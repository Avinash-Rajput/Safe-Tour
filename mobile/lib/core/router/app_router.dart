import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/heatmap/screens/home_screen.dart';
import '../../features/sos/screens/sos_screen.dart';
import '../../features/live_share/screens/live_share_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/signin',
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/sos',
        builder: (context, state) => const SosScreen(),
      ),
      GoRoute(
        path: '/live-share',
        builder: (context, state) => const LiveShareScreen(),
      ),
    ],
  );
});
