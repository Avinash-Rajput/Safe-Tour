// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_theme.dart';
import 'dart:async';
import 'dart:developer' as developer;

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
  late final List<FocusNode> _otpFocusNodes;
  
  bool _isOtpSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String _phoneNumber = "";
  String _searchQuery = "";
  String? _validationError;
  
  // Timestamps for performance measurement
  DateTime? _buttonPressTime;
  DateTime? _codeSentTime;
  
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
    _otpFocusNodes = List.generate(6, (index) {
      final node = FocusNode(
        debugLabel: 'otp_focus_$index',
        onKeyEvent: (node, event) {
          final isBackspace = event.logicalKey == LogicalKeyboardKey.backspace;
          final isDown = event is KeyDownEvent;
          
          if (isBackspace && isDown) {
            _log('Backspace action detected at index $index');
            final currentText = _otpControllers[index].text;
            if (currentText.isNotEmpty) {
              _log('Current field $index is not empty (val: $currentText). Clearing current digit.');
              setState(() {
                _otpControllers[index].clear();
              });
            } else {
              _log('Current field $index is empty. Moving focus to previous field.');
              if (index > 0) {
                final prevIndex = index - 1;
                _log('Clearing and focusing previous field at index $prevIndex.');
                setState(() {
                  _otpControllers[prevIndex].clear();
                });
                _safeRequestFocus(prevIndex);
              }
            }
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
      );
      node.addListener(() {
        _log('Focus changed for index $index: hasFocus = ${node.hasFocus}');
        setState(() {}); // Rebuild to update focus indicators visually
      });
      return node;
    });
  }

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    developer.log('SafeTourPhoneAuth [$timestamp]: $message');
  }

  void _safeRequestFocus(int index) {
    _log('Attempting safe focus request for index $index');
    if (!mounted) {
      _log('Focus request aborted: widget is not mounted.');
      return;
    }
    if (index < 0 || index >= _otpFocusNodes.length) {
      _log('Focus request aborted: index $index out of bounds.');
      return;
    }
    final node = _otpFocusNodes[index];
    if (node.context != null) {
      node.requestFocus();
      _log('Focus successfully requested for index $index synchronously.');
    } else {
      _log('Focus node context is null for index $index. Scheduling post-frame callback.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && node.context != null) {
          node.requestFocus();
          _log('Focus successfully requested for index $index asynchronously.');
        } else {
          _log('Failed to focus node at index $index: widget unmounted or context still null.');
        }
      });
    }
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

    final numberToCheck = _phoneController.text;
    if (!_validatePhoneNumber(numberToCheck, _selectedCountry)) {
      setState(() {
        _validationError = _getValidationErrorText(numberToCheck, _selectedCountry);
      });
      _showError('Invalid phone number format. Please check your input.');
      return;
    }
    
    _buttonPressTime = DateTime.now();
    _log('Send OTP button pressed');

    setState(() {
      _isLoading = true;
      _phoneNumber = '${_selectedCountry.dialingCode}${_phoneController.text}';
    });

    _log('verifyPhoneNumber started for phone: $_phoneNumber');

    try {
      ref.read(authServiceProvider).signInWithPhone(
        phoneNumber: _phoneNumber,
        verificationCompleted: (credential) async {
          _log('verificationCompleted callback triggered');
          try {
            await ref.read(authServiceProvider).verifyOTP(
              verificationId: _verificationId ?? "",
              smsCode: credential.smsCode ?? "",
            );
          } catch (_) {}
        },
        verificationFailed: (exception) {
          _log('verificationFailed callback triggered. Code: ${exception.code}, message: ${exception.message}');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            _showError(exception.message ?? 'Verification failed. Please try again.');
          }
        },
        codeSent: (verificationId, resendToken) {
          _codeSentTime = DateTime.now();
          final delayFromPress = _buttonPressTime != null 
              ? _codeSentTime!.difference(_buttonPressTime!).inMilliseconds 
              : null;
          _log('codeSent callback fired. Delay from button press: ${delayFromPress}ms. Verification ID: $verificationId');
          
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _isOtpSent = true;
              _isLoading = false; // Reset loading spinner instantly!
            });
            _log('OTP screen state changed (_isOtpSent = true)');
            
            _startTimer();
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final renderTime = DateTime.now();
                final delayFromSent = _codeSentTime != null
                    ? renderTime.difference(_codeSentTime!).inMilliseconds
                    : null;
                final totalDelay = _buttonPressTime != null
                    ? renderTime.difference(_buttonPressTime!).inMilliseconds
                    : null;
                _log('OTP UI rendered. Delay from codeSent: ${delayFromSent}ms. Total delay from button press: ${totalDelay}ms.');
                _safeRequestFocus(0);
              }
            });
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _log('codeAutoRetrievalTimeout callback triggered. Verification ID: $verificationId');
          _verificationId = verificationId;
        },
      ).catchError((e) {
        _log('verifyPhoneNumber asynchronous catch: $e');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          _showError(e.toString().replaceFirst('Exception: ', ''));
        }
      });
    } catch (e) {
      _log('verifyPhoneNumber synchronous catch: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError(e.toString().replaceFirst('Exception: ', ''));
      }
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showError(e.toString().replaceFirst('Exception: ', ''));
        for (var controller in _otpControllers) {
          controller.clear();
        }
        _safeRequestFocus(0);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              initialChildSize: 0.75,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(2.5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Country',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF121212),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.08),
                            ),
                          ),
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            onChanged: (val) {
                              setStateSheet(() {
                                _searchQuery = val;
                              });
                            },
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.4)),
                              hintText: 'Search country name or dialing code...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.white.withOpacity(0.03),
                            height: 1,
                            indent: 16,
                            endIndent: 16,
                          ),
                          itemBuilder: (context, index) {
                            final country = filtered[index];
                            final isSelected = country.isoCode == _selectedCountry.isoCode;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.03),
                                ),
                                child: Center(
                                  child: Text(
                                    _getCountryFlag(country.isoCode),
                                    style: const TextStyle(fontSize: 22),
                                  ),
                                ),
                              ),
                              title: Text(
                                country.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    country.dialingCode,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 14),
                                    const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                                  ],
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedCountry = country;
                                  _searchQuery = "";
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
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Safe ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Tour',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.2,
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_rounded, size: 18, color: Colors.white),
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
        ),
      ),
      body: Stack(
        children: [
          // Glowing radial canvas
          const Positioned.fill(
            child: GlowingBackground(),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _isOtpSent ? _buildOtpState() : _buildPhoneState(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneState() {
    return Column(
      key: const ValueKey("phoneState"),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        
        // Premium Title
        Row(
          children: [
            const Text(
              'Verify ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Number',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Premium Subtitle
        Text(
          "We'll send you a 6-digit one-time code to authenticate your secure travel profile.",
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.55),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 40),
        
        // Searchable Country Dial Code Dropdown + Phone Input Field Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isPhoneValid 
                  ? AppTheme.primary 
                  : (_validationError != null ? AppTheme.danger : Colors.white.withOpacity(_phoneController.text.isEmpty ? 0.06 : 0.2)),
              width: 1.5,
            ),
            boxShadow: [
              if (_isPhoneValid)
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.08),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
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
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 24,
                width: 1.2,
                color: Colors.white.withOpacity(0.08),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter phone number',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 16, letterSpacing: 0.0),
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
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 14),
                const SizedBox(width: 6),
                Text(
                  _validationError!,
                  style: const TextStyle(
                    color: AppTheme.danger,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const Spacer(),
        
        // Tactile send button
        TactileButton(
          onTap: (_isPhoneValid && !_isLoading) ? _sendOtp : null,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: (_isPhoneValid && !_isLoading)
                  ? const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: (!_isPhoneValid || _isLoading)
                  ? AppTheme.primary.withOpacity(0.15)
                  : null,
              boxShadow: [
                if (_isPhoneValid && !_isLoading)
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Send OTP',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: (_isPhoneValid && !_isLoading) ? Colors.white : Colors.white.withOpacity(0.35),
                      ),
                    ),
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
        const SizedBox(height: 24),
        
        // Title
        Row(
          children: [
            const Text(
              'Enter ',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w300,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Code',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Code description
        Row(
          children: [
            Text(
              'Code sent to ',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
            Text(
              _phoneNumber,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        
        // Premium 6-digit boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            final isFocused = _otpFocusNodes[index].hasFocus;
            final isNotEmpty = _otpControllers[index].text.isNotEmpty;
            return SizedBox(
              width: 48,
              height: 56,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                decoration: BoxDecoration(
                  color: isFocused ? const Color(0xFF252525) : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isFocused 
                        ? AppTheme.primary 
                        : (isNotEmpty ? Colors.white.withOpacity(0.3) : Colors.white.withOpacity(0.08)),
                    width: isFocused ? 2.0 : 1.2,
                  ),
                  boxShadow: [
                    if (isFocused)
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.12),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                  ],
                ),
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
                    _log('Digit entered at index $index: "$value"');
                    if (value.isNotEmpty) {
                      if (index < 5) {
                        _log('Auto-advancing focus from $index to ${index + 1}');
                        _safeRequestFocus(index + 1);
                      } else {
                        _log('6th digit entered. Unfocusing and verifying OTP.');
                        if (mounted) {
                          _otpFocusNodes[index].unfocus();
                        }
                        _verifyOtp();
                      }
                    }
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    counterText: '',
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 36),
        
        // Resend section
        Center(
          child: _timerSeconds > 0
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_rounded, 
                      color: Colors.white.withOpacity(0.4), 
                      size: 16
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Resend in $_timerSeconds seconds',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                )
              : TextButton.icon(
                  onPressed: _isLoading ? null : _sendOtp,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                  ),
                ),
        ),
        
        const Spacer(),
        
        // Tactile verify button
        TactileButton(
          onTap: (!_isLoading && _otpControllers.every((c) => c.text.isNotEmpty)) 
              ? _verifyOtp 
              : null,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: (!_isLoading && _otpControllers.every((c) => c.text.isNotEmpty))
                  ? const LinearGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: (_isLoading || !_otpControllers.every((c) => c.text.isNotEmpty))
                  ? AppTheme.primary.withOpacity(0.15)
                  : null,
              boxShadow: [
                if (!_isLoading && _otpControllers.every((c) => c.text.isNotEmpty))
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Center(
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Verify & Proceed',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold,
                        color: (!_isLoading && _otpControllers.every((c) => c.text.isNotEmpty)) 
                            ? Colors.white 
                            : Colors.white.withOpacity(0.35),
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class GlowingBackground extends StatelessWidget {
  const GlowingBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(color: AppTheme.background),
        ),
        // Subtle top glowing element
        Positioned(
          top: -200,
          left: MediaQuery.of(context).size.width / 4,
          width: MediaQuery.of(context).size.width / 2,
          height: 350,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.06),
                  blurRadius: 80,
                  spreadRadius: 40,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TactileButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;

  const TactileButton({super.key, this.onTap, required this.child});

  @override
  State<TactileButton> createState() => _TactileButtonState();
}

class _TactileButtonState extends State<TactileButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) {
          setState(() {
            _scale = 0.96;
          });
        }
      },
      onTapUp: (_) {
        if (widget.onTap != null) {
          setState(() {
            _scale = 1.0;
          });
        }
      },
      onTapCancel: () {
        if (widget.onTap != null) {
          setState(() {
            _scale = 1.0;
          });
        }
      },
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
