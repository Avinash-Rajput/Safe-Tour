import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safetour/features/auth/screens/phone_signin_screen.dart';
import 'package:safetour/features/auth/providers/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FakeUserCredential implements UserCredential {
  @override
  final User? user = null;
  @override
  final AuthCredential? credential = null;
  @override
  final AdditionalUserInfo? additionalUserInfo = null;
}

class FakeAuthService implements AuthService {
  String? lastVerificationId;
  String? lastSmsCode;
  bool signInWithPhoneCalled = false;
  bool verifyOTPCalled = false;

  @override
  User? get currentUser => null;

  @override
  Future<UserCredential?> signInWithGoogle() async {
    return null;
  }

  @override
  Future<void> signInWithPhone({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) async {
    signInWithPhoneCalled = true;
    codeSent("test_verification_id", 12345);
  }

  @override
  Future<UserCredential> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    verifyOTPCalled = true;
    lastVerificationId = verificationId;
    lastSmsCode = smsCode;
    return FakeUserCredential();
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('OTP Verification Screen Flow and Keyboard Actions', (WidgetTester tester) async {
    final fakeAuth = FakeAuthService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authServiceProvider.overrideWithValue(fakeAuth),
        ],
        child: const MaterialApp(
          home: PhoneSignInScreen(),
        ),
      ),
    );

    // 1. Initial State: Enter phone number
    final phoneField = find.byType(TextField);
    expect(phoneField, findsOneWidget);

    await tester.enterText(phoneField, '9876543210');
    await tester.pumpAndSettle();

    // Tap Send OTP
    final sendButton = find.text('Send OTP');
    expect(sendButton, findsOneWidget);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    // 2. Transformed state: OTP inputs should be rendered
    expect(fakeAuth.signInWithPhoneCalled, isTrue);
    expect(find.text('Verification Code'), findsOneWidget);

    // Verify there are 6 TextField boxes
    final otpFields = find.byType(TextField);
    expect(otpFields, findsNWidgets(6));

    // Enter digits sequentially
    await tester.enterText(otpFields.at(0), '1');
    await tester.pumpAndSettle();

    await tester.enterText(otpFields.at(1), '2');
    await tester.pumpAndSettle();
    
    await tester.enterText(otpFields.at(2), '3');
    await tester.pumpAndSettle();
    
    await tester.enterText(otpFields.at(3), '4');
    await tester.pumpAndSettle();
    
    await tester.enterText(otpFields.at(4), '5');
    await tester.pumpAndSettle();
    
    // 6th field entry triggers verification
    await tester.enterText(otpFields.at(5), '6');
    await tester.pumpAndSettle();

    expect(fakeAuth.verifyOTPCalled, isTrue);
    expect(fakeAuth.lastSmsCode, '123456');
  });
}
