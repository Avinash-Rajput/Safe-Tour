import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safetour/features/auth/screens/sign_in_screen.dart';

void main() {
  testWidgets('Sign-in screen shows Google sign-in button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SignInScreen()),
      ),
    );

    expect(find.text('Sign in with Google'), findsOneWidget);
  });
}
