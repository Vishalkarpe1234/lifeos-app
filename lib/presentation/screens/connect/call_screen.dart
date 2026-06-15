import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/call_provider.dart';

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

    if (call.status == CallStatus.idle) {
      return const SizedBox.shrink();
    }

    final isOutgoing = call.status == CallStatus.outgoing;
    final participants = call.participants;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(children: [
          if (isOutgoing || participants.isEmpty)
            Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(radius: 48, backgroundColor: C.primary.withOpacity(0.25),
                  child: Text((call.peerUsername ?? 'M')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontFamily: 'Inter', fontWeight: FontWeight.w700))),
                const SizedBox(height: 16),
                Text(call.isMeeting ? 'Meeting' : '@${call.peerUsername ?? ''}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(isOutgoing ? 'Calling...' : 'Waiting for others to join...',
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Inter')),
              ]),
            )
          else
            _VideoGrid(participants: participants, callType: call.callType),

          // local preview
          if (call.callType == 'video' && !call.cameraOff)
            Positioned(
              right: 16, bottom: 120, width: 100, height: 140,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: RTCVideoView(controller.localRenderer, mirror: true, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover),
              ),
            ),

          // top bar
          Positioned(top: 8, left: 8, right: 8, child: Row(children: [
            IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: controller.endCall),
            const Spacer(),
          ])),

          // bottom controls
          Positioned(bottom: 24, left: 0, right: 0, child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
                ),
            ],
          )),
        ]),
      ),
    );
  }
}

class _VideoGrid extends StatelessWidget {
  final List<CallParticipant> participants;
  final String callType;
  const _VideoGrid({required this.participants, required this.callType});

  @override
  Widget build(BuildContext context) {
    if (participants.length == 1) {
      return _ParticipantTile(participant: participants[0], callType: callType);
    }
    final crossAxisCount = participants.length <= 4 ? 2 : 3;
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, mainAxisSpacing: 4, crossAxisSpacing: 4),
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
    final hasVideo = callType == 'video' && participant.rendererReady;
    return Container(
      color: const Color(0xFF1C1C1E),
      child: Stack(fit: StackFit.expand, children: [
        if (hasVideo)
          RTCVideoView(participant.renderer, objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover)
        else
          Center(
            child: CircleAvatar(radius: 36, backgroundColor: C.primary.withOpacity(0.25),
              child: Text((participant.username ?? '?').isNotEmpty ? participant.username![0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'Inter', fontWeight: FontWeight.w700))),
          ),
        Positioned(left: 8, bottom: 8, child: Text('@${participant.username ?? '...'}',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'Inter', fontWeight: FontWeight.w600,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)]))),
      ]),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color? background;
  final VoidCallback onTap;
  const _ControlButton({required this.icon, required this.onTap, this.active = true, this.background});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(32),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: background ?? (active ? Colors.white24 : Colors.white),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: background != null ? Colors.white : (active ? Colors.white : Colors.black87)),
      ),
    );
  }
}
