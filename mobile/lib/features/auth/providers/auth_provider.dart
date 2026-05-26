import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Gets the current Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Signs in the user with Google.
  /// 
  /// Returns the [UserCredential] if successful, or `null` if the user aborted the flow.
  /// Throws a user-friendly exception on failure without technical jargon.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // User cancelled the sign-in flow
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e.code));
    } on PlatformException catch (e) {
      throw Exception(_mapGoogleSignInError(e.code));
    } catch (_) {
      throw Exception('Failed to sign in. Please try again.');
    }
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'invalid-credential':
        return 'Invalid sign-in credentials. Please try again.';
      case 'operation-not-allowed':
        return 'Google sign-in is currently unavailable. Please try again later.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Unable to sign in right now. Please try again.';
    }
  }

  String _mapGoogleSignInError(String code) {
    switch (code) {
      case 'network_error':
        return 'Network error. Please check your internet connection and try again.';
      case 'sign_in_failed':
        return 'Google sign-in failed. Please try again.';
      case 'sign_in_required':
        return 'Please choose a Google account to continue.';
      case 'sign_in_canceled':
        return 'Google sign-in was canceled.';
      default:
        return 'Unable to sign in with Google right now. Please try again.';
    }
  }

  /// Signs out the user from both Firebase and Google.
  /// 
  /// Throws a user-friendly exception on failure.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out. Please try again.');
    }
  }
}

/// Provider for the AuthService instance.
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// StreamProvider that tracks the authentication state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});
