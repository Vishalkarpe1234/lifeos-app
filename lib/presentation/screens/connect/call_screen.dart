import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/call_provider.dart';
import 'package:lifeos/presentation/providers/connect_provider.dart';

class CallScreen extends ConsumerStatefulWidget {
  const CallScreen({super.key});
  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  bool _showControls = true;

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);

    ref.listen(callControllerProvider, (prev, next) {
      if (next.status == CallStatus.idle) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((r) => r.isFirst);
        }
      }
      if (next.error != null && next.error != prev?.error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(next.error!), backgroundColor: C.error));
        }
      }
    });

    if (call.status == CallStatus.idle) return const SizedBox.shrink();

    final isVideo = call.callType == 'video';
    final isOutgoing = call.status == CallStatus.outgoing;
    final participants = call.participants;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Stack(children: [
            // ── Remote video / participants grid ─────────────────────────
            if (isOutgoing || participants.isEmpty)
              _WaitingView(call: call)
            else
              _VideoGrid(participants: participants, callType: call.callType),

            // ── Local PiP (video only) ───────────────────────────────────
            if (isVideo && !call.cameraOff)
              Positioned(
                right: 12,
                top: 56,
                width: 100,
                height: 140,
                child: GestureDetector(
                  onTap: () {}, // don't toggle controls when tapping PiP
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RTCVideoView(
                      controller.localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),

            // ── Audio call avatar (when no video) ────────────────────────
            if (!isVideo && participants.isNotEmpty && call.status == CallStatus.connected)
              Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: C.primary.withOpacity(0.3),
                    child: Text(
                      (call.peerUsername ?? participants.first.username ?? '?')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 40,
                          fontFamily: 'Inter', fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('@${call.peerUsername ?? participants.first.username ?? '?'}',
                      style: const TextStyle(color: Colors.white, fontSize: 20,
                          fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(call.durationLabel,
                      style: const TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Inter')),
                ]),
              ),

            // ── Top bar ──────────────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Positioned(
                top: 0, left: 0, right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
                  child: Row(children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 26),
                      onPressed: controller.endCall,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          call.isMeeting
                              ? 'Meeting (${participants.length + 1})'
                              : '@${call.peerUsername ?? ''}',
                          style: const TextStyle(color: Colors.white, fontSize: 16,
                              fontFamily: 'Inter', fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (call.status == CallStatus.connected)
                          Text(call.durationLabel,
                              style: const TextStyle(color: Colors.white60, fontSize: 12,
                                  fontFamily: 'Inter'))
                        else
                          const Text('Connecting…',
                              style: TextStyle(color: Colors.white60, fontSize: 12,
                                  fontFamily: 'Inter')),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),

            // ── Bottom controls ───────────────────────────────────────────
            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Positioned(
                bottom: 0, left: 0, right: 0,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black87, Colors.transparent],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // Secondary row: flip + add
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (isVideo) ...[
                          _SmallBtn(
                            icon: Icons.flip_camera_android_rounded,
                            label: 'Flip',
                            onTap: controller.switchCamera,
                          ),
                          const SizedBox(width: 32),
                        ],
                        _SmallBtn(
                          icon: Icons.person_add_alt_1_rounded,
                          label: 'Add',
                          onTap: () => _showAddDialog(context, ref),
                        ),
                        if (isVideo) ...[
                          const SizedBox(width: 32),
                          _SmallBtn(
                            icon: call.cameraOff
                                ? Icons.videocam_off_rounded
                                : Icons.videocam_rounded,
                            label: call.cameraOff ? 'Cam Off' : 'Camera',
                            onTap: controller.toggleCamera,
                          ),
                        ],
                      ]),
                      const SizedBox(height: 20),
                      // Primary row: mic + end + speaker
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _RoundBtn(
                          icon: call.micMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          active: !call.micMuted,
                          label: call.micMuted ? 'Unmute' : 'Mute',
                          onTap: controller.toggleMic,
                        ),
                        const SizedBox(width: 24),
                        _EndBtn(onTap: controller.endCall),
                        const SizedBox(width: 24),
                        _RoundBtn(
                          icon: call.speakerOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                          active: call.speakerOn,
                          label: call.speakerOn ? 'Speaker' : 'Earpiece',
                          onTap: controller.toggleSpeaker,
                        ),
                      ]),
                    ]),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    List<Map<String, dynamic>> friends;
    try {
      friends = await ref.read(connectServiceProvider).listFriends();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load friends'), backgroundColor: C.error));
      }
      return;
    }
    if (!context.mounted) return;

    final currentIds =
        ref.read(callControllerProvider).participants.map((p) => p.userId).toSet();
    final available = friends.where((f) => !currentIds.contains(f['id'] as int)).toList();

    if (available.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No more friends to add'), backgroundColor: C.textSub));
      }
      return;
    }

    final selected = <int>{};
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, set) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Add to call',
                style: TextStyle(color: Colors.white, fontSize: 18,
                    fontFamily: 'Inter', fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            ...available.map((f) {
              final id = f['id'] as int;
              return CheckboxListTile(
                value: selected.contains(id),
                activeColor: C.primary,
                checkColor: Colors.white,
                title: Text('@${f['username']}',
                    style: const TextStyle(color: Colors.white, fontFamily: 'Inter')),
                onChanged: (v) =>
                    set(() => v == true ? selected.add(id) : selected.remove(id)),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: C.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        ref.read(callControllerProvider.notifier).addToCall(selected.toList());
                        Navigator.pop(ctx);
                      },
                child: const Text('Invite',
                    style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        );
      }),
    );
  }
}

// ── Waiting / outgoing view ────────────────────────────────────────────────

class _WaitingView extends StatelessWidget {
  final CallState call;
  const _WaitingView({required this.call});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 64,
          backgroundColor: C.primary.withOpacity(0.25),
          child: Text(
            (call.peerUsername ?? 'M').isNotEmpty
                ? (call.peerUsername ?? 'M')[0].toUpperCase()
                : 'M',
            style: const TextStyle(color: Colors.white, fontSize: 48,
                fontFamily: 'Inter', fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          call.isMeeting ? 'Meeting Room' : '@${call.peerUsername ?? ''}',
          style: const TextStyle(color: Colors.white, fontSize: 22,
              fontFamily: 'Inter', fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          call.status == CallStatus.outgoing ? 'Calling…' : 'Waiting for others…',
          style: const TextStyle(color: Colors.white60, fontSize: 15, fontFamily: 'Inter'),
        ),
        if (call.status == CallStatus.outgoing) ...[
          const SizedBox(height: 6),
          const Text('Call will cancel after 45 seconds',
              style: TextStyle(color: Colors.white38, fontSize: 12, fontFamily: 'Inter')),
        ],
      ]),
    );
  }
}

// ── Video grid ─────────────────────────────────────────────────────────────

class _VideoGrid extends StatelessWidget {
  final List<CallParticipant> participants;
  final String callType;
  const _VideoGrid({required this.participants, required this.callType});

  @override
  Widget build(BuildContext context) {
    if (participants.length == 1) {
      return _ParticipantTile(participant: participants[0], callType: callType, fullSize: true);
    }
    final cols = participants.length <= 4 ? 2 : 3;
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, mainAxisSpacing: 2, crossAxisSpacing: 2),
      itemCount: participants.length,
      itemBuilder: (_, i) =>
          _ParticipantTile(participant: participants[i], callType: callType, fullSize: false),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final CallParticipant participant;
  final String callType;
  final bool fullSize;
  const _ParticipantTile(
      {required this.participant, required this.callType, required this.fullSize});

  @override
  Widget build(BuildContext context) {
    final hasVideo =
        callType == 'video' && participant.rendererReady && participant.remoteStream != null;
    return Container(
      color: const Color(0xFF1C1C1E),
      child: Stack(fit: StackFit.expand, children: [
        if (hasVideo)
          RTCVideoView(participant.renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
        else
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircleAvatar(
                radius: fullSize ? 56 : 36,
                backgroundColor: C.primary.withOpacity(0.3),
                child: Text(
                  (participant.username ?? '?').isNotEmpty
                      ? participant.username![0].toUpperCase()
                      : '?',
                  style: TextStyle(color: Colors.white,
                      fontSize: fullSize ? 40 : 26,
                      fontFamily: 'Inter', fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              Text('@${participant.username ?? '…'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Inter')),
            ]),
          ),
        Positioned(
          left: 8, bottom: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(6)),
            child: Text('@${participant.username ?? '…'}',
                style: const TextStyle(color: Colors.white, fontSize: 12,
                    fontFamily: 'Inter', fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}

// ── Button widgets ─────────────────────────────────────────────────────────

class _EndBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _EndBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 68, height: 68,
          decoration: const BoxDecoration(color: C.error, shape: BoxShape.circle),
          child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 30),
        ),
      ),
      const SizedBox(height: 5),
      const Text('End', style: TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'Inter')),
    ]);
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final String label;
  final VoidCallback onTap;
  const _RoundBtn({required this.icon, required this.active, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
              color: active ? Colors.white24 : Colors.white,
              shape: BoxShape.circle),
          child: Icon(icon, color: active ? Colors.white : Colors.black87, size: 24),
        ),
      ),
      const SizedBox(height: 5),
      Text(label,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'Inter')),
    ]);
  }
}

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'Inter')),
    ]);
  }
}
