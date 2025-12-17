import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _selectedUserType;
  bool _showPasswordReset = false;
  bool _showEmailVerification = false;

  final List<Map<String, dynamic>> _userTypes = [
    {
      'value': 'individual',
      'label': 'Individual',
      'description': 'Personal errands and tasks',
      'icon': Icons.person
    },
    {
      'value': 'business',
      'label': 'Business',
      'description': 'Commercial errands and services',
      'icon': Icons.business
    },
    {
      'value': 'runner',
      'label': 'Runner',
      'description': 'Complete errands for others',
      'icon': Icons.directions_run
    },
  ];

  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    // For sign-up, validate user type selection
    if (!_isLogin && _selectedUserType == null) {
      setState(() {
        _errorMessage = 'Please select an account type';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await SupabaseConfig.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // Sign up with complete user data
        final userData = {
          'full_name': _nameController.text.trim(),
          'user_type': _selectedUserType,
        };

        final response = await SupabaseConfig.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          userData,
        );

        // If sign-up successful, create complete user profile
        if (response.user != null) {
          await SupabaseConfig.createUserProfile({
            'id': response.user!.id,
            'email': _emailController.text.trim(),
            'full_name': _nameController.text.trim(),
            'phone': _phoneController.text.trim().isNotEmpty
                ? _phoneController.text.trim()
                : null,
            'user_type': _selectedUserType,
            'is_verified': false,
            'has_vehicle': false,
          });

          // Check if email verification is required
          if (response.user!.emailConfirmedAt == null) {
            setState(() {
              _showEmailVerification = true;
            });
          } else {
            // Show success message
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Account created successfully! Welcome to Lotto Runners.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onError),
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Clean up error message for better user experience
          String cleanError = e
              .toString()
              .replaceAll('Exception: ', '')
              .replaceAll('AuthException: ', '')
              .replaceAll('PostgrestException: ', '');

          // Provide user-friendly error messages
          if (cleanError.contains('EMAIL_SEND_FAILED')) {
            _errorMessage =
                'Unable to send confirmation email.\n\n'
                'This could be due to:\n'
                '• SMTP configuration issue\n'
                '• SMTP authentication failed\n'
                '• Email rate limits exceeded\n'
                '• Email template misconfiguration\n\n'
                'Please check your Supabase SMTP settings:\n'
                'Settings → Authentication → SMTP Settings';
          } else if (cleanError.contains('Invalid login credentials')) {
            _errorMessage =
                'Invalid email or password. Please check your credentials and try again.';
          } else if (cleanError.contains('Email not confirmed') ||
              cleanError.contains('email_not_confirmed')) {
            _errorMessage =
                'Please check your email and click the confirmation link before signing in.';
            setState(() {
              _showEmailVerification = true;
            });
          } else if (cleanError.contains('User already registered') ||
              cleanError.contains('already_registered')) {
            _errorMessage =
                'An account with this email already exists. Please sign in instead.';
          } else if (cleanError.contains('Password should be at least')) {
            _errorMessage = 'Password must be at least 6 characters long.';
          } else if (cleanError.contains('Unable to validate email address')) {
            _errorMessage = 'Please enter a valid email address.';
          } else if (cleanError.contains('Network') || cleanError.contains('NETWORK_ERROR')) {
            _errorMessage =
                'Network error. Please check your internet connection and try again.';
          } else if (cleanError.contains('rate_limit_exceeded') || cleanError.contains('RATE_LIMIT')) {
            _errorMessage =
                'Too many attempts. Please wait a moment before trying again.';
          } else if (cleanError.contains('email_address_invalid') || cleanError.contains('INVALID_EMAIL')) {
            _errorMessage = 'Please enter a valid email address.';
          } else {
            _errorMessage = cleanError.isNotEmpty
                ? cleanError
                : 'An unexpected error occurred. Please try again.';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _selectedUserType = null;
      _showPasswordReset = false;
      _showEmailVerification = false;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _handlePasswordReset() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseConfig.resetPasswordForEmail(_emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset email sent to ${_emailController.text.trim()}\n\nPlease check your inbox and spam folder.',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        setState(() {
          _showPasswordReset = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        
        // Handle specific error cases
        if (e.toString().contains('INVALID_EMAIL')) {
          errorMessage = 'The email address is invalid. Please enter a valid email address.';
        } else if (e.toString().contains('RATE_LIMIT')) {
          errorMessage = 'Too many attempts. Please wait a few minutes and try again.';
        } else if (e.toString().contains('EMAIL_SEND_FAILED')) {
          // Extract the detailed error message
          final match = RegExp(r'EMAIL_SEND_FAILED: (.+)').firstMatch(e.toString());
          errorMessage = match?.group(1) ?? 
              'Unable to send password reset email. Please check your Supabase SMTP settings or try again later.';
        } else if (e.toString().contains('NETWORK_ERROR')) {
          // Extract the network error message
          final match = RegExp(r'NETWORK_ERROR: (.+)').firstMatch(e.toString());
          errorMessage = match?.group(1) ?? 
              'Network error occurred. Please check your connection and try again.';
        } else if (e.toString().contains('AUTH_ERROR')) {
          // Extract the actual error message
          final match = RegExp(r'AUTH_ERROR: (.+)').firstMatch(e.toString());
          errorMessage = match?.group(1) ?? 'Failed to send password reset email. Please try again.';
        } else {
          errorMessage = 'Failed to send password reset email. Please check your email address and try again.';
        }
        
        setState(() {
          _errorMessage = errorMessage;
        });
        
        // Also show as a snackbar for better visibility
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendEmailConfirmation() async {
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await SupabaseConfig.resendEmailConfirmation(
          _emailController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Email confirmation resent to ${_emailController.text.trim()}',
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        
        // Handle specific error cases
        final errorString = e.toString();
        if (errorString.contains('EMAIL_SEND_FAILED')) {
          errorMessage =
              'Unable to send confirmation email.\n\n'
              'This could be due to:\n'
              '• SMTP configuration issue\n'
              '• SMTP authentication failed\n'
              '• Email rate limits exceeded\n'
              '• Email template misconfiguration\n\n'
              'Please check your Supabase SMTP settings:\n'
              'Settings → Authentication → SMTP Settings';
        } else if (errorString.contains('INVALID_EMAIL')) {
          errorMessage = 'The email address is invalid. Please enter a valid email address.';
        } else if (errorString.contains('RATE_LIMIT')) {
          errorMessage = 'Too many attempts. Please wait a few minutes and try again.';
        } else if (errorString.contains('AUTH_ERROR')) {
          // Extract the actual error message
          final match = RegExp(r'AUTH_ERROR: (.+)').firstMatch(errorString);
          errorMessage = match?.group(1) ?? 'Failed to resend email confirmation. Please try again.';
        } else if (errorString.contains('NETWORK_ERROR')) {
          errorMessage = 'Network error. Please check your internet connection and try again.';
        } else {
          errorMessage = 'Failed to resend email confirmation. Please try again.';
        }
        
        setState(() {
          _errorMessage = errorMessage;
        });
        
        // Also show as a snackbar for better visibility
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.onError),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              LottoRunnersColors.primaryBlue.withOpacity(0.12),
              LottoRunnersColors.gray50,
              LottoRunnersColors.primaryYellow.withOpacity(0.08),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isTablet = constraints.maxWidth > 768;
              final isMobile = constraints.maxWidth < 600;

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 32,
                    vertical: 32,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isTablet ? 440 : double.infinity,
                        ),
                        child: Card(
                          elevation: 20,
                          shadowColor:
                              LottoRunnersColors.primaryBlue.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Container(
                            padding: EdgeInsets.all(isMobile ? 24 : 32),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  LottoRunnersColors.gray50.withOpacity(0.5),
                                  LottoRunnersColors.primaryYellow
                                      .withOpacity(0.04),
                                ],
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildLogo(),
                                const SizedBox(height: 32),
                                _buildForm(),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 16),
                                  _buildErrorMessage(),
                                ],
                                const SizedBox(height: 24),
                                _buildSubmitButton(),
                                const SizedBox(height: 24),
                                if (_isLogin && !_showPasswordReset)
                                  _buildForgotPasswordLink(),
                                if (_showPasswordReset)
                                  _buildPasswordResetSection(),
                                if (_showEmailVerification)
                                  _buildEmailVerificationSection(),
                                const SizedBox(height: 16),
                                _buildToggleAuth(),
                                const SizedBox(height: 16),
                                _buildFooter(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'web/icons/lotto runners icon 92.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.directions_run,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lotto Runners',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                  ),
                  Text(
                    'Your Errands, Done fast',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                          letterSpacing: 0.5,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          _isLogin ? 'Welcome Back' : 'Create Account',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin
              ? 'Sign in to access your dashboard'
              : 'Join our professional platform',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LottoRunnersColors.gray600,
              ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (!_isLogin) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (!_isLogin) ...[
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number (Optional)',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^\+?[\d\s\-\(\)]{8,}$').hasMatch(value)) {
                    return 'Please enter a valid phone number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildUserTypeSelector(),
            const SizedBox(height: 16),
          ],
          _buildTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: LottoRunnersColors.gray600,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (!_isLogin && value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: LottoRunnersColors.primaryYellow),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: LottoRunnersColors.gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: LottoRunnersColors.gray200,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: LottoRunnersColors.primaryBlue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Type',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: LottoRunnersColors.gray700,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _selectedUserType == null
                  ? LottoRunnersColors.gray200
                  : LottoRunnersColors.primaryBlue,
              width: _selectedUserType == null ? 1 : 2,
            ),
            color: LottoRunnersColors.gray50,
          ),
          child: Column(
            children: _userTypes.map((userType) {
              final isSelected = _selectedUserType == userType['value'];
              return Container(
                margin: const EdgeInsets.all(4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedUserType = userType['value'];
                        _errorMessage = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected
                            ? LottoRunnersColors.primaryBlue.withOpacity(0.1)
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? LottoRunnersColors.primaryBlue
                              : Colors.transparent,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? LottoRunnersColors.primaryBlue
                                  : LottoRunnersColors.gray200,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              userType['icon'],
                              color: isSelected
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : LottoRunnersColors.gray600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userType['label'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? LottoRunnersColors.primaryBlue
                                            : LottoRunnersColors.gray700,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userType['description'],
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: LottoRunnersColors.gray600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: LottoRunnersColors.primaryBlue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: LottoRunnersColors.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 8,
          shadowColor: LottoRunnersColors.primaryBlue.withOpacity(0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isLogin ? 'Sign In' : 'Create Account',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
      ),
    );
  }

  Widget _buildToggleAuth() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : 'Already have an account? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: LottoRunnersColors.gray600,
              ),
        ),
        TextButton(
          onPressed: _toggleAuthMode,
          style: TextButton.styleFrom(
            foregroundColor: LottoRunnersColors.primaryBlue,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isLogin ? 'Sign Up' : 'Sign In',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: LottoRunnersColors.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPasswordLink() {
    return TextButton(
      onPressed: () {
        setState(() {
          _showPasswordReset = true;
          _errorMessage = null;
        });
      },
      style: TextButton.styleFrom(
        foregroundColor: LottoRunnersColors.primaryBlue,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Text(
        'Forgot your password?',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: LottoRunnersColors.primaryBlue,
              fontWeight: FontWeight.w500,
            ),
      ),
    );
  }

  Widget _buildPasswordResetSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LottoRunnersColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LottoRunnersColors.primaryBlue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_reset,
                color: LottoRunnersColors.primaryBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reset Password',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: LottoRunnersColors.primaryBlue,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your email address and we\'ll send you a link to reset your password.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LottoRunnersColors.gray600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handlePasswordReset,
              style: ElevatedButton.styleFrom(
                backgroundColor: LottoRunnersColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Send Reset Email'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _showPasswordReset = false;
                _errorMessage = null;
              });
            },
            style: TextButton.styleFrom(
              foregroundColor: LottoRunnersColors.gray600,
              padding: EdgeInsets.zero,
            ),
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerificationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LottoRunnersColors.primaryYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: LottoRunnersColors.primaryYellow.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.email_outlined,
                color: LottoRunnersColors.primaryYellow,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Email Verification Required',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: LottoRunnersColors.primaryYellow,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ve sent a verification email to ${_emailController.text.trim()}. Please check your inbox and click the verification link to activate your account.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: LottoRunnersColors.gray600,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResendEmailConfirmation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LottoRunnersColors.primaryYellow,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Resend Email'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showEmailVerification = false;
                      _isLogin = true;
                      _errorMessage = null;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: LottoRunnersColors.primaryBlue,
                    side:
                        const BorderSide(color: LottoRunnersColors.primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Sign In'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Text(
      'By continuing, you agree to our Terms of Service and Privacy Policy',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: LottoRunnersColors.gray400,
          ),
    );
  }
}
