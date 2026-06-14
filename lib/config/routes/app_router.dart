import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lifeos/presentation/screens/splash/splash_screen.dart';
import 'package:lifeos/presentation/screens/auth/login_screen.dart';
import 'package:lifeos/presentation/screens/auth/pin_login_screen.dart';
import 'package:lifeos/presentation/screens/auth/biometric_screen.dart';
import 'package:lifeos/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:lifeos/presentation/screens/profile/profile_screen.dart';
import 'package:lifeos/presentation/screens/research/research_screen.dart';
import 'package:lifeos/presentation/screens/research/publication_form_screen.dart';
import 'package:lifeos/presentation/screens/teaching/teaching_screen.dart';
import 'package:lifeos/presentation/screens/projects/projects_screen.dart';
import 'package:lifeos/presentation/screens/projects/project_detail_screen.dart';
import 'package:lifeos/presentation/screens/tasks/tasks_screen.dart';
import 'package:lifeos/presentation/screens/notes/notes_screen.dart';
import 'package:lifeos/presentation/screens/notes/note_editor_screen.dart';
import 'package:lifeos/presentation/screens/finance/finance_screen.dart';
import 'package:lifeos/presentation/screens/habits/habits_screen.dart';
import 'package:lifeos/presentation/screens/ai/ai_chat_screen.dart';
import 'package:lifeos/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:lifeos/presentation/screens/settings/settings_screen.dart';
import 'package:lifeos/presentation/screens/media/media_library_screen.dart';
import 'package:lifeos/presentation/screens/certificates/certificates_screen.dart';
import 'package:lifeos/presentation/screens/journal/journal_screen.dart';
import 'package:lifeos/presentation/screens/bookmarks/bookmarks_screen.dart';
import 'package:lifeos/presentation/widgets/common/main_shell.dart';
import 'package:lifeos/presentation/providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.hasToken;
      final onAuthPage = state.matchedLocation == '/login' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/pin-login' ||
          state.matchedLocation == '/biometric';

      if (!isAuthenticated && !onAuthPage) return '/login';
      if (isAuthenticated && state.matchedLocation == '/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/pin-login', builder: (_, __) => const PINLoginScreen()),
      GoRoute(path: '/biometric', builder: (_, __) => const BiometricScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(
            path: '/research',
            builder: (_, __) => const ResearchScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const PublicationFormScreen()),
              GoRoute(
                path: ':id/edit',
                builder: (_, state) => PublicationFormScreen(publicationId: int.tryParse(state.pathParameters['id'] ?? '')),
              ),
            ],
          ),
          GoRoute(path: '/teaching', builder: (_, __) => const TeachingScreen()),
          GoRoute(
            path: '/projects',
            builder: (_, __) => const ProjectsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => ProjectDetailScreen(projectId: int.parse(state.pathParameters['id']!)),
              ),
            ],
          ),
          GoRoute(path: '/tasks', builder: (_, __) => const TasksScreen()),
          GoRoute(
            path: '/notes',
            builder: (_, __) => const NotesScreen(),
            routes: [
              GoRoute(path: 'new', builder: (_, __) => const NoteEditorScreen()),
              GoRoute(
                path: ':id',
                builder: (_, state) => NoteEditorScreen(noteId: int.tryParse(state.pathParameters['id'] ?? '')),
              ),
            ],
          ),
          GoRoute(path: '/finance', builder: (_, __) => const FinanceScreen()),
          GoRoute(path: '/habits', builder: (_, __) => const HabitsScreen()),
          GoRoute(path: '/ai', builder: (_, __) => const AIChatScreen()),
          GoRoute(path: '/media', builder: (_, __) => const MediaLibraryScreen()),
          GoRoute(path: '/certificates', builder: (_, __) => const CertificatesScreen()),
          GoRoute(path: '/journal', builder: (_, __) => const JournalScreen()),
          GoRoute(path: '/bookmarks', builder: (_, __) => const BookmarksScreen()),
          GoRoute(path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
