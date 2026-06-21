import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/accommodation/data/accommodation_repository.dart';
import '../features/accommodation/presentation/accommodation_screen.dart';
import '../features/accommodation/presentation/add_accommodation_screen.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/budget/presentation/budget_screen.dart';
import '../features/checklist/presentation/checklist_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/expenses/data/expense_repository.dart';
import '../features/expenses/presentation/add_expense_screen.dart';
import '../features/expenses/presentation/edit_expense_screen.dart';
import '../features/expenses/presentation/expenses_screen.dart';
import '../features/fund/presentation/fund_screen.dart';
import '../features/members/presentation/accept_invite_screen.dart';
import '../features/members/presentation/invite_screen.dart';
import '../features/members/presentation/members_screen.dart';
import '../features/places/data/place_repository.dart';
import '../features/places/presentation/add_place_screen.dart';
import '../features/places/presentation/places_map_screen.dart';
import '../features/places/presentation/places_screen.dart';
import '../features/report/presentation/report_screen.dart';
import '../features/settings/presentation/about_screen.dart';
import '../features/settings/presentation/account_dialogs.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/web_page_screen.dart';
import '../features/settlement/presentation/settlement_screen.dart';
import '../features/tickets/data/ticket_repository.dart';
import '../features/tickets/presentation/add_ticket_screen.dart';
import '../features/tickets/presentation/all_tickets_screen.dart';
import '../features/tickets/presentation/ticket_qr_screen.dart';
import '../features/tickets/presentation/tickets_screen.dart';
import '../features/timeline/data/event_repository.dart';
import '../features/timeline/presentation/add_event_screen.dart';
import '../features/timeline/presentation/timeline_screen.dart';
import '../features/transport/data/transport_repository.dart';
import '../features/transport/presentation/add_transport_screen.dart';
import '../features/transport/presentation/transport_screen.dart';
import '../features/trips/domain/trip.dart';
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
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(
        path: '/web',
        builder: (context, state) {
          final WebPageArgs args = state.extra as WebPageArgs;
          return WebPageScreen(title: args.title, url: args.url);
        },
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
        path: '/trips/:rid/expenses/:expenseRid/edit',
        builder: (context, state) => EditExpenseScreen(
          tripRid: state.pathParameters['rid']!,
          expense: state.extra as ExpenseItem,
        ),
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
        path: '/trips/:rid/transports/new',
        builder: (context, state) =>
            AddTransportScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/transports/:transportRid/edit',
        builder: (context, state) => AddTransportScreen(
          tripRid: state.pathParameters['rid']!,
          existing: state.extra as TransportItem?,
        ),
      ),
      GoRoute(
        path: '/trips/:rid/transports',
        builder: (context, state) =>
            TransportScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/accommodations/new',
        builder: (context, state) =>
            AddAccommodationScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/accommodations/:accommodationRid/edit',
        builder: (context, state) => AddAccommodationScreen(
          tripRid: state.pathParameters['rid']!,
          existing: state.extra as AccommodationItem?,
        ),
      ),
      GoRoute(
        path: '/trips/:rid/accommodations',
        builder: (context, state) =>
            AccommodationScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/places/map',
        builder: (context, state) =>
            PlacesMapScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/places/new',
        builder: (context, state) =>
            AddPlaceScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/places/:placeRid/edit',
        builder: (context, state) => AddPlaceScreen(
          tripRid: state.pathParameters['rid']!,
          existing: state.extra as PlaceItem?,
        ),
      ),
      GoRoute(
        path: '/trips/:rid/places',
        builder: (context, state) =>
            PlacesScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/tickets/new',
        builder: (context, state) =>
            AddTicketScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/tickets/all',
        builder: (context, state) =>
            AllTicketsScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/tickets/:ticketRid/edit',
        builder: (context, state) => AddTicketScreen(
          tripRid: state.pathParameters['rid']!,
          existing: state.extra as Ticket?,
        ),
      ),
      GoRoute(
        path: '/trips/:rid/tickets/:ticketRid/qr',
        builder: (context, state) =>
            TicketQrScreen(ticket: state.extra as Ticket),
      ),
      GoRoute(
        path: '/trips/:rid/tickets',
        builder: (context, state) =>
            TicketsScreen(tripRid: state.pathParameters['rid']!),
      ),
      GoRoute(
        path: '/trips/:rid/edit',
        builder: (context, state) =>
            CreateTripScreen(existing: state.extra as Trip?),
      ),
      GoRoute(
        path: '/trips/:rid',
        builder: (context, state) =>
            TripDetailScreen(tripRid: state.pathParameters['rid']!),
      ),
    ],
  );
});
