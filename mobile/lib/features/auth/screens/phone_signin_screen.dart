// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class PhoneSignInScreen extends ConsumerStatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  ConsumerState<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends ConsumerState<PhoneSignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String _phoneNumber = "";
  
  // Resend Timer
  Timer? _timer;
  int _timerSeconds = 60;
  
  // RegEx for Indian mobile number (without prefix): starting with 6-9 and exactly 10 digits
  final RegExp _phoneRegExp = RegExp(r'^[6-9]\d{9}$');
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final valid = _phoneRegExp.hasMatch(_phoneController.text);
    if (valid != _isPhoneValid) {
      setState(() {
        _isPhoneValid = valid;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timerSeconds = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _timerSeconds--;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    if (!_isPhoneValid) return;
    
    setState(() {
      _isLoading = true;
      _phoneNumber = '+91${_phoneController.text}';
    });

    try {
      await ref.read(authServiceProvider).signInWithPhone(
        phoneNumber: _phoneNumber,
        verificationCompleted: (credential) async {
          // Auto-retrieval completed, sign in
          try {
            await ref.read(authServiceProvider).verifyOTP(
              verificationId: _verificationId ?? "",
              smsCode: credential.smsCode ?? "",
            );
          } catch (_) {
            // Ignore auto-retrieval failure here
          }
        },
        verificationFailed: (exception) {
          setState(() {
            _isLoading = false;
          });
          _showError(exception.message ?? 'Verification failed. Please try again.');
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
          _startTimer();
          // Focus first OTP field
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _otpFocusNodes[0].requestFocus();
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6 || _verificationId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authServiceProvider).verifyOTP(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      // On success, navigate to /home
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError(e.toString().replaceFirst('Exception: ', ''));
      // Clear OTP inputs on failure
      for (var controller in _otpControllers) {
        controller.clear();
      }
      _otpFocusNodes[0].requestFocus();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _timer?.cancel();
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (_isOtpSent) {
              setState(() {
                _isOtpSent = false;
                _verificationId = null;
                // Clear controllers
                for (var controller in _otpControllers) {
                  controller.clear();
                }
              });
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _isOtpSent ? _buildOtpState() : _buildPhoneState(),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneState() {
    return Column(
      key: const ValueKey("phoneState"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Verify your number',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'We will send you a one-time verification code.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 40),
        
        // Input with prefix +91
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isPhoneValid 
                  ? AppTheme.primary 
                  : Colors.white.withOpacity(_phoneController.text.isEmpty ? 0.1 : 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              const Text(
                '+91',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 24,
                width: 1,
                color: Colors.white.withOpacity(0.2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Enter 10-digit number',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        
        // Submit button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (_isPhoneValid && !_isLoading) ? _sendOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primary.withOpacity(0.3),
              disabledForegroundColor: Colors.white.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Send OTP',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildOtpState() {
    return Column(
      key: const ValueKey("otpState"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Code sent to ',
              style: TextStyle(
                fontSize: 15,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            Text(
              _phoneNumber,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        
        // 6 digits boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 56,
              child: TextField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(1),
                ],
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    if (index < 5) {
                      _otpFocusNodes[index + 1].requestFocus();
                    } else {
                      _otpFocusNodes[index].unfocus();
                      _verifyOtp();
                    }
                  } else {
                    if (index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                  }
                },
                decoration: InputDecoration(
                  fillColor: AppTheme.surface,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        
        // Countdown resend timer
        Center(
          child: _timerSeconds > 0
              ? Text(
                  'Resend OTP in $_timerSeconds seconds',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.5),
                  ),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _sendOtp,
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
        ),
        
        const Spacer(),
        
        // Manual verification button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (!_isLoading && _otpControllers.every((c) => c.text.isNotEmpty)) 
                ? _verifyOtp 
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.primary.withOpacity(0.3),
              disabledForegroundColor: Colors.white.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verify',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
