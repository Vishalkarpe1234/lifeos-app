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
import 'package:lifeos/presentation/screens/shell/main_shell.dart';
import 'package:lifeos/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:lifeos/presentation/screens/tasks/tasks_screen.dart';
import 'package:lifeos/presentation/screens/habits/habits_screen.dart';
import 'package:lifeos/presentation/screens/journal/journal_screen.dart';
import 'package:lifeos/presentation/screens/goals/goals_screen.dart';
import 'package:lifeos/presentation/screens/projects/projects_screen.dart';
import 'package:lifeos/presentation/screens/focus/focus_screen.dart';
import 'package:lifeos/presentation/screens/snippets/snippets_screen.dart';
import 'package:lifeos/presentation/screens/analytics/analytics_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);
  return GoRouter(
    initialLocation: '/',
    redirect: (ctx, state) {
      final loc = state.matchedLocation;
      final open = ['/login', '/register', '/'];
      if (!auth.loggedIn && !open.contains(loc)) return '/login';
      if (auth.loggedIn && (loc == '/login' || loc == '/register' || loc == '/')) {
        return auth.isAdmin ? '/admin' : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Admin routes — outside shell
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

      // Shell routes with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainShell(
          child: child,
          location: state.matchedLocation,
        ),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (_, __) => const TasksScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (_, __) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/journal',
            builder: (_, __) => const JournalScreen(),
          ),
          GoRoute(
            path: '/goals',
            builder: (_, __) => const GoalsScreen(),
          ),
          GoRoute(
            path: '/projects',
            builder: (_, __) => const ProjectsScreen(),
          ),
          GoRoute(
            path: '/focus',
            builder: (_, __) => const FocusScreen(),
          ),
          GoRoute(
            path: '/snippets',
            builder: (_, __) => const SnippetsScreen(),
          ),
          GoRoute(
            path: '/analytics',
            builder: (_, __) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: '/notes',
            builder: (_, __) => const NotesScreen(),
          ),
          GoRoute(
            path: '/notes/new',
            builder: (_, __) => const NoteEditorScreen(),
          ),
          GoRoute(
            path: '/notes/:id/edit',
            builder: (_, s) => NoteEditorScreen(note: s.extra as Note?),
          ),
          GoRoute(
            path: '/connect',
            builder: (_, __) => const ConnectScreen(),
          ),
          GoRoute(
            path: '/connect/chat/:friendId',
            builder: (_, s) => ChatScreen(
              friendId: int.parse(s.pathParameters['friendId']!),
              friend: s.extra as Map<String, dynamic>?,
            ),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});
