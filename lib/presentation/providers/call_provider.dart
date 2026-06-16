import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:lifeos/core/constants/app_constants.dart';

// Free public TURN relay — no API key required.
const _iceServers = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
    {
      'urls': [
        'turn:openrelay.metered.ca:80',
        'turn:openrelay.metered.ca:80?transport=tcp',
        'turns:openrelay.metered.ca:443',
        'turns:openrelay.metered.ca:443?transport=tcp',
      ],
      'username': 'openrelayproject',
      'credential': 'openrelayproject',
    },
  ],
  'sdpSemantics': 'unified-plan',
  'iceCandidatePoolSize': 10,
};

enum CallStatus { idle, ringing, outgoing, connected }

class CallParticipant {
  final int userId;
  String? username;
  RTCPeerConnection? pc;
  MediaStream? remoteStream;
  bool rendererReady = false;
  final RTCVideoRenderer renderer = RTCVideoRenderer();
  CallParticipant({required this.userId, this.username});
}

class CallState {
  final CallStatus status;
  final String? roomId;
  final String callType; // audio | video
  final bool isMeeting;
  final int? peerUserId;
  final String? peerUsername;
  final List<CallParticipant> participants;
  final MediaStream? localStream;
  final bool micMuted;
  final bool cameraOff;
  final bool speakerOn;
  final int durationSeconds;
  final String? error;

  const CallState({
    this.status = CallStatus.idle,
    this.roomId,
    this.callType = 'video',
    this.isMeeting = false,
    this.peerUserId,
    this.peerUsername,
    this.participants = const [],
    this.localStream,
    this.micMuted = false,
    this.cameraOff = false,
    this.speakerOn = true,
    this.durationSeconds = 0,
    this.error,
  });

  CallState copyWith({
    CallStatus? status,
    String? roomId,
    String? callType,
    bool? isMeeting,
    int? peerUserId,
    String? peerUsername,
    List<CallParticipant>? participants,
    MediaStream? localStream,
    bool? micMuted,
    bool? cameraOff,
    bool? speakerOn,
    int? durationSeconds,
    String? error,
  }) =>
      CallState(
        status: status ?? this.status,
        roomId: roomId ?? this.roomId,
        callType: callType ?? this.callType,
        isMeeting: isMeeting ?? this.isMeeting,
        peerUserId: peerUserId ?? this.peerUserId,
        peerUsername: peerUsername ?? this.peerUsername,
        participants: participants ?? this.participants,
        localStream: localStream ?? this.localStream,
        micMuted: micMuted ?? this.micMuted,
        cameraOff: cameraOff ?? this.cameraOff,
        speakerOn: speakerOn ?? this.speakerOn,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        error: error,
      );

  String get durationLabel {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class CallController extends StateNotifier<CallState> {
  final Ref ref;
  WebSocketChannel? _channel;
  final _storage = const FlutterSecureStorage();
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  bool _localRendererReady = false;

  // Queued ICE candidates that arrive before the PC is ready
  final Map<int, List<RTCIceCandidate>> _pendingCandidates = {};

  // Timers
  Timer? _reconnectTimer;
  Timer? _outgoingTimeout;
  Timer? _durationTimer;

  CallController(this.ref) : super(const CallState()) {
    _connect();
    checkPendingInvite();
  }

  // ─── WebSocket ────────────────────────────────────────────────────────────

  Future<void> _connect() async {
    final token = await _storage.read(key: AppConstants.keyToken);
    if (token == null) return;
    final base = AppConstants.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$base/api/v1/connect/ws?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(
        (event) => _onMessage(event),
        onDone: () {
          _channel = null;
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(const Duration(seconds: 5), _connect);
        },
        onError: (_) {
          _channel = null;
          _reconnectTimer?.cancel();
          _reconnectTimer = Timer(const Duration(seconds: 5), _connect);
        },
      );
    } catch (_) {
      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(const Duration(seconds: 5), _connect);
    }
  }

  void _send(Map<String, dynamic> data) {
    try {
      _channel?.sink.add(jsonEncode(data));
    } catch (_) {}
  }

  // ─── Message router (fully async so exceptions don't escape) ─────────────

  Future<void> _onMessage(dynamic event) async {
    try {
      final data = jsonDecode(event as String) as Map<String, dynamic>;
      switch (data['type'] as String?) {
        case 'call_invite':
          _onCallInvite(data);
        case 'call_answer':
          _onCallAnswer(data);
        case 'call_reject':
          _onCallReject(data);
        case 'call_end':
          _onCallEnd(data);
        case 'meeting_invite':
          _onMeetingInvite(data);
        case 'room_members':
          await _onRoomMembers(data);
        case 'peer_joined':
          _onPeerJoined(data);
        case 'peer_left':
          _onPeerLeft(data);
        case 'webrtc_offer':
          await _onOffer(data);
        case 'webrtc_answer':
          await _onAnswer(data);
        case 'webrtc_ice':
          await _onIce(data);
      }
    } catch (_) {}
  }

  // ─── Pending invite (from background service while app was closed) ─────────

  Future<void> checkPendingInvite() async {
    if (state.status != CallStatus.idle) return;
    try {
      final raw = await _storage.read(key: 'pending_call_invite');
      if (raw == null) return;
      await _storage.delete(key: 'pending_call_invite');
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final receivedAt = DateTime.tryParse(data['received_at']?.toString() ?? '');
      if (receivedAt == null ||
          DateTime.now().toUtc().difference(receivedAt) > const Duration(seconds: 90)) {
        return;
      }
      if (data['type'] == 'meeting_invite') {
        _onMeetingInvite(data);
      } else if (data['type'] == 'call_invite') {
        _onCallInvite(data);
      }
    } catch (_) {}
  }

  // ─── Local media ──────────────────────────────────────────────────────────

  Future<bool> _ensurePermissions(bool video) async {
    try {
      final mic = await Permission.microphone.request();
      if (!mic.isGranted) {
        state = state.copyWith(error: 'Microphone permission denied');
        return false;
      }
      if (video) {
        final cam = await Permission.camera.request();
        if (!cam.isGranted) {
          state = state.copyWith(error: 'Camera permission denied');
          return false;
        }
      }
      return true;
    } catch (_) {
      state = state.copyWith(error: 'Permission check failed');
      return false;
    }
  }

  Future<MediaStream?> _getLocalStream(bool video) async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': video ? {'facingMode': 'user', 'width': 640, 'height': 480} : false,
      });
      if (!_localRendererReady) {
        await localRenderer.initialize();
        _localRendererReady = true;
      }
      localRenderer.srcObject = stream;
      try { await Helper.setSpeakerphoneOn(true); } catch (_) {}
      return stream;
    } catch (e) {
      return null;
    }
  }

  void _releaseLocalStream() {
    final stream = state.localStream;
    if (stream != null) {
      for (final t in stream.getTracks()) {
        try { t.stop(); } catch (_) {}
      }
    }
    localRenderer.srcObject = null;
  }

  // ─── Outgoing 1-to-1 call ─────────────────────────────────────────────────

  Future<void> startCall(int friendId, String friendUsername, String callType) async {
    if (state.status != CallStatus.idle) return;
    if (!await _ensurePermissions(callType == 'video')) return;
    final stream = await _getLocalStream(callType == 'video');
    if (stream == null) {
      state = state.copyWith(error: 'Could not access camera/microphone');
      return;
    }
    final roomId =
        'call_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    state = state.copyWith(
      status: CallStatus.outgoing,
      roomId: roomId,
      callType: callType,
      isMeeting: false,
      peerUserId: friendId,
      peerUsername: friendUsername,
      localStream: stream,
      participants: [],
      micMuted: false,
      cameraOff: false,
      speakerOn: true,
      durationSeconds: 0,
    );
    _send({'type': 'call_invite', 'to': friendId, 'room_id': roomId, 'call_type': callType});

    // Auto-cancel after 45 s if no answer
    _outgoingTimeout?.cancel();
    _outgoingTimeout = Timer(const Duration(seconds: 45), () {
      if (state.status == CallStatus.outgoing) endCall();
    });
  }

  // ─── Incoming 1-to-1 ──────────────────────────────────────────────────────

  void _onCallInvite(Map<String, dynamic> data) {
    if (state.status != CallStatus.idle) {
      _send({'type': 'call_reject', 'to': data['from'], 'room_id': data['room_id']});
      return;
    }
    state = state.copyWith(
      status: CallStatus.ringing,
      roomId: data['room_id'],
      callType: data['call_type'] ?? 'video',
      isMeeting: false,
      peerUserId: data['from'] as int?,
      peerUsername: data['from_username'] as String?,
      participants: [],
      durationSeconds: 0,
    );
  }

  void _onMeetingInvite(Map<String, dynamic> data) {
    if (state.status != CallStatus.idle) return;
    state = state.copyWith(
      status: CallStatus.ringing,
      roomId: data['room_id'],
      callType: 'video',
      isMeeting: true,
      peerUserId: data['from'] as int?,
      peerUsername: data['from_username'] as String?,
      participants: [],
      durationSeconds: 0,
    );
  }

  Future<void> acceptCall() async {
    final roomId = state.roomId;
    if (roomId == null) return;
    if (!await _ensurePermissions(state.callType == 'video')) {
      if (!state.isMeeting && state.peerUserId != null) {
        _send({'type': 'call_reject', 'to': state.peerUserId, 'room_id': roomId});
      }
      _reset();
      return;
    }
    final stream = await _getLocalStream(state.callType == 'video');
    if (stream == null) {
      state = state.copyWith(error: 'Could not access camera/microphone');
      if (!state.isMeeting && state.peerUserId != null) {
        _send({'type': 'call_reject', 'to': state.peerUserId, 'room_id': roomId});
      }
      _reset();
      return;
    }
    state = state.copyWith(
        status: CallStatus.connected, localStream: stream, durationSeconds: 0);
    if (!state.isMeeting) {
      _send({'type': 'call_answer', 'to': state.peerUserId, 'room_id': roomId});
    }
    _send({'type': 'join_room', 'room_id': roomId});
    _startDurationTimer();
  }

  void rejectCall() {
    if (!state.isMeeting && state.peerUserId != null) {
      _send({'type': 'call_reject', 'to': state.peerUserId, 'room_id': state.roomId});
    }
    _reset();
  }

  void _onCallAnswer(Map<String, dynamic> data) {
    if (state.status != CallStatus.outgoing || data['room_id'] != state.roomId) return;
    _outgoingTimeout?.cancel();
    state = state.copyWith(status: CallStatus.connected, durationSeconds: 0);
    _send({'type': 'join_room', 'room_id': state.roomId});
    _startDurationTimer();
  }

  void _onCallReject(Map<String, dynamic> data) {
    if (data['room_id'] != state.roomId) return;
    _reset();
  }

  void _onCallEnd(Map<String, dynamic> data) {
    if (data['room_id'] != state.roomId) return;
    _send({'type': 'leave_room', 'room_id': state.roomId});
    _reset();
  }

  // ─── Meeting ──────────────────────────────────────────────────────────────

  Future<void> startMeeting(List<int> friendIds) async {
    if (state.status != CallStatus.idle) return;
    if (!await _ensurePermissions(true)) return;
    final stream = await _getLocalStream(true);
    if (stream == null) {
      state = state.copyWith(error: 'Could not access camera/microphone');
      return;
    }
    final roomId =
        'meet_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    state = state.copyWith(
      status: CallStatus.connected,
      roomId: roomId,
      callType: 'video',
      isMeeting: true,
      peerUserId: null,
      peerUsername: null,
      localStream: stream,
      participants: [],
      micMuted: false,
      cameraOff: false,
      speakerOn: true,
      durationSeconds: 0,
    );
    if (friendIds.isNotEmpty) {
      _send({'type': 'meeting_invite', 'to_ids': friendIds, 'room_id': roomId});
    }
    _send({'type': 'join_room', 'room_id': roomId});
    _startDurationTimer();
  }

  // ─── Room / peer connections ───────────────────────────────────────────────

  CallParticipant _getOrCreateParticipant(int userId, {String? username}) {
    final existing = state.participants
        .firstWhere((p) => p.userId == userId, orElse: () => CallParticipant(userId: userId, username: username));
    if (!state.participants.any((p) => p.userId == userId)) {
      state = state.copyWith(participants: [...state.participants, existing]);
    } else if (username != null && existing.username == null) {
      existing.username = username;
    }
    return existing;
  }

  Future<RTCPeerConnection> _ensurePeerConnection(CallParticipant participant) async {
    if (participant.pc != null) return participant.pc!;
    final pc = await createPeerConnection(_iceServers);
    final localStream = state.localStream;
    if (localStream != null) {
      for (final track in localStream.getTracks()) {
        try { await pc.addTrack(track, localStream); } catch (_) {}
      }
    }
    pc.onIceCandidate = (candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) return;
      _send({
        'type': 'webrtc_ice',
        'to': participant.userId,
        'room_id': state.roomId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      });
    };
    pc.onTrack = (event) async {
      if (event.streams.isEmpty) return;
      try {
        if (!participant.rendererReady) {
          await participant.renderer.initialize();
          participant.rendererReady = true;
        }
        participant.remoteStream = event.streams[0];
        participant.renderer.srcObject = event.streams[0];
        _touch();
      } catch (_) {}
    };
    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        // Try ICE restart on failure
        try { pc.restartIce(); } catch (_) {}
      }
    };
    participant.pc = pc;
    return pc;
  }

  Future<void> _onRoomMembers(Map<String, dynamic> data) async {
    final members = (data['members'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];
    for (final m in members) {
      try {
        final participant =
            _getOrCreateParticipant(m['id'] as int, username: m['username'] as String?);
        final pc = await _ensurePeerConnection(participant);
        final offer = await pc.createOffer();
        await pc.setLocalDescription(offer);
        _send({
          'type': 'webrtc_offer',
          'to': participant.userId,
          'room_id': state.roomId,
          'sdp': {'sdp': offer.sdp, 'type': offer.type},
        });
      } catch (_) {}
    }
  }

  void _onPeerJoined(Map<String, dynamic> data) {
    _getOrCreateParticipant(
      data['from'] as int,
      username: data['from_username'] as String?,
    );
  }

  void _onPeerLeft(Map<String, dynamic> data) {
    final userId = data['from'] as int;
    final participant = state.participants
        .firstWhere((p) => p.userId == userId, orElse: () => CallParticipant(userId: -1));
    if (participant.userId == -1) return;
    try { participant.pc?.close(); } catch (_) {}
    try { participant.renderer.dispose(); } catch (_) {}
    state = state.copyWith(
        participants: state.participants.where((p) => p.userId != userId).toList());
    if (!state.isMeeting && state.participants.isEmpty) _reset();
  }

  Future<void> _onOffer(Map<String, dynamic> data) async {
    final from = data['from'] as int;
    final sdpData = data['sdp'];
    if (sdpData == null) return;
    try {
      final participant = _getOrCreateParticipant(from);
      final pc = await _ensurePeerConnection(participant);
      await pc.setRemoteDescription(
          RTCSessionDescription(sdpData['sdp'] as String, sdpData['type'] as String));
      await _drainCandidates(participant);
      final answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);
      _send({
        'type': 'webrtc_answer',
        'to': from,
        'room_id': state.roomId,
        'sdp': {'sdp': answer.sdp, 'type': answer.type},
      });
    } catch (_) {}
  }

  Future<void> _onAnswer(Map<String, dynamic> data) async {
    final from = data['from'] as int;
    final sdpData = data['sdp'];
    if (sdpData == null) return;
    try {
      final participant = state.participants
          .firstWhere((p) => p.userId == from, orElse: () => CallParticipant(userId: -1));
      if (participant.pc == null) return;
      await participant.pc!.setRemoteDescription(
          RTCSessionDescription(sdpData['sdp'] as String, sdpData['type'] as String));
      await _drainCandidates(participant);
    } catch (_) {}
  }

  Future<void> _onIce(Map<String, dynamic> data) async {
    final from = data['from'] as int;
    final c = data['candidate'];
    if (c == null) return;
    try {
      final candidate =
          RTCIceCandidate(c['candidate'] as String, c['sdpMid'] as String?, c['sdpMLineIndex'] as int?);
      final participant = state.participants
          .firstWhere((p) => p.userId == from, orElse: () => CallParticipant(userId: -1));
      if (participant.userId == -1 || participant.pc == null) {
        _pendingCandidates.putIfAbsent(from, () => []).add(candidate);
        return;
      }
      await participant.pc!.addCandidate(candidate);
    } catch (_) {}
  }

  Future<void> _drainCandidates(CallParticipant participant) async {
    final queued = _pendingCandidates.remove(participant.userId);
    if (queued == null) return;
    for (final c in queued) {
      try { await participant.pc!.addCandidate(c); } catch (_) {}
    }
  }

  // ─── Controls ─────────────────────────────────────────────────────────────

  void toggleMic() {
    final stream = state.localStream;
    if (stream == null) return;
    final muted = !state.micMuted;
    for (final track in stream.getAudioTracks()) {
      track.enabled = !muted;
    }
    state = state.copyWith(micMuted: muted);
  }

  void toggleCamera() {
    final stream = state.localStream;
    if (stream == null) return;
    final off = !state.cameraOff;
    for (final track in stream.getVideoTracks()) {
      track.enabled = !off;
    }
    state = state.copyWith(cameraOff: off);
  }

  void toggleSpeaker() {
    final on = !state.speakerOn;
    try { Helper.setSpeakerphoneOn(on); } catch (_) {}
    state = state.copyWith(speakerOn: on);
  }

  void switchCamera() {
    final stream = state.localStream;
    if (stream == null) return;
    final videoTracks = stream.getVideoTracks();
    if (videoTracks.isNotEmpty) {
      try { Helper.switchCamera(videoTracks.first); } catch (_) {}
    }
  }

  void addToCall(List<int> friendIds) {
    final roomId = state.roomId;
    if (roomId == null || friendIds.isEmpty) return;
    _send({'type': 'meeting_invite', 'to_ids': friendIds, 'room_id': roomId});
  }

  void endCall() {
    if (state.roomId != null) {
      _send({'type': 'call_end', 'room_id': state.roomId});
      _send({'type': 'leave_room', 'room_id': state.roomId});
    }
    _reset();
  }

  // ─── Timer ────────────────────────────────────────────────────────────────

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == CallStatus.connected) {
        state = state.copyWith(durationSeconds: state.durationSeconds + 1);
      }
    });
  }

  // ─── Internal ─────────────────────────────────────────────────────────────

  void _touch() {
    state = state.copyWith(participants: List.of(state.participants));
  }

  void _reset({String? error}) {
    _outgoingTimeout?.cancel();
    _durationTimer?.cancel();
    _pendingCandidates.clear();
    for (final p in state.participants) {
      try { p.pc?.close(); } catch (_) {}
      try { p.renderer.dispose(); } catch (_) {}
    }
    _releaseLocalStream();
    state = CallState(error: error);
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _outgoingTimeout?.cancel();
    _durationTimer?.cancel();
    _reset();
    try { localRenderer.dispose(); } catch (_) {}
    _channel?.sink.close();
    super.dispose();
  }
}

final callControllerProvider =
    StateNotifierProvider<CallController, CallState>((ref) => CallController(ref));
