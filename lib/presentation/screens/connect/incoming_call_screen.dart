import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/presentation/providers/call_provider.dart';

class IncomingCallScreen extends ConsumerStatefulWidget {
  const IncomingCallScreen({super.key});
  @override
  ConsumerState<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends ConsumerState<IncomingCallScreen> {
  int _secondsLeft = 45;
  Timer? _countdownTimer;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _countdownTimer?.cancel();
        ref.read(callControllerProvider.notifier).rejectCall();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_accepting) return;
    setState(() => _accepting = true);
    _countdownTimer?.cancel();
    await ref.read(callControllerProvider.notifier).acceptCall();
    // Navigation handled by ref.listen below
  }

  @override
  Widget build(BuildContext context) {
    final call = ref.watch(callControllerProvider);
    final controller = ref.read(callControllerProvider.notifier);

    ref.listen(callControllerProvider, (prev, next) {
      if (!mounted) return;
      if (next.error != null && next.error != prev?.error) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(next.error!), backgroundColor: C.error));
      }
      if (next.status == CallStatus.idle) {
        _countdownTimer?.cancel();
        if (context.canPop()) context.pop();
      } else if (next.status == CallStatus.connected) {
        _countdownTimer?.cancel();
        if (context.canPop()) context.pop();
        context.push('/connect/call');
      }
    });

    if (call.status != CallStatus.ringing) return const SizedBox.shrink();

    final isVideo = call.callType == 'video';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF0D0D0D)],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            const SizedBox(height: 60),

            // Animated ripple avatar
            Stack(alignment: Alignment.center, children: [
              // Outer ripple
              Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06)),
              ),
              // Middle ripple
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08)),
              ),
              CircleAvatar(
                radius: 56,
                backgroundColor: C.primary.withOpacity(0.7),
                child: Text(
                  (call.peerUsername ?? '?').isNotEmpty
                      ? call.peerUsername![0].toUpperCase()
                      : '?',
                  style: const TextStyle(color: Colors.white, fontSize: 44,
                      fontFamily: 'Inter', fontWeight: FontWeight.w700),
                ),
              ),
            ]),

            const SizedBox(height: 28),
            Text(
              call.isMeeting
                  ? 'Meeting Invite'
                  : isVideo ? 'Incoming Video Call' : 'Incoming Audio Call',
              style: const TextStyle(color: Colors.white54, fontSize: 14,
                  fontFamily: 'Inter', letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),
            Text(
              '@${call.peerUsername ?? ''}',
              style: const TextStyle(color: Colors.white, fontSize: 28,
                  fontFamily: 'Inter', fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 8),
            // Countdown
            Text(
              'Auto-decline in $_secondsLeft s',
              style: TextStyle(
                  color: _secondsLeft <= 10 ? C.error : Colors.white38,
                  fontSize: 12, fontFamily: 'Inter'),
            ),

            const Spacer(),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 0, 40, 56),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                // Decline
                Column(children: [
                  GestureDetector(
                    onTap: controller.rejectCall,
                    child: Container(
                      width: 72, height: 72,
                      decoration: const BoxDecoration(color: C.error, shape: BoxShape.circle),
                      child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Decline',
                      style: TextStyle(color: Colors.white70, fontFamily: 'Inter', fontSize: 13)),
                ]),

                // Accept
                Column(children: [
                  GestureDetector(
                    onTap: _accepting ? null : _accept,
                    child: Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                          color: _accepting ? Colors.white24 : C.success,
                          shape: BoxShape.circle),
                      child: _accepting
                          ? const SizedBox(
                              width: 28, height: 28,
                              child: Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              ))
                          : Icon(
                              call.isMeeting
                                  ? Icons.video_call_rounded
                                  : isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                              color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    call.isMeeting ? 'Join' : 'Accept',
                    style: const TextStyle(color: Colors.white70, fontFamily: 'Inter', fontSize: 13),
                  ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
