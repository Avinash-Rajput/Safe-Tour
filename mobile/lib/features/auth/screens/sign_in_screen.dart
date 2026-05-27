// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final credential = await ref.read(authServiceProvider).signInWithGoogle();
      if (credential == null) {
        // Sign-in cancelled by user, stop loading without showing error
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      // On success, the GoRouter refreshListenable redirect will automatically
      // navigate to /home. We still check if mounted before updating state just in case.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Error message constraint: never expose technical details to user
        final errorMessage = e.toString().replaceFirst('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              
              // Glowing shield icon inside a green circle
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary.withOpacity(0.08),
                    border: Border.all(
                      color: AppTheme.primary.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, Color(0xFF388E3C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.shield,
                      size: 68,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Safe Tour title text with premium typography and spacing
              const Text(
                'Safe Tour',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Your Premium Security & Travel Companion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
              
              const Spacer(),
              
              // Loading Spinner or Button layer
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isLoading
                    ? const SizedBox(
                        height: 54,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            strokeWidth: 3,
                          ),
                        ),
                      )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PremiumInteractiveScale(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _handleGoogleSignIn,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      CustomPaint(
                                        size: const Size(20, 20),
                                        painter: GoogleGLogoPainter(),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Sign in with Google',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            PremiumInteractiveScale(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.15),
                                    width: 1.2,
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: () => context.push('/phone-signin'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(Icons.phone_android, size: 20, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text(
                                        'Sign in with Phone Number',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
              ),
              
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter to render an extremely precise and crisp vector Google 'G' logo
class GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width / 24;
    
    // Paint for Blue Segment (#4285F4)
    final Paint bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path bluePath = Path()
      ..moveTo(s * 22.56, s * 12.25)
      ..cubicTo(s * 22.56, s * 11.47, s * 22.49, s * 10.72, s * 22.36, s * 10.0)
      ..lineTo(s * 12.0, s * 10.0)
      ..lineTo(s * 12.0, s * 14.26)
      ..lineTo(s * 17.92, s * 14.26)
      ..cubicTo(s * 17.66, s * 15.63, s * 16.88, s * 16.79, s * 15.71, s * 17.57)
      ..lineTo(s * 15.71, s * 20.34)
      ..lineTo(s * 19.28, s * 20.34)
      ..cubicTo(s * 21.36, s * 18.42, s * 22.56, s * 15.6, s * 22.56, s * 12.25)
      ..close();
      
    canvas.drawPath(bluePath, bluePaint);

    // Paint for Green Segment (#34A853)
    final Paint greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path greenPath = Path()
      ..moveTo(s * 12.0, s * 23.0)
      ..cubicTo(s * 14.97, s * 23.0, s * 17.46, s * 22.02, s * 19.28, s * 20.34)
      ..lineTo(s * 15.71, s * 17.57)
      ..cubicTo(s * 14.73, s * 18.23, s * 13.48, s * 18.63, s * 12.0, s * 18.63)
      ..cubicTo(s * 9.14, s * 18.63, s * 6.71, s * 16.7, s * 5.84, s * 14.1)
      ..lineTo(s * 2.18, s * 14.1)
      ..lineTo(s * 2.18, s * 16.94)
      ..cubicTo(s * 3.99, s * 20.53, s * 7.7, s * 23.0, s * 12.0, s * 23.0)
      ..close();

    canvas.drawPath(greenPath, greenPaint);

    // Paint for Yellow Segment (#FBBC05)
    final Paint yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path yellowPath = Path()
      ..moveTo(s * 5.84, s * 14.09)
      ..cubicTo(s * 5.62, s * 13.43, s * 5.49, s * 12.73, s * 5.49, s * 12.0)
      ..cubicTo(s * 5.49, s * 11.27, s * 5.62, s * 10.57, s * 5.84, s * 9.91)
      ..lineTo(s * 5.84, s * 7.06)
      ..lineTo(s * 2.18, s * 7.06)
      ..cubicTo(s * 1.43, s * 8.55, s * 1.0, s * 10.22, s * 1.0, s * 12.0)
      ..cubicTo(s * 1.0, s * 13.78, s * 1.43, s * 15.45, s * 2.18, s * 16.94)
      ..lineTo(s * 5.03, s * 14.72)
      ..cubicTo(s * 4.81, s * 14.06, s * 4.68, s * 13.36, s * 4.68, s * 12.63)
      ..close();

    canvas.drawPath(yellowPath, yellowPaint);

    // Paint for Red Segment (#EA4335)
    final Paint redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path redPath = Path()
      ..moveTo(s * 12.0, s * 5.38)
      ..cubicTo(s * 13.62, s * 5.38, s * 15.06, s * 5.94, s * 16.21, s * 7.02)
      ..lineTo(s * 19.36, s * 3.87)
      ..cubicTo(s * 17.45, s * 2.09, s * 14.97, s * 1.0, s * 12.0, s * 1.0)
      ..cubicTo(s * 7.7, s * 1.0, s * 3.99, s * 3.47, s * 2.18, s * 7.06)
      ..lineTo(s * 5.84, s * 9.9)
      ..cubicTo(s * 6.71, s * 7.3, s * 9.14, s * 5.38, s * 12.0, s * 5.38)
      ..close();

    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A high-performance premium scale micro-animation on interaction
class PremiumInteractiveScale extends StatefulWidget {
  final Widget child;

  const PremiumInteractiveScale({super.key, required this.child});

  @override
  State<PremiumInteractiveScale> createState() => _PremiumInteractiveScaleState();
}

class _PremiumInteractiveScaleState extends State<PremiumInteractiveScale> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _isPressed = true),
      onPointerUp: (_) => setState(() => _isPressed = false),
      onPointerCancel: (_) => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
