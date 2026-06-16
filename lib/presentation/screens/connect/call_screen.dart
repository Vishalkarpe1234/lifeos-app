import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/call_provider.dart';
import 'package:lifeos/presentation/providers/connect_provider.dart';

class CallScreen extends ConsumerWidget {
  const CallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);

    ref.listen(callControllerProvider, (prev, next) {
      if (next.status == CallStatus.idle && Navigator.of(context).canPop()) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });

    if (call.status == CallStatus.idle) return const SizedBox.shrink();

    final isOutgoing = call.status == CallStatus.outgoing;
    final participants = call.participants;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          // ── Main video area ──────────────────────────────────────────────
          if (isOutgoing || participants.isEmpty)
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(
                  radius: 56,
                  backgroundColor: C.primary.withOpacity(0.25),
                  child: Text(
                    (call.peerUsername ?? 'M')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 40,
                        fontFamily: 'Inter', fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  call.isMeeting ? 'Meeting' : '@${call.peerUsername ?? ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 22,
                      fontFamily: 'Inter', fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  isOutgoing ? 'Calling...' : 'Waiting for others...',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Inter'),
                ),
              ]),
            )
          else
            _VideoGrid(participants: participants, callType: call.callType),

          // ── Local camera preview (PiP top-right) ────────────────────────
          if (call.callType == 'video' && !call.cameraOff)
            Positioned(
              right: 12, top: 56, width: 100, height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(
                  controller.localRenderer,
                  mirror: true,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              ),
            ),

          // ── Top bar ──────────────────────────────────────────────────────
          Positioned(
            top: 4, left: 4,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: controller.endCall,
            ),
          ),

          // ── Controls ─────────────────────────────────────────────────────
          Positioned(
            bottom: 24, left: 0, right: 0,
            child: Column(children: [
              // Secondary: flip camera + add person
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                if (call.callType == 'video')
                  _SmallButton(
                    icon: Icons.flip_camera_android,
                    label: 'Flip',
                    onTap: controller.switchCamera,
                  ),
                SizedBox(width: call.callType == 'video' ? 32 : 0),
                _SmallButton(
                  icon: Icons.person_add,
                  label: 'Add',
                  onTap: () => _showAddPersonDialog(context, ref),
                ),
              ]),
              const SizedBox(height: 18),
              // Primary: mic + end + camera
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _ControlButton(
                  icon: call.micMuted ? Icons.mic_off : Icons.mic,
                  active: !call.micMuted,
                  onTap: controller.toggleMic,
                ),
                const SizedBox(width: 20),
                _ControlButton(
                  icon: Icons.call_end,
                  background: C.error,
                  onTap: controller.endCall,
                ),
                const SizedBox(width: 20),
                if (call.callType == 'video')
                  _ControlButton(
                    icon: call.cameraOff ? Icons.videocam_off : Icons.videocam,
                    active: !call.cameraOff,
                    onTap: controller.toggleCamera,
                  )
                else
                  _ControlButton(
                    icon: call.speakerOn ? Icons.volume_up : Icons.volume_off,
                    active: call.speakerOn,
                    onTap: controller.toggleSpeaker,
                  ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Future<void> _showAddPersonDialog(BuildContext context, WidgetRef ref) async {
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

    final currentIds = ref.read(callControllerProvider).participants.map((p) => p.userId).toSet();
    final available = friends.where((f) => !currentIds.contains(f['id'] as int)).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No more friends to add'), backgroundColor: C.textSub));
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
              final username = f['username']?.toString() ?? '?';
              return CheckboxListTile(
                value: selected.contains(id),
                activeColor: C.primary,
                checkColor: Colors.white,
                title: Text('@$username',
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
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                onPressed: selected.isEmpty
                    ? null
                    : () {
                        ref.read(callControllerProvider.notifier).addToCall(selected.toList());
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Inviting ${selected.length} person(s)…'),
                            backgroundColor: C.success));
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

// ── Video grid ────────────────────────────────────────────────────────────────

class _VideoGrid extends StatelessWidget {
  final List<CallParticipant> participants;
  final String callType;
  const _VideoGrid({required this.participants, required this.callType});

  @override
  Widget build(BuildContext context) {
    if (participants.length == 1) {
      return _ParticipantTile(participant: participants[0], callType: callType);
    }
    final cols = participants.length <= 4 ? 2 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols, mainAxisSpacing: 4, crossAxisSpacing: 4),
      itemCount: participants.length,
      itemBuilder: (_, i) => _ParticipantTile(participant: participants[i], callType: callType),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final CallParticipant participant;
  final String callType;
  const _ParticipantTile({required this.participant, required this.callType});

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
            child: CircleAvatar(
              radius: 40,
              backgroundColor: C.primary.withOpacity(0.25),
              child: Text(
                (participant.username ?? '?').isNotEmpty
                    ? participant.username![0].toUpperCase()
                    : '?',
                style: const TextStyle(color: Colors.white, fontSize: 30,
                    fontFamily: 'Inter', fontWeight: FontWeight.w700),
              ),
            ),
          ),
        Positioned(
          left: 8, bottom: 8,
          child: Text('@${participant.username ?? '...'}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 12, fontFamily: 'Inter',
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)])),
        ),
      ]),
    );
  }
}

// ── Buttons ───────────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color? background;
  final VoidCallback onTap;
  const _ControlButton(
      {required this.icon, required this.onTap, this.active = true, this.background});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
            color: background ?? (active ? Colors.white24 : Colors.white),
            shape: BoxShape.circle),
        child: Icon(icon,
            color: background != null ? Colors.white : (active ? Colors.white : Colors.black87),
            size: 26),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 44, height: 44,
          decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white70, fontSize: 11, fontFamily: 'Inter')),
      ]),
    );
  }
}
