// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';

class Country {
  final String name;
  final String isoCode;
  final String dialingCode;
  final String? validationRegExp;
  final int maxLength;

  const Country({
    required this.name,
    required this.isoCode,
    required this.dialingCode,
    this.validationRegExp,
    required this.maxLength,
  });
}

// Rich list of international countries with explicit ITU-T E.164 length limits
const List<Country> countriesList = [
  Country(name: 'India', isoCode: 'IN', dialingCode: '+91', validationRegExp: r'^[6-9]\d{9}$', maxLength: 10),
  Country(name: 'United States', isoCode: 'US', dialingCode: '+1', validationRegExp: r'^\d{10}$', maxLength: 10),
  Country(name: 'United Kingdom', isoCode: 'GB', dialingCode: '+44', validationRegExp: r'^7\d{9}$', maxLength: 10),
  Country(name: 'Australia', isoCode: 'AU', dialingCode: '+61', validationRegExp: r'^4\d{8}$', maxLength: 9),
  Country(name: 'Germany', isoCode: 'DE', dialingCode: '+49', validationRegExp: r'^1[5-7]\d{8,9}$', maxLength: 11),
  Country(name: 'France', isoCode: 'FR', dialingCode: '+33', validationRegExp: r'^6\d{8}$', maxLength: 9),
  Country(name: 'Canada', isoCode: 'CA', dialingCode: '+1', validationRegExp: r'^\d{10}$', maxLength: 10),
  Country(name: 'Singapore', isoCode: 'SG', dialingCode: '+65', validationRegExp: r'^[89]\d{7}$', maxLength: 8),
  Country(name: 'Japan', isoCode: 'JP', dialingCode: '+81', validationRegExp: r'^[789]0\d{8}$', maxLength: 10),
  Country(name: 'United Arab Emirates', isoCode: 'AE', dialingCode: '+971', validationRegExp: r'^5[0256]\d{7}$', maxLength: 9),
  Country(name: 'Saudi Arabia', isoCode: 'SA', dialingCode: '+966', validationRegExp: r'^5\d{8}$', maxLength: 9),
  Country(name: 'South Africa', isoCode: 'ZA', dialingCode: '+27', validationRegExp: r'^[678]\d{8}$', maxLength: 9),
  Country(name: 'Brazil', isoCode: 'BR', dialingCode: '+55', validationRegExp: r'^[1-9]{2}9\d{8}$', maxLength: 11),
  Country(name: 'New Zealand', isoCode: 'NZ', dialingCode: '+64', validationRegExp: r'^2\d{7,9}$', maxLength: 10),
  Country(name: 'Netherlands', isoCode: 'NL', dialingCode: '+31', validationRegExp: r'^6\d{8}$', maxLength: 9),
  Country(name: 'Spain', isoCode: 'ES', dialingCode: '+34', validationRegExp: r'^[67]\d{8}$', maxLength: 9),
  Country(name: 'Italy', isoCode: 'IT', dialingCode: '+39', validationRegExp: r'^3\d{9}$', maxLength: 10),
  Country(name: 'Switzerland', isoCode: 'CH', dialingCode: '+41', validationRegExp: r'^7[5-9]\d{7}$', maxLength: 9),
  Country(name: 'Sweden', isoCode: 'SE', dialingCode: '+46', validationRegExp: r'^7[02369]\d{7}$', maxLength: 9),
  Country(name: 'Norway', isoCode: 'NO', dialingCode: '+47', validationRegExp: r'^[49]\d{7}$', maxLength: 8),
  Country(name: 'Denmark', isoCode: 'DK', dialingCode: '+45', validationRegExp: r'^[2-9]\d{7}$', maxLength: 8),
  Country(name: 'Finland', isoCode: 'FI', dialingCode: '+358', validationRegExp: r'^(457|4[0-9]|50)\d{6,7}$', maxLength: 10),
  Country(name: 'Ireland', isoCode: 'IE', dialingCode: '+353', validationRegExp: r'^8[3-9]\d{7}$', maxLength: 9),
];

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
  String _searchQuery = "";
  String? _validationError;
  
  // Default country = India (+91)
  Country _selectedCountry = countriesList[0];
  
  // Resend Timer
  Timer? _timer;
  int _timerSeconds = 60;
  bool _isPhoneValid = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _log(String message) {
    developer.log('SafeTourPhoneAuth: $message');
  }

  void _onPhoneChanged() {
    final text = _phoneController.text;
    if (text.isEmpty) {
      setState(() {
        _isPhoneValid = false;
        _validationError = null;
      });
      return;
    }

    final valid = _validatePhoneNumber(text, _selectedCountry);
    setState(() {
      _isPhoneValid = valid;
      if (valid) {
        _validationError = null;
      } else {
        _validationError = _getValidationErrorText(text, _selectedCountry);
      }
    });
  }

  bool _validatePhoneNumber(String phoneNumber, Country country) {
    if (phoneNumber.isEmpty) return false;
    
    // Check digits only
    final digitsOnly = RegExp(r'^\d+$');
    if (!digitsOnly.hasMatch(phoneNumber)) return false;

    if (country.validationRegExp != null) {
      return RegExp(country.validationRegExp!).hasMatch(phoneNumber);
    } else {
      // Fallback E.164 requirements
      return phoneNumber.length >= 6 && phoneNumber.length <= 15;
    }
  }

  String _getValidationErrorText(String text, Country country) {
    if (text.length < 6) {
      return 'Phone number must be at least 6 digits';
    }
    if (country.validationRegExp != null) {
      return 'Invalid number format for ${country.name} (must be exactly ${country.maxLength} digits)';
    }
    return 'Invalid phone number';
  }

  String _getCountryFlag(String countryCode) {
    final int firstLetter = countryCode.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int secondLetter = countryCode.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(firstLetter) + String.fromCharCode(secondLetter);
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
    if (_isLoading) {
      _log('Prevented duplicate Send OTP click: request is already running.');
      return;
    }

    // Double-check validations before dispatch
    final numberToCheck = _phoneController.text;
    if (!_validatePhoneNumber(numberToCheck, _selectedCountry)) {
      setState(() {
        _validationError = _getValidationErrorText(numberToCheck, _selectedCountry);
      });
      _showError('Invalid phone number format. Please check your input.');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _phoneNumber = '${_selectedCountry.dialingCode}${_phoneController.text}';
    });

    _log('Initiating verifyPhoneNumber for number: $_phoneNumber');

    try {
      await ref.read(authServiceProvider).signInWithPhone(
        phoneNumber: _phoneNumber,
        verificationCompleted: (credential) async {
          _log('verificationCompleted callback triggered. Auto-signed in.');
          try {
            await ref.read(authServiceProvider).verifyOTP(
              verificationId: _verificationId ?? "",
              smsCode: credential.smsCode ?? "",
            );
          } catch (_) {}
        },
        verificationFailed: (exception) {
          _log('verificationFailed callback triggered. Code: ${exception.code}, message: ${exception.message}');
          setState(() {
            _isLoading = false;
          });
          _showError(exception.message ?? 'Verification failed. Please try again.');
        },
        codeSent: (verificationId, resendToken) {
          _log('codeSent callback triggered. Verification ID: $verificationId. Transitioning immediately.');
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false; // Reset loading spinner instantly!
          });
          _startTimer();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _otpFocusNodes[0].requestFocus();
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _log('codeAutoRetrievalTimeout callback triggered. Verification ID: $verificationId');
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _log('verifyPhoneNumber synchronous catch: $e');
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
      
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError(e.toString().replaceFirst('Exception: ', ''));
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

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final query = _searchQuery.toLowerCase();
            final filtered = countriesList.where((c) {
              return c.name.toLowerCase().contains(query) ||
                     c.isoCode.toLowerCase().contains(query) ||
                     c.dialingCode.contains(query);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Country',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            onChanged: (val) {
                              setStateSheet(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                              hintText: 'Search country name or code...',
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final country = filtered[index];
                            final isSelected = country.isoCode == _selectedCountry.isoCode;
                            return ListTile(
                              leading: Text(
                                _getCountryFlag(country.isoCode),
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                country.name,
                                style: const TextStyle(color: Colors.white),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    country.dialingCode,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 12),
                                    const Icon(Icons.check, color: AppTheme.primary),
                                  ],
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedCountry = country;
                                  _searchQuery = "";
                                  // Safely truncate existing inputs to match the new country's maximum digits constraint
                                  if (_phoneController.text.length > country.maxLength) {
                                    _phoneController.text = _phoneController.text.substring(0, country.maxLength);
                                  }
                                });
                                _onPhoneChanged();
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
        
        // Searchable Country Dial Code Dropdown + Phone Input Field
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isPhoneValid 
                  ? AppTheme.primary 
                  : (_validationError != null ? AppTheme.danger : Colors.white.withOpacity(_phoneController.text.isEmpty ? 0.1 : 0.3)),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _showCountryPicker,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Text(
                      _getCountryFlag(_selectedCountry.isoCode),
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _selectedCountry.dialingCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                    LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
                  ],
                  decoration: const InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                    border: InputBorder.none,
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Active visual validation feedback
        if (_validationError != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              _validationError!,
              style: const TextStyle(
                color: AppTheme.danger,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        
        const Spacer(),
        
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
        
        // 6 digit boxes with KeyboardListener backspace support
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 48,
              height: 56,
              child: KeyboardListener(
                focusNode: _otpFocusNodes[index],
                onKeyEvent: (event) {
                  final isBackspace = event.logicalKey == LogicalKeyboardKey.backspace;
                  if (isBackspace && (event is KeyDownEvent || event.runtimeType.toString().contains('KeyDown'))) {
                    if (_otpControllers[index].text.isNotEmpty) {
                      _otpControllers[index].clear();
                    } else {
                      if (index > 0) {
                        _otpFocusNodes[index - 1].requestFocus();
                        _otpControllers[index - 1].clear();
                      }
                    }
                  }
                },
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
              ),
            );
          }),
        ),
        const SizedBox(height: 32),
        
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
