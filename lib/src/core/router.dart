import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/checklist/presentation/checklist_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/expenses/presentation/add_expense_screen.dart';
import '../features/expenses/presentation/expenses_screen.dart';
import '../features/fund/presentation/fund_screen.dart';
import '../features/members/presentation/accept_invite_screen.dart';
import '../features/members/presentation/invite_screen.dart';
import '../features/members/presentation/members_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/settlement/presentation/settlement_screen.dart';
import '../features/timeline/data/event_repository.dart';
import '../features/timeline/presentation/add_event_screen.dart';
import '../features/timeline/presentation/timeline_screen.dart';
import '../features/trips/presentation/create_trip_screen.dart';
import '../features/trips/presentation/trip_detail_screen.dart';
import '../features/trips/presentation/trips_screen.dart';
import 'splash_screen.dart';

/// Bridges auth-state changes to go_router so the redirect re-runs on login/logout.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authControllerProvider, (_, __) => notifyListeners());
  }
}

/// App router with an auth-aware redirect: unauthenticated users are sent to /login; while the
/// stored session resolves on startup, a splash is shown.
final routerProvider = Provider<GoRouter>((ref) {
  final _AuthListenable listenable = _AuthListenable(ref);
  ref.onDispose(listenable.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,
    redirect: (context, state) {
      final AsyncValue<Object?> auth = ref.read(authControllerProvider);
      if (auth.isLoading) {
        return '/splash';
      }
      final bool loggedIn = auth.valueOrNull != null;
      final String loc = state.matchedLocation;
      final bool atAuth = loc == '/login' || loc == '/register';
      if (!loggedIn) {
        return atAuth ? null : '/login';
      }
      if (atAuth || loc == '/splash') {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/', builder: (_, __) => const TripsScreen()),
      GoRoute(
        path: '/join',
        builder: (context, state) =>
            AcceptInviteScreen(token: state.uri.queryParameters['token']),
      ),
      GoRoute(path: '/trips/new', builder: (_, __) => const CreateTripScreen()),
      GoRoute(
        path: '/trips/:rid/dashboard',
        builder: (context, state) =>
            DashboardScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/members/invite',
        builder: (context, state) =>
            InviteScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/expenses/new',
        builder: (context, state) =>
            AddExpenseScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/expenses',
        builder: (context, state) =>
            ExpensesScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/budgets',
        builder: (context, state) =>
            BudgetScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/settlement',
        builder: (context, state) =>
            SettlementScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/timeline/new',
        builder: (context, state) =>
            AddEventScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/timeline/:eventRid/edit',
        builder: (context, state) => AddEventScreen(
          tripRid: state.pathParameters['rid']!,
          existing: state.extra as EventItem?,
        ),
      ),
      GoRoute(
        path: '/trips/:rid/timeline',
        builder: (context, state) =>
            TimelineScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/checklist',
        builder: (context, state) =>
            ChecklistScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/fund',
        builder: (context, state) =>
            FundScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/report',
        builder: (context, state) =>
            ReportScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/members',
        builder: (context, state) =>
            MembersScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid',
        builder: (context, state) =>
            TripDetailScreen(tripRid: state.pathParameters['rid']!),
      ),
    ],
  );
});
