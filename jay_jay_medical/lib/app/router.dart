import 'package:go_router/go_router.dart';

import '../screens/dashboard_screen.dart';
import '../screens/grouped_screen.dart';
import '../screens/scan_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/tablet_form_screen.dart';
import '../screens/tablet_list_screen.dart';

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
        builder: (context, state) => TabletListScreen(
          status: state.uri.queryParameters['status'],
          tabletFilter: state.uri.queryParameters['tablet'],
          mfrFilter: state.uri.queryParameters['mfr'],
        ),
      ),
      GoRoute(
        path: '/tablets/new',
        builder: (context, state) => const TabletFormScreen(),
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
      GoRoute(
        path: '/scan',
        builder: (context, state) =>
            ScanScreen(returnTo: state.uri.queryParameters['return']),
      ),
    ],
  );
}
