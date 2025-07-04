import 'package:flutter/material.dart';
import 'package:lotto_runners/theme.dart';
import 'package:lotto_runners/supabase/supabase_config.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'individual';
  bool _hasVehicle = false;

  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animationController, curve: Curves.easeOutCubic));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _cardAnimationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _cardAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              LottoRunnersColors.gray50,
              LottoRunnersColors.gray100,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width > 600 ? size.width * 0.25 : 24.0,
                  vertical: 40.0,
                ),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildAuthCard(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: LottoRunnersColors.primaryBlue.withOpacity(0.05),
            blurRadius: 60,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildCardHeader(),
              const SizedBox(height: 32),
              _buildFormFields(),
              const SizedBox(height: 32),
              _buildActionButton(),
              const SizedBox(height: 32),
              _buildToggleSection(),
              const SizedBox(height: 24),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeader() {
    return Column(
      children: [
        // Icon
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            _isLogin ? Icons.login : Icons.person_add,
            size: 28,
            color: LottoRunnersColors.primaryBlue,
          ),
        ),

        const SizedBox(height: 20),

        // Title
        Text(
          _isLogin ? 'Sign in with email' : 'Create your account',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: LottoRunnersColors.gray900,
            height: 1.2,
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          _isLogin
              ? 'Welcome back! Please enter your details.'
              : 'Join our community and start running errands.',
          style: TextStyle(
            fontSize: 15,
            color: LottoRunnersColors.gray600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Email Field
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Enter your email address',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),

        const SizedBox(height: 20),

        // Password Field
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Enter your password',
          icon: Icons.lock_outlined,
          obscureText: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: LottoRunnersColors.gray400,
              size: 20,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Password is required';
            if (value.length < 6)
              return 'Password must be at least 6 characters';
            return null;
          },
        ),

        // Forgot Password (only for login)
        if (_isLogin) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                // TODO: Implement forgot password
              },
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: LottoRunnersColors.primaryBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],

        // Sign up specific fields
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState:
              _isLogin ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: const SizedBox.shrink(),
          secondChild: Column(
            children: [
              const SizedBox(height: 20),
              _buildTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'Enter your full name',
                icon: Icons.person_outlined,
                validator: (value) {
                  if (!_isLogin && (value == null || value.isEmpty)) {
                    return 'Full name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: 'Enter your phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (!_isLogin && (value == null || value.isEmpty)) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              _buildRoleSelection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: LottoRunnersColors.gray900,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: LottoRunnersColors.gray400, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: LottoRunnersColors.gray50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: LottoRunnersColors.gray200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: LottoRunnersColors.gray200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: LottoRunnersColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(
          color: LottoRunnersColors.gray600,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: LottoRunnersColors.gray400,
          fontSize: 14,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _buildRoleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What describes you best?',
          style: TextStyle(
            color: LottoRunnersColors.gray900,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildRoleChip('individual', 'Individual', Icons.person),
            _buildRoleChip('business', 'Business', Icons.business),
            _buildRoleChip('runner', 'Runner', Icons.directions_run),
          ],
        ),

        // Vehicle option for runners
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 300),
          crossFadeState: _selectedRole == 'runner'
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: LottoRunnersColors.primaryBlue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: LottoRunnersColors.primaryBlue.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_car,
                  color: LottoRunnersColors.primaryBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'I have a vehicle',
                    style: TextStyle(
                      color: LottoRunnersColors.gray700,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: _hasVehicle,
                  onChanged: (value) => setState(() => _hasVehicle = value),
                  activeColor: LottoRunnersColors.primaryBlue,
                  activeTrackColor:
                      LottoRunnersColors.primaryBlue.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleChip(String value, String label, IconData icon) {
    final isSelected = _selectedRole == value;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: () => setState(() {
          _selectedRole = value;
          if (value != 'runner') _hasVehicle = false;
        }),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? LottoRunnersColors.primaryBlue
                : LottoRunnersColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? LottoRunnersColors.primaryBlue
                  : LottoRunnersColors.gray200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : LottoRunnersColors.gray600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : LottoRunnersColors.gray600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: LottoRunnersColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _isLogin ? 'Get Started' : 'Create Account',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? "Don't have an account? " : "Already have an account? ",
          style: TextStyle(
            color: LottoRunnersColors.gray600,
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isLogin = !_isLogin;
              _formKey.currentState?.reset();
            });
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            _isLogin ? 'Sign up' : 'Sign in',
            style: TextStyle(
              color: LottoRunnersColors.primaryBlue,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'By continuing, you agree to our Terms of Service and Privacy Policy',
        style: TextStyle(
          color: LottoRunnersColors.gray600,
          fontSize: 12,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await SupabaseConfig.signInWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        final response = await SupabaseConfig.signUpWithEmail(
          _emailController.text.trim(),
          _passwordController.text,
          {
            'full_name': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'user_type': _selectedRole,
          },
        );

        if (response.user != null) {
          await SupabaseConfig.createUserProfile({
            'id': response.user!.id,
            'email': _emailController.text.trim(),
            'full_name': _fullNameController.text.trim(),
            'phone': _phoneController.text.trim(),
            'user_type': _selectedRole,
            'has_vehicle': _hasVehicle,
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  _isLogin ? 'Welcome back!' : 'Account created successfully!',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: LottoRunnersColors.accent,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isLogin
                        ? 'Sign in failed. Please check your credentials.'
                        : 'Sign up failed. Please try again.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
