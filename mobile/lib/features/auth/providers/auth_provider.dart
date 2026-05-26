import 'package:firebase_auth/firebase_auth.dart';
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
    } catch (e) {
      // Do not expose e.toString() directly to avoid showing technical details
      throw Exception('Failed to sign in. Please verify your internet connection and try again.');
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
