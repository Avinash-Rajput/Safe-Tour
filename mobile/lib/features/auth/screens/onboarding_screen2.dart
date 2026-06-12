import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingScreen2 extends StatelessWidget {
  const OnboardingScreen2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Onboarding Step 2'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          'Step 2: Emergency Contacts Placeholder',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
