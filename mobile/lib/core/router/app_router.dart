// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/heatmap/screens/home_screen.dart';
import '../../features/sos/screens/sos_screen.dart';
import '../../features/live_share/screens/live_share_screen.dart';

/// A custom [ChangeNotifier] to trigger GoRouter refreshes on authentication changes.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/signin',
    // Listening to the auth stream changes to trigger redirect checks dynamically.
    refreshListenable: GoRouterRefreshStream(ref.watch(authStateProvider.stream)),
    redirect: (context, state) {
      // Grab current auth value
      final user = authState.valueOrNull;
      final isLoggingIn = state.matchedLocation == '/signin';

      // Avoid redirecting prematurely before auth initialization completes
      if (authState.isLoading) {
        return null;
      }

      if (user == null) {
        // If not logged in and not on /signin → redirect to /signin
        return isLoggingIn ? null : '/signin';
      } else {
        // If logged in and on /signin → redirect to /home
        return isLoggingIn ? '/home' : null;
      }
    },
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
