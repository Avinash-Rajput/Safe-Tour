// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen1 extends ConsumerStatefulWidget {
  const OnboardingScreen1({super.key});

  @override
  ConsumerState<OnboardingScreen1> createState() => _OnboardingScreen1State();
}

class _OnboardingScreen1State extends ConsumerState<OnboardingScreen1> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        ref.read(onboardingProvider.notifier).updatePhotoPath(image.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  String _getInitials(String name, String? firebaseDisplayName) {
    final targetName = name.trim().isNotEmpty
        ? name.trim()
        : (firebaseDisplayName?.trim() ?? '');
    if (targetName.isEmpty) return '';
    final parts = targetName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  Widget _buildAvatarContent(OnboardingState state, User? firebaseUser) {
    if (state.photoPath != null) {
      return Image.file(
        File(state.photoPath!),
        fit: BoxFit.cover,
        width: 96,
        height: 96,
      );
    }

    final firebasePhotoUrl = firebaseUser?.photoURL;
    if (firebasePhotoUrl != null && firebasePhotoUrl.isNotEmpty) {
      return Image.network(
        firebasePhotoUrl,
        fit: BoxFit.cover,
        width: 96,
        height: 96,
        errorBuilder: (context, error, stackTrace) =>
            _buildInitialsFallback(firebaseUser),
      );
    }

    return _buildInitialsFallback(firebaseUser);
  }

  Widget _buildInitialsFallback(User? firebaseUser) {
    final name = ref.watch(onboardingProvider).name;
    final initials = _getInitials(name, firebaseUser?.displayName);

    if (initials.isNotEmpty) {
      return Container(
        color: AppTheme.primary,
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      );
    }

    return const Icon(
      Icons.person,
      size: 48,
      color: AppTheme.textSecondary,
    );
  }

  Future<void> _handleContinue() async {
    final success = await ref.read(onboardingProvider.notifier).submitProfile();
    if (success && mounted) {
      context.go('/onboarding2');
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final name = onboardingState.name;

    // Validation rules: name must not be empty and must be at least 2 characters
    final isNameValid = name.trim().length >= 2;
    final isLoading = onboardingState.isLoading;

    // Show error text only after user has typed something
    final nameErrorText = (name.isNotEmpty && name.trim().length < 2)
        ? 'Name must be at least 2 characters'
        : null;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with back button and centered progress indicator
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => ref.read(authServiceProvider).signOut(),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.24),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 32),

                    // Title
                    const Text(
                      'Set up your profile',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'This helps your contacts identify you in an emergency',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Avatar Picker
                    Center(
                      child: GestureDetector(
                        onTap: isLoading ? null : _pickImage,
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withOpacity(0.1),
                                border: Border.all(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: ClipOval(
                                child: _buildAvatarContent(
                                  onboardingState,
                                  firebaseUser,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Name input
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      enabled: !isLoading,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Your full name',
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.4)),
                        filled: true,
                        fillColor: AppTheme.surface,
                        errorText: nameErrorText,
                        errorMaxLines: 2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.danger,
                            width: 1.5,
                          ),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.danger,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        ref.read(onboardingProvider.notifier).updateName(value);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Error display if api request fails
                    if (onboardingState.errorMessage != null) ...[
                      Center(
                        child: Text(
                          onboardingState.errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppTheme.danger,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Continue Button
                    ElevatedButton(
                      onPressed:
                          (isNameValid && !isLoading) ? _handleContinue : null,
                      style: ElevatedButton.styleFrom(
                        disabledBackgroundColor: Colors.white.withOpacity(0.12),
                        disabledForegroundColor: Colors.white.withOpacity(0.3),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Continue'),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
