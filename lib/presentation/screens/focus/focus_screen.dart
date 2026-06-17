import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/config/theme/app_theme.dart';
import 'package:lifeos/services/api/api_client.dart';

enum FocusMode { focus, shortBreak, longBreak }

class FocusTimerState {
  final int totalSeconds;
  final int secondsLeft;
  final bool isRunning;
  final bool isPaused;
  final int roundsCompleted;
  final FocusMode mode;

  const FocusTimerState({
    this.totalSeconds = 25 * 60,
    this.secondsLeft = 25 * 60,
    this.isRunning = false,
    this.isPaused = false,
    this.roundsCompleted = 0,
    this.mode = FocusMode.focus,
  });

  FocusTimerState copyWith({
    int? totalSeconds,
    int? secondsLeft,
    bool? isRunning,
    bool? isPaused,
    int? roundsCompleted,
    FocusMode? mode,
  }) =>
      FocusTimerState(
        totalSeconds: totalSeconds ?? this.totalSeconds,
        secondsLeft: secondsLeft ?? this.secondsLeft,
        isRunning: isRunning ?? this.isRunning,
        isPaused: isPaused ?? this.isPaused,
        roundsCompleted: roundsCompleted ?? this.roundsCompleted,
        mode: mode ?? this.mode,
      );

  double get progress =>
      totalSeconds > 0 ? 1 - (secondsLeft / totalSeconds) : 0;

  String get timeString {
    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class FocusTimerNotifier extends StateNotifier<FocusTimerState> {
  Timer? _timer;

  FocusTimerNotifier() : super(const FocusTimerState());

  void setMode(FocusMode mode, {int? customMinutes}) {
    _timer?.cancel();
    int minutes;
    if (customMinutes != null) {
      minutes = customMinutes;
    } else {
      switch (mode) {
        case FocusMode.focus:
          minutes = 25;
        case FocusMode.shortBreak:
          minutes = 5;
        case FocusMode.longBreak:
          minutes = 15;
      }
    }
    state = FocusTimerState(
      totalSeconds: minutes * 60,
      secondsLeft: minutes * 60,
      roundsCompleted: state.roundsCompleted,
      mode: mode,
    );
  }

  void start(VoidCallback onComplete) {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true, isPaused: false);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.secondsLeft <= 1) {
        _timer?.cancel();
        state = state.copyWith(
          secondsLeft: 0,
          isRunning: false,
          roundsCompleted: state.mode == FocusMode.focus
              ? state.roundsCompleted + 1
              : state.roundsCompleted,
        );
        if (state.mode == FocusMode.focus) onComplete();
      } else {
        state = state.copyWith(secondsLeft: state.secondsLeft - 1);
      }
    });
  }

  void pause() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false, isPaused: true);
  }

  void reset() {
    _timer?.cancel();
    state = FocusTimerState(
      totalSeconds: state.totalSeconds,
      secondsLeft: state.totalSeconds,
      roundsCompleted: state.roundsCompleted,
      mode: state.mode,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusTimerProvider =
    StateNotifierProvider.autoDispose<FocusTimerNotifier, FocusTimerState>(
  (ref) => FocusTimerNotifier(),
);

final focusSessionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final r = await dio.get('/api/v1/focus/sessions', queryParameters: {'page_size': 20});
  return List<Map<String, dynamic>>.from(r.data['items']);
});

class FocusScreen extends ConsumerWidget {
  const FocusScreen({super.key});

  Future<void> _onComplete(WidgetRef ref, BuildContext context) async {
    try {
      final timerState = ref.read(focusTimerProvider);
      final dio = ref.read(dioProvider);
      await dio.post('/api/v1/focus/sessions', data: {
        'duration_minutes': timerState.totalSeconds ~/ 60,
        'rounds_completed': 1,
        'focus_type': 'pomodoro',
      });
      ref.invalidate(focusSessionsProvider);
    } catch (_) {}
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Focus session complete! Great work!'),
        backgroundColor: C.success,
        duration: Duration(seconds: 3),
      ));
    }
  }

  void _editTime(BuildContext context, WidgetRef ref, FocusTimerState state) {
    final ctrl = TextEditingController(text: '${state.totalSeconds ~/ 60}');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set Timer (minutes)',
            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Minutes'),
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final m = int.tryParse(ctrl.text);
              if (m != null && m > 0 && m <= 120) {
                ref
                    .read(focusTimerProvider.notifier)
                    .setMode(state.mode, customMinutes: m);
              }
              Navigator.pop(context);
            },
            child: const Text('Set'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusTimerProvider);
    final modeColor = state.mode == FocusMode.focus ? C.primary : C.success;

    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(title: const Text('Focus Timer')),
      body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            // Mode tabs
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.border)),
              child: Row(children: [
                _modeTab(ref, 'Focus', FocusMode.focus, state.mode),
                _modeTab(ref, 'Short Break', FocusMode.shortBreak, state.mode),
                _modeTab(ref, 'Long Break', FocusMode.longBreak, state.mode),
              ]),
            ),
            const SizedBox(height: 32),

            // Timer circle
            Center(
              child: GestureDetector(
                onTap: () => _editTime(context, ref, state),
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(alignment: Alignment.center, children: [
                    CustomPaint(
                      size: const Size(240, 240),
                      painter: _CircleTimerPainter(
                          progress: state.progress, color: modeColor),
                    ),
                    Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(
                        state.mode == FocusMode.focus
                            ? 'FOCUS'
                            : state.mode == FocusMode.shortBreak
                                ? 'SHORT BREAK'
                                : 'LONG BREAK',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: modeColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.timeString,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: modeColor),
                      ),
                      const SizedBox(height: 4),
                      const Text('tap to edit',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: C.textMuted)),
                    ]),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Motivational text
            if (state.isRunning && state.mode == FocusMode.focus)
              Center(
                  child: Text(
                _motivationalMessage(state.roundsCompleted),
                style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: C.textSub),
                textAlign: TextAlign.center,
              )),

            const SizedBox(height: 24),

            // Controls
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _controlBtn(Icons.refresh_rounded, 'Reset', C.textSub, () {
                ref.read(focusTimerProvider.notifier).reset();
              }),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: state.isRunning
                    ? () => ref.read(focusTimerProvider.notifier).pause()
                    : () => ref.read(focusTimerProvider.notifier).start(
                          () => _onComplete(ref, context),
                        ),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: modeColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: modeColor.withOpacity(0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Icon(
                      state.isRunning
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 34),
                ),
              ),
              const SizedBox(width: 20),
              _controlBtn(Icons.skip_next_rounded, 'Skip', C.textSub, () {
                ref.read(focusTimerProvider.notifier).reset();
                if (state.mode == FocusMode.focus) {
                  ref
                      .read(focusTimerProvider.notifier)
                      .setMode(FocusMode.shortBreak);
                } else {
                  ref
                      .read(focusTimerProvider.notifier)
                      .setMode(FocusMode.focus);
                }
              }),
            ]),
            const SizedBox(height: 20),

            // Rounds
            Center(
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Icon(Icons.radio_button_checked_rounded,
                      size: 14, color: C.textMuted),
                  const SizedBox(width: 6),
                  Text(
                      'Round ${state.roundsCompleted + 1}  •  ${state.roundsCompleted} completed',
                      style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: C.textSub)),
                ])),
            const SizedBox(height: 32),

            // Session history
            const Text('SESSION HISTORY',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: C.textMuted,
                    letterSpacing: 1)),
            const SizedBox(height: 10),
            ref.watch(focusSessionsProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Failed to load sessions',
                  style:
                      TextStyle(fontFamily: 'Inter', color: C.textSub)),
              data: (sessions) => sessions.isEmpty
                  ? const Text(
                      'No sessions yet. Start your first focus session!',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: C.textSub))
                  : Column(
                      children: sessions
                          .map((s) => Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: C.border)),
                                child: Row(children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color: C.primary.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    child: const Icon(Icons.timer_rounded,
                                        color: C.primary, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(
                                            '${s['duration_minutes']} minutes',
                                            style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: C.text)),
                                        Text(s['date']?.toString() ?? '',
                                            style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                color: C.textMuted)),
                                      ])),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: C.success.withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(6)),
                                    child: Text(
                                        s['focus_type'] ?? 'pomodoro',
                                        style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11,
                                            color: C.success)),
                                  ),
                                ]),
                              ))
                          .toList()),
            ),
          ]),
    );
  }

  Widget _modeTab(
      WidgetRef ref, String label, FocusMode mode, FocusMode current) {
    final isSelected = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(focusTimerProvider.notifier).setMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? C.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : C.textSub)),
        ),
      ),
    );
  }

  Widget _controlBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: color)),
      ]),
    );
  }

  String _motivationalMessage(int rounds) {
    const msgs = [
      'Stay focused. You\'ve got this!',
      'Deep work in progress...',
      'One focused session at a time.',
      'Eliminate distractions.',
      'You are in the zone.',
    ];
    return msgs[rounds % msgs.length];
  }
}

class _CircleTimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CircleTimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Background circle
    paint.color = color.withOpacity(0.15);
    canvas.drawCircle(center, radius, paint);

    // Progress arc
    paint.color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_CircleTimerPainter old) =>
      old.progress != progress || old.color != color;
}
