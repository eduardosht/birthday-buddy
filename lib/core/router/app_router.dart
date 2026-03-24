import 'dart:async';

import 'package:birthday/features/account/account_screen.dart';
import 'package:flutter/scheduler.dart';
import 'package:birthday/features/add_person/add_person_screen.dart';
import 'package:birthday/features/auth/login_screen.dart';
import 'package:birthday/features/celebration/celebration_screen.dart';
import 'package:birthday/features/group_detail/group_detail_screen.dart';
import 'package:birthday/features/groups/groups_list_screen.dart';
import 'package:birthday/features/home/dashboard_tab.dart';
import 'package:birthday/features/home/home_screen.dart';
import 'package:birthday/features/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A [ChangeNotifier] that fires whenever the Supabase auth state changes.
/// GoRouter uses this as [refreshListenable] to re-evaluate the redirect guard.
class _SupabaseAuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _SupabaseAuthNotifier() {
    _sub = Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      // Defer to the next frame so any open dialogs/sheets are fully dismissed
      // before GoRouter evaluates the redirect guard.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final _authNotifier = _SupabaseAuthNotifier();

final appRouter = GoRouter(
  initialLocation: '/splash',
  refreshListenable: _authNotifier,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final loggedIn = session != null;
    final onAuth = state.matchedLocation == '/login';
    final onSplash = state.matchedLocation == '/splash';

    if (onSplash) return null;
    if (!loggedIn && !onAuth) return '/login';
    if (loggedIn && onAuth) return '/home';
    return null;
  },
  routes: [
    GoRoute(
      path: '/splash',
      builder: (ctx, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (ctx, state) => const LoginScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomeScreen(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              builder: (ctx, state) => const DashboardTab(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/groups',
              builder: (ctx, state) => const GroupsListScreen(),
              routes: [
                GoRoute(
                  path: ':groupId',
                  builder: (ctx, state) => GroupDetailScreen(
                    groupId: state.pathParameters['groupId']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'add-person',
                      builder: (ctx, state) => AddPersonScreen(
                        groupId: state.pathParameters['groupId']!,
                      ),
                    ),
                    GoRoute(
                      path: 'edit-person/:personId',
                      builder: (ctx, state) => AddPersonScreen(
                        groupId: state.pathParameters['groupId']!,
                        personId: state.pathParameters['personId'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/account',
              builder: (ctx, state) => const AccountScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/celebration/:personId',
      builder: (ctx, state) => CelebrationScreen(
        personId: state.pathParameters['personId']!,
      ),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(child: Text('Page not found: ${state.error}')),
  ),
);
