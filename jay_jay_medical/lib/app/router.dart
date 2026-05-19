import 'package:go_router/go_router.dart';

import '../screens/barcode_scanner_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/grouped_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tablet_detail_screen.dart';
import '../screens/tablet_form_screen.dart';
import '../screens/tablets_list_screen.dart';

GoRouter buildRouter() {
  return GoRouter(
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/tablets',
        // ?status= filters by lifecycle status (active|expiring|expired|all).
        // ?tablet= and ?mfr= filter by tablet name / manufacturer (drill-down
        // from the grouped view). Defaults to status=all when no param given.
        builder: (context, state) => TabletsListScreen(
          statusFilter: state.uri.queryParameters['status'],
          tabletFilter: state.uri.queryParameters['tablet'],
          mfrFilter: state.uri.queryParameters['mfr'],
        ),
      ),
      GoRoute(
        path: '/tablets/new',
        // ?barcode= pre-fills the barcode field (used by the home scanner's
        // "not found → create" flow).
        builder: (context, state) => TabletFormScreen(
          prefillBarcode: state.uri.queryParameters['barcode'],
        ),
      ),
      GoRoute(
        path: '/tablets/scan',
        builder: (context, state) => const BarcodeScannerScreen(),
      ),
      GoRoute(
        path: '/tablets/:id',
        builder: (context, state) =>
            TabletDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/tablets/:id/edit',
        builder: (context, state) =>
            TabletFormScreen(editId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/grouped',
        builder: (context, state) => const GroupedScreen(),
      ),
    ],
  );
}
