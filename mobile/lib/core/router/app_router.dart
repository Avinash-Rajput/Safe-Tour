// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/providers/onboarding_provider.dart';
import '../../features/auth/screens/sign_in_screen.dart';
import '../../features/auth/screens/phone_signin_screen.dart';
import '../../features/auth/screens/onboarding_screen1.dart';
import '../../features/auth/screens/onboarding_screen2.dart';
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
  return GoRouter(
    initialLocation: '/signin',
    // Listening to both auth stream changes and profile existence changes.
    refreshListenable: ref.watch(routerRefreshProvider),
    redirect: (context, state) {
      // Grab current auth and profile state
      final authState = ref.read(authStateProvider);
      final user = authState.valueOrNull;
      final profileState = ref.read(profileStateProvider);
      final currentRoute = state.matchedLocation;
      final isAuthRoute =
          currentRoute == '/signin' || currentRoute == '/phone-signin';

      developer.log(
        'Router redirect check: Route=$currentRoute, UID=${user?.uid}, ProfileState=$profileState',
        name: 'SafeTour.Router',
      );

      // Avoid redirecting prematurely before auth initialization completes
      if (authState.isLoading) {
        developer.log(
          'Redirect decision: Auth is loading. No redirect. Final destination: $currentRoute',
          name: 'SafeTour.Router',
        );
        return null;
      }

      // 1. If not logged in at all
      if (user == null) {
        if (!isAuthRoute) {
          developer.log(
            'Redirect decision: user is null and target is not auth route. Redirecting to /signin. Final destination: /signin',
            name: 'SafeTour.Router',
          );
          return '/signin';
        }
        developer.log(
          'Redirect decision: user is null but target is auth route. No redirect. Final destination: $currentRoute',
          name: 'SafeTour.Router',
        );
        return null;
      }

      // 2. If logged in, but checking profile status (initial or loading)
      if (profileState == ProfileState.initial ||
          profileState == ProfileState.loading) {
        developer.log(
          'Redirect decision: Profile state is initial/loading. Waiting on current screen. Final destination: $currentRoute',
          name: 'SafeTour.Router',
        );
        return null;
      }

      // 3. If profile needs onboarding
      if (profileState == ProfileState.needsOnboarding) {
        final isOnboardingRoute =
            currentRoute == '/onboarding1' || currentRoute == '/onboarding2';
        if (!isOnboardingRoute) {
          developer.log(
            'Redirect decision: User needs onboarding, not on onboarding route. Redirecting to /onboarding1. Final destination: /onboarding1',
            name: 'SafeTour.Router',
          );
          return '/onboarding1';
        }
        developer.log(
          'Redirect decision: User needs onboarding, already on onboarding route. No redirect. Final destination: $currentRoute',
          name: 'SafeTour.Router',
        );
        return null;
      }

      // 4. If profile exists
      if (profileState == ProfileState.exists) {
        if (isAuthRoute) {
          developer.log(
            'Redirect decision: Profile exists, on auth route. Redirecting to /home. Final destination: /home',
            name: 'SafeTour.Router',
          );
          return '/home';
        }
        developer.log(
          'Redirect decision: Profile exists, on target private/onboarding route. No redirect. Final destination: $currentRoute',
          name: 'SafeTour.Router',
        );
        return null;
      }

      // 5. If profile check failed (error status)
      if (profileState == ProfileState.error) {
        if (!isAuthRoute) {
          developer.log(
            'Redirect decision: Profile check error, on private route. Redirecting to /signin. Final destination: /signin',
            name: 'SafeTour.Router',
          );
          return '/signin';
        }
        developer.log(
          'Redirect decision: Profile check error, already on auth route. No redirect. Final destination: $currentRoute',
          name: 'SafeTour.Router',
        );
        return null;
      }

      developer.log(
        'Redirect decision: Fallback default. No redirect. Final destination: $currentRoute',
        name: 'SafeTour.Router',
      );
      return null;
    },
    routes: [
      GoRoute(
        path: '/signin',
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: '/phone-signin',
        builder: (context, state) => const PhoneSignInScreen(),
      ),
      GoRoute(
        path: '/onboarding1',
        builder: (context, state) => const OnboardingScreen1(),
      ),
      GoRoute(
        path: '/onboarding2',
        builder: (context, state) => const OnboardingScreen2(),
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
