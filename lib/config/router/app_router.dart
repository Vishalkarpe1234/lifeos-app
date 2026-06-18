import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';
import 'package:lifeos/presentation/providers/notes_provider.dart';
import 'package:lifeos/presentation/screens/splash/splash_screen.dart';
import 'package:lifeos/presentation/screens/auth/login_screen.dart';
import 'package:lifeos/presentation/screens/auth/register_screen.dart';
import 'package:lifeos/presentation/screens/notes/notes_screen.dart';
import 'package:lifeos/presentation/screens/notes/note_editor_screen.dart';
import 'package:lifeos/presentation/screens/profile/profile_screen.dart';
import 'package:lifeos/presentation/screens/admin/admin_screen.dart';
import 'package:lifeos/presentation/screens/admin/admin_user_detail_screen.dart';
import 'package:lifeos/presentation/screens/admin/admin_location_screen.dart';
import 'package:lifeos/presentation/screens/connect/connect_screen.dart';
import 'package:lifeos/presentation/screens/connect/chat_screen.dart';
import 'package:lifeos/presentation/screens/location/location_history_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) {
      final loc = state.matchedLocation;
      final open = ['/login', '/register', '/'];
      if (!auth.loggedIn && !open.contains(loc)) return '/login';
      if (auth.loggedIn && open.contains(loc)) {
        return auth.isAdmin ? '/admin' : '/notes';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/notes', builder: (_, __) => const NotesScreen()),
      GoRoute(path: '/notes/new', builder: (_, __) => const NoteEditorScreen()),
      GoRoute(
        path: '/notes/:id/edit',
        builder: (_, s) => NoteEditorScreen(note: s.extra as Note?),
      ),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminScreen()),
      GoRoute(
        path: '/admin/users/:id',
        builder: (_, s) => AdminUserDetailScreen(
          userId: int.parse(s.pathParameters['id']!),
          userData: s.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/admin/users/:id/location',
        builder: (_, s) => AdminLocationScreen(
          userId: int.parse(s.pathParameters['id']!),
          userEmail: (s.extra as Map<String, dynamic>?)?['email']?.toString() ?? '',
        ),
      ),
      GoRoute(path: '/connect', builder: (_, __) => const ConnectScreen()),
      GoRoute(
        path: '/connect/chat/:friendId',
        builder: (_, s) => ChatScreen(
          friendId: int.parse(s.pathParameters['friendId']!),
          friend: s.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/location/history',
        builder: (_, __) => const LocationHistoryScreen(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
