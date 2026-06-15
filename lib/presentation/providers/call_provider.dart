import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:lifeos/core/constants/app_constants.dart';

final _iceServers = {
  'iceServers': [
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
    {'urls': 'stun:stun2.l.google.com:19302'},
  ]
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
    String? error,
  }) => CallState(
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
    error: error,
  );
}

class CallController extends StateNotifier<CallState> {
  final Ref ref;
  WebSocketChannel? _channel;
  final _storage = const FlutterSecureStorage();
  final RTCVideoRenderer localRenderer = RTCVideoRenderer();
  bool _localRendererReady = false;

  CallController(this.ref) : super(const CallState()) {
    _connect();
    _checkPendingInvite();
  }

  Future<void> _checkPendingInvite() async {
    const pendingKey = 'pending_call_invite';
    try {
      final raw = await _storage.read(key: pendingKey);
      if (raw == null) return;
      await _storage.delete(key: pendingKey);
      final data = jsonDecode(raw) as Map<String, dynamic>;
      final receivedAt = DateTime.tryParse(data['received_at']?.toString() ?? '');
      if (receivedAt == null || DateTime.now().toUtc().difference(receivedAt) > const Duration(seconds: 60)) {
        return;
      }
      if (data['type'] == 'meeting_invite') {
        _onMeetingInvite(data);
      } else if (data['type'] == 'call_invite') {
        _onCallInvite(data);
      }
    } catch (_) {}
  }

  Future<void> _connect() async {
    final token = await _storage.read(key: AppConstants.keyToken);
    if (token == null) return;
    final base = AppConstants.baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://');
    final uri = Uri.parse('$base/api/v1/connect/ws?token=$token');
    try {
      _channel = WebSocketChannel.connect(uri);
      _channel!.stream.listen(_onMessage, onDone: () {
        _channel = null;
        Future.delayed(const Duration(seconds: 5), _connect);
      }, onError: (_) {
        _channel = null;
        Future.delayed(const Duration(seconds: 5), _connect);
      });
    } catch (_) {
      Future.delayed(const Duration(seconds: 5), _connect);
    }
  }

  void _send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void _onMessage(dynamic event) {
    try {
      final data = jsonDecode(event as String) as Map<String, dynamic>;
      switch (data['type']) {
        case 'call_invite':
          _onCallInvite(data);
          break;
        case 'call_answer':
          _onCallAnswer(data);
          break;
        case 'call_reject':
          _onCallReject(data);
          break;
        case 'call_end':
          _onCallEnd(data);
          break;
        case 'meeting_invite':
          _onMeetingInvite(data);
          break;
        case 'room_members':
          _onRoomMembers(data);
          break;
        case 'peer_joined':
          _onPeerJoined(data);
          break;
        case 'peer_left':
          _onPeerLeft(data);
          break;
        case 'webrtc_offer':
          _onOffer(data);
          break;
        case 'webrtc_answer':
          _onAnswer(data);
          break;
        case 'webrtc_ice':
          _onIce(data);
          break;
      }
    } catch (_) {}
  }

  // ---------------------------------------------------------------------
  // Local media
  // ---------------------------------------------------------------------

  Future<bool> _ensurePermissions(bool video) async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      state = state.copyWith(error: 'Microphone permission is required for calls');
      return false;
    }
    if (video) {
      final cam = await Permission.camera.request();
      if (!cam.isGranted) {
        state = state.copyWith(error: 'Camera permission is required for video calls');
        return false;
      }
    }
    return true;
  }

  Future<MediaStream> _getLocalStream(bool video) async {
    final stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    });
    if (!_localRendererReady) {
      await localRenderer.initialize();
      _localRendererReady = true;
    }
    localRenderer.srcObject = stream;
    return stream;
  }

  void _releaseLocalStream() {
    final stream = state.localStream;
    if (stream != null) {
      for (final t in stream.getTracks()) {
        t.stop();
      }
    }
    localRenderer.srcObject = null;
  }

  // ---------------------------------------------------------------------
  // Outgoing 1:1 call
  // ---------------------------------------------------------------------

  Future<void> startCall(int friendId, String friendUsername, String callType) async {
    if (state.status != CallStatus.idle) return;
    if (!await _ensurePermissions(callType == 'video')) return;
    final roomId = 'call_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    final stream = await _getLocalStream(callType == 'video');
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
    );
    _send({'type': 'call_invite', 'to': friendId, 'room_id': roomId, 'call_type': callType});
  }

  // ---------------------------------------------------------------------
  // Incoming 1:1 call / meeting invite
  // ---------------------------------------------------------------------

  void _onCallInvite(Map<String, dynamic> data) {
    if (state.status != CallStatus.idle) {
      // already busy - auto reject
      _send({'type': 'call_reject', 'to': data['from'], 'room_id': data['room_id']});
      return;
    }
    state = state.copyWith(
      status: CallStatus.ringing,
      roomId: data['room_id'],
      callType: data['call_type'] ?? 'video',
      isMeeting: false,
      peerUserId: data['from'],
      peerUsername: data['from_username'],
      participants: [],
    );
  }

  void _onMeetingInvite(Map<String, dynamic> data) {
    if (state.status != CallStatus.idle) return;
    state = state.copyWith(
      status: CallStatus.ringing,
      roomId: data['room_id'],
      callType: 'video',
      isMeeting: true,
      peerUserId: data['from'],
      peerUsername: data['from_username'],
      participants: [],
    );
  }

  Future<void> acceptCall() async {
    final roomId = state.roomId;
    if (roomId == null) return;
    if (!await _ensurePermissions(state.callType == 'video')) {
      final err = state.error;
      if (!state.isMeeting && state.peerUserId != null) {
        _send({'type': 'call_reject', 'to': state.peerUserId, 'room_id': state.roomId});
      }
      _reset(error: err);
      return;
    }
    final stream = await _getLocalStream(state.callType == 'video');
    state = state.copyWith(status: CallStatus.connected, localStream: stream);
    if (!state.isMeeting) {
      _send({'type': 'call_answer', 'to': state.peerUserId, 'room_id': roomId});
    }
    _send({'type': 'join_room', 'room_id': roomId});
  }

  void rejectCall() {
    if (!state.isMeeting && state.peerUserId != null) {
      _send({'type': 'call_reject', 'to': state.peerUserId, 'room_id': state.roomId});
    }
    _reset();
  }

  void _onCallAnswer(Map<String, dynamic> data) {
    if (state.status != CallStatus.outgoing || data['room_id'] != state.roomId) return;
    state = state.copyWith(status: CallStatus.connected);
    _send({'type': 'join_room', 'room_id': state.roomId});
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

  // ---------------------------------------------------------------------
  // Meeting (group call)
  // ---------------------------------------------------------------------

  Future<void> startMeeting(List<int> friendIds) async {
    if (state.status != CallStatus.idle) return;
    if (!await _ensurePermissions(true)) return;
    final roomId = 'meet_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    final stream = await _getLocalStream(true);
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
    );
    if (friendIds.isNotEmpty) {
      _send({'type': 'meeting_invite', 'to_ids': friendIds, 'room_id': roomId});
    }
    _send({'type': 'join_room', 'room_id': roomId});
  }

  // ---------------------------------------------------------------------
  // Room / peer connection lifecycle
  // ---------------------------------------------------------------------

  CallParticipant _getOrCreateParticipant(int userId, {String? username}) {
    final existing = state.participants.firstWhere((p) => p.userId == userId, orElse: () => CallParticipant(userId: userId, username: username));
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
        await pc.addTrack(track, localStream);
      }
    }
    pc.onIceCandidate = (candidate) {
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
      if (event.streams.isNotEmpty) {
        if (!participant.rendererReady) {
          await participant.renderer.initialize();
          participant.rendererReady = true;
        }
        participant.remoteStream = event.streams[0];
        participant.renderer.srcObject = event.streams[0];
        _touch();
      }
    };
    participant.pc = pc;
    return pc;
  }

  Future<void> _onRoomMembers(Map<String, dynamic> data) async {
    final members = List<Map<String, dynamic>>.from((data['members'] as List).map((e) => Map<String, dynamic>.from(e)));
    for (final m in members) {
      final participant = _getOrCreateParticipant(m['id'] as int, username: m['username'] as String?);
      final pc = await _ensurePeerConnection(participant);
      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      _send({
        'type': 'webrtc_offer',
        'to': participant.userId,
        'room_id': state.roomId,
        'sdp': {'sdp': offer.sdp, 'type': offer.type},
      });
    }
  }

  void _onPeerJoined(Map<String, dynamic> data) {
    _getOrCreateParticipant(data['from'] as int, username: data['from_username'] as String?);
  }

  void _onPeerLeft(Map<String, dynamic> data) {
    final userId = data['from'] as int;
    final participant = state.participants.firstWhere((p) => p.userId == userId, orElse: () => CallParticipant(userId: -1));
    if (participant.userId == -1) return;
    participant.pc?.close();
    participant.renderer.dispose();
    state = state.copyWith(participants: state.participants.where((p) => p.userId != userId).toList());

    if (!state.isMeeting && state.participants.isEmpty) {
      _reset();
    }
  }

  Future<void> _onOffer(Map<String, dynamic> data) async {
    final from = data['from'] as int;
    final participant = _getOrCreateParticipant(from);
    final pc = await _ensurePeerConnection(participant);
    final sdp = data['sdp'];
    await pc.setRemoteDescription(RTCSessionDescription(sdp['sdp'], sdp['type']));
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);
    _send({
      'type': 'webrtc_answer',
      'to': from,
      'room_id': state.roomId,
      'sdp': {'sdp': answer.sdp, 'type': answer.type},
    });
  }

  Future<void> _onAnswer(Map<String, dynamic> data) async {
    final from = data['from'] as int;
    final participant = state.participants.firstWhere((p) => p.userId == from, orElse: () => CallParticipant(userId: -1));
    if (participant.pc == null) return;
    final sdp = data['sdp'];
    await participant.pc!.setRemoteDescription(RTCSessionDescription(sdp['sdp'], sdp['type']));
  }

  Future<void> _onIce(Map<String, dynamic> data) async {
    final from = data['from'] as int;
    final participant = state.participants.firstWhere((p) => p.userId == from, orElse: () => CallParticipant(userId: -1));
    if (participant.pc == null) return;
    final c = data['candidate'];
    if (c == null) return;
    await participant.pc!.addCandidate(RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
  }

  // ---------------------------------------------------------------------
  // Controls
  // ---------------------------------------------------------------------

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

  void endCall() {
    if (state.roomId != null) {
      _send({'type': 'call_end', 'room_id': state.roomId});
    }
    _reset();
  }

  void _touch() {
    state = state.copyWith(participants: List.of(state.participants));
  }

  void _reset({String? error}) {
    for (final p in state.participants) {
      p.pc?.close();
      p.renderer.dispose();
    }
    _releaseLocalStream();
    state = CallState(error: error);
  }

  @override
  void dispose() {
    _reset();
    localRenderer.dispose();
    _channel?.sink.close();
    super.dispose();
  }
}

final callControllerProvider = StateNotifierProvider<CallController, CallState>((ref) => CallController(ref));
