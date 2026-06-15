import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/call_provider.dart';

class IncomingCallScreen extends ConsumerWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final call = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);

    ref.listen(callControllerProvider, (prev, next) {
      if (next.status == CallStatus.idle && context.canPop()) {
        context.pop();
      } else if (next.status == CallStatus.connected && context.canPop()) {
        context.pop();
        context.push('/connect/call');
      }
    });

    if (call.status != CallStatus.ringing) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: C.primaryDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 60),
            CircleAvatar(radius: 56, backgroundColor: Colors.white.withOpacity(0.15),
              child: Text((call.peerUsername ?? '?').isNotEmpty ? call.peerUsername![0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontSize: 40, fontFamily: 'Inter', fontWeight: FontWeight.w700))),
            const SizedBox(height: 24),
            Text(call.isMeeting ? 'Meeting invite' : (call.callType == 'video' ? 'Incoming video call' : 'Incoming audio call'),
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontFamily: 'Inter')),
            const SizedBox(height: 8),
            Text('@${call.peerUsername ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Inter', fontWeight: FontWeight.w800)),
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Column(children: [
                InkWell(
                  onTap: () => controller.rejectCall(),
                  borderRadius: BorderRadius.circular(36),
                  child: Container(width: 64, height: 64, decoration: const BoxDecoration(color: C.error, shape: BoxShape.circle),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 28)),
                ),
                const SizedBox(height: 8),
                const Text('Decline', style: TextStyle(color: Colors.white70, fontFamily: 'Inter', fontSize: 12)),
              ]),
              Column(children: [
                InkWell(
                  onTap: () => controller.acceptCall(),
                  borderRadius: BorderRadius.circular(36),
                  child: Container(width: 64, height: 64, decoration: const BoxDecoration(color: C.success, shape: BoxShape.circle),
                    child: Icon(call.isMeeting ? Icons.video_call : Icons.call, color: Colors.white, size: 28)),
                ),
                const SizedBox(height: 8),
                Text(call.isMeeting ? 'Join' : 'Accept', style: const TextStyle(color: Colors.white70, fontFamily: 'Inter', fontSize: 12)),
              ]),
            ]),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }
}
