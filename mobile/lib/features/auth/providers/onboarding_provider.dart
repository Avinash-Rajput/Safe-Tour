import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/api_service.dart';
import 'auth_provider.dart';

/// Represents the state of the user profile check in the backend database.
enum ProfileState {
  initial,
  loading,
  exists,
  needsOnboarding,
  error,
}

/// State notifier to manage the profile existence state synchronously.
class ProfileStateNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;
  bool _isChecking = false;

  ProfileStateNotifier(this._ref) : super(ProfileState.initial) {
    // Listen to Firebase Auth state changes.
    // When a user signs in, trigger a profile existence check.
    _ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      final user = next.valueOrNull;
      developer.log(
        'ProfileStateNotifier: Firebase auth state changed. User: ${user?.uid}',
        name: 'SafeTour.Auth',
      );
      if (user == null) {
        state = ProfileState.initial;
        _isChecking = false;
      } else {
        checkProfile();
      }
    }, fireImmediately: true);
  }

  void setExists() {
    developer.log(
      'PROFILE STATE -> exists',
      name: 'SafeTour.Auth',
    );
    state = ProfileState.exists;
  }

  Future<void> checkProfile() async {
    if (_isChecking) {
      developer.log(
        'ProfileStateNotifier: checkProfile aborted (already checking)',
        name: 'SafeTour.Auth',
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      developer.log(
        'ProfileStateNotifier: checkProfile aborted (no Firebase user)',
        name: 'SafeTour.Auth',
      );
      state = ProfileState.initial;
      return;
    }

    _isChecking = true;
    state = ProfileState.loading;
    developer.log(
      'PROFILE CHECK START',
      name: 'SafeTour.Auth',
    );

    try {
      final apiService = _ref.read(apiServiceProvider);

      // Get ID token to make sure it's valid before checking profile.
      final idToken = await user.getIdToken();
      developer.log(
        'ProfileStateNotifier: Firebase ID token fetched (length: ${idToken?.length ?? 0})',
        name: 'SafeTour.Auth',
      );

      final response = await apiService.dio.get('/api/users/me');
      developer.log(
        'PROFILE CHECK RESPONSE: ${response.statusCode}',
        name: 'SafeTour.Auth',
      );

      if (response.statusCode == 200) {
        developer.log(
          'PROFILE STATE -> exists',
          name: 'SafeTour.Auth',
        );
        state = ProfileState.exists;
      } else {
        developer.log(
          'PROFILE STATE -> error',
          name: 'SafeTour.Auth',
        );
        state = ProfileState.error;
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      developer.log(
        'PROFILE CHECK RESPONSE: $statusCode',
        name: 'SafeTour.Auth',
      );
      if (statusCode == 404) {
        developer.log(
          'PROFILE STATE -> needsOnboarding',
          name: 'SafeTour.Auth',
        );
        state = ProfileState.needsOnboarding;
      } else {
        developer.log(
          'PROFILE STATE -> error',
          name: 'SafeTour.Auth',
        );
        state = ProfileState.error;
      }
    } catch (e) {
      developer.log(
        'PROFILE CHECK RESPONSE: null',
        name: 'SafeTour.Auth',
      );
      developer.log(
        'PROFILE STATE -> error',
        name: 'SafeTour.Auth',
      );
      state = ProfileState.error;
    } finally {
      _isChecking = false;
    }
  }
}

final profileStateProvider =
    StateNotifierProvider<ProfileStateNotifier, ProfileState>((ref) {
  return ProfileStateNotifier(ref);
});

/// A ChangeNotifier that listens to both auth state and profile check status
/// to notify GoRouter when a refresh (redirect check) is required.
class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      developer.log(
          'RouterRefreshNotifier: Auth state changed, notifying router.',
          name: 'SafeTour.Router');
      notifyListeners();
    });
    ref.listen<ProfileState>(profileStateProvider, (previous, next) {
      developer.log(
          'RouterRefreshNotifier: Profile state changed to $next, notifying router.',
          name: 'SafeTour.Router');
      notifyListeners();
    });
  }
}

final routerRefreshProvider = Provider<RouterRefreshNotifier>((ref) {
  return RouterRefreshNotifier(ref);
});

class OnboardingState {
  final String name;
  final String? photoPath;
  final bool isLoading;
  final String? errorMessage;

  OnboardingState({
    required this.name,
    this.photoPath,
    required this.isLoading,
    this.errorMessage,
  });

  OnboardingState copyWith({
    String? name,
    String? photoPath,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OnboardingState(
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final Ref _ref;

  OnboardingNotifier(this._ref)
      : super(OnboardingState(name: '', isLoading: false));

  void updateName(String name) {
    state = state.copyWith(name: name, errorMessage: null);
  }

  void updatePhotoPath(String path) {
    state = state.copyWith(photoPath: path, errorMessage: null);
  }

  Future<bool> submitProfile() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final apiService = _ref.read(apiServiceProvider);
      final firebaseUser = FirebaseAuth.instance.currentUser;

      // Use picked photoPath (local file path) if set, otherwise fallback to firebase photoURL.
      final photoUrl = state.photoPath ?? firebaseUser?.photoURL;

      // Try PUT first. If 404 (user doesn't exist yet in backend DB), call POST.
      try {
        await apiService.dio.put('/api/users/me', data: {
          'name': state.name.trim(),
          'photo_url': photoUrl,
          'city': 'bangalore',
        });
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          await apiService.dio.post('/api/users/me', data: {
            'name': state.name.trim(),
            'photo_url': photoUrl,
            'city': 'bangalore',
          });
        } else {
          rethrow;
        }
      }

      // Successfully updated/created profile
      _ref.read(profileStateProvider.notifier).setExists();
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      String? errorMessage;
      final data = e.response?.data;
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String) {
          errorMessage = detail;
        } else if (detail is List) {
          errorMessage = detail.map((err) {
            if (err is Map) {
              return '${err['loc']?.last ?? 'field'}: ${err['msg'] ?? 'invalid value'}';
            }
            return err.toString();
          }).join(', ');
        } else {
          errorMessage = detail?.toString();
        }
      } else if (data is String && data.isNotEmpty) {
        errorMessage = data;
      }

      final message = errorMessage ?? 'Failed to save profile. Please try again.';
      state = state.copyWith(
        isLoading: false,
        errorMessage: message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }
}

final onboardingProvider =
    StateNotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>(
        (ref) {
  return OnboardingNotifier(ref);
});
