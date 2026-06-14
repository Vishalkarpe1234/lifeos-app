import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with TickerProviderStateMixin {
  late final AnimationController _orb1;
  late final AnimationController _orb2;
  late final AnimationController _orb3;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _orb1 = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _orb2 = AnimationController(vsync: this, duration: const Duration(seconds: 11))..repeat(reverse: true);
    _orb3 = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orb1.dispose();
    _orb2.dispose();
    _orb3.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF03020F), Color(0xFF0A0520), Color(0xFF060215), Color(0xFF020109)],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Animated orbs ─────────────────────────────────────────
            _buildOrb(_orb1, Alignment(-0.9, -0.7), 280, const Color(0xFF6366F1), 0.18),
            _buildOrb(_orb2, Alignment(0.8, -0.3), 200, const Color(0xFF8B5CF6), 0.12),
            _buildOrb(_orb3, Alignment(-0.2, 0.8), 240, const Color(0xFF4F46E5), 0.14),

            // ── Noise/grid overlay ────────────────────────────────────
            Positioned.fill(
              child: CustomPaint(painter: _GridPainter()),
            ),

            // ── Main content ──────────────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLogo(),
                      const SizedBox(height: 48),
                      _buildCard(context),
                      const SizedBox(height: 32),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrb(AnimationController ctrl, Alignment align, double size, Color color, double opacity) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final dx = math.sin(ctrl.value * math.pi * 2) * 30;
        final dy = math.cos(ctrl.value * math.pi * 2) * 20;
        return Align(
          alignment: FractionalOffset(
            (align.x + 1) / 2 + dx / 400,
            (align.y + 1) / 2 + dy / 800,
          ),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent]),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.25 + _pulse.value * 0.18),
                  blurRadius: 32 + _pulse.value * 14,
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
        ).animate().scale(duration: 700.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        const Text(
          'VK OS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            fontFamily: 'Inter',
            letterSpacing: -1.5,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        const Text(
          'Your Life, Organized, Intelligent.',
          style: TextStyle(
            color: Color(0xFF9896C4),
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
        ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
      ],
    );
  }

  Widget _buildCard(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to continue your journey',
                style: TextStyle(color: Color(0xFF9896C4), fontSize: 13, fontFamily: 'Inter'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Login button
              _GlassButton(
                label: 'Sign In',
                icon: Icons.login_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                onTap: () => context.go('/login'),
              ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 14),

              // Register button
              _GlassButton(
                label: 'Create Account',
                icon: Icons.person_add_rounded,
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF6366F1)]),
                onTap: () => context.go('/register'),
              ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 12, fontFamily: 'Inter')),
                  ),
                  Expanded(child: Divider(color: Colors.white.withOpacity(0.12))),
                ],
              ),

              const SizedBox(height: 18),

              // Admin login
              GestureDetector(
                onTap: () => context.go('/admin-login'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.admin_panel_settings_rounded, size: 18, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 8),
                      Text('Admin Login', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 650.ms),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildFooter() {
    return Text(
      'One App. One Life. Everything Connected.',
      style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 11, fontFamily: 'Inter'),
      textAlign: TextAlign.center,
    ).animate().fadeIn(delay: 800.ms);
  }
}

class _GlassButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback onTap;
  const _GlassButton({required this.label, required this.icon, required this.gradient, required this.onTap});

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: (widget.gradient.colors.first).withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(widget.label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..strokeWidth = 0.5;
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
