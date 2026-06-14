import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/presentation/screens/splash/splash_screen.dart';
import 'package:lifeos/presentation/screens/auth/login_screen.dart';
import 'package:lifeos/presentation/screens/auth/register_screen.dart';
import 'package:lifeos/presentation/screens/auth/verify_otp_screen.dart';
import 'package:lifeos/presentation/screens/auth/forgot_password_screen.dart';
import 'package:lifeos/presentation/screens/notes/notes_screen.dart';
import 'package:lifeos/presentation/screens/notes/note_editor_screen.dart';
import 'package:lifeos/presentation/screens/profile/profile_screen.dart';
import 'package:lifeos/presentation/screens/admin/admin_screen.dart';
import 'package:lifeos/presentation/providers/notes_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authStateProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isAuth = auth.hasToken;
      final loc = state.matchedLocation;
      final authRoutes = ['/login', '/register', '/verify-otp', '/forgot-password', '/'];
      if (!isAuth && !authRoutes.contains(loc)) return '/login';
      if (isAuth && (loc == '/login' || loc == '/register' || loc == '/')) return '/notes';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, s) => LoginScreen(adminMode: s.uri.queryParameters['admin'] == 'true')),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/verify-otp', builder: (_, s) => VerifyOTPScreen(email: s.extra as String? ?? '')),
      GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),
      GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
      GoRoute(path: '/notes/new', builder: (_, __) => const NoteEditorScreen()),
      GoRoute(path: '/notes/:id/edit', builder: (_, s) => NoteEditorScreen(noteId: int.tryParse(s.pathParameters['id'] ?? ''), existingNote: s.extra as Note?)),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: Center(child: Text('Page not found: ${state.uri}', style: const TextStyle(color: Color(0xFF1E1E3F), fontFamily: 'Inter'))),
    ),
  );
});
