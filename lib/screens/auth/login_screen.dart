import 'package:flutter/material.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'dart:math' as math;

class _Strings {
  static const String alreadyClient = 'Déjà Client ?';
  static const String loginToEnjoy =
      'Connectez-vous pour profiter d\'une expérience\npersonnalisée';
  static const String emailHint = 'Email';
  static const String passwordHint = 'Mot de passe';
  static const String forgotPassword = 'Mot de passe oublié?';
  static const String login = 'Connexion';
  static const String noAccount = 'Pas encore de compte? ';
  static const String signUp = 'Inscription';
  static const String emailRequired = 'Veuillez saisir votre email';
  static const String invalidEmailFormat = 'Format d\'email invalide';
  static const String passwordRequired = 'Veuillez saisir votre mot de passe';
  static const String passwordTooShort =
      'Le mot de passe doit contenir au moins 6 caractères';
}

class _Dimens {
  static const double horizontalPadding = 24.0;
  static const double verticalPadding = 16.0;
  static const double buttonHeight = 56.0;
  static const double buttonRadius = 100.0;
  static const double textFieldRadius = 12.0;
  static const double iconSize = 24.0;
  static const double backButtonSize = 32.0;
  static const double backButtonIconSize = 20.0;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!_validateAndShowError(email, password)) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.login(email, password);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result['message'])));

      if (result['success']) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  bool _validateAndShowError(String email, String password) {
    if (email.isEmpty) {
      _showError(_Strings.emailRequired);
      return false;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError(_Strings.invalidEmailFormat);
      return false;
    }
    if (password.isEmpty) {
      _showError(_Strings.passwordRequired);
      return false;
    }
    if (password.length < 6) {
      _showError(_Strings.passwordTooShort);
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: _Dimens.horizontalPadding),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _buildLoginForm(),
                    const SizedBox(height: 24),
                    _buildSignUp(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(
            minHeight: 280,
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: Image.asset(
            "assets/images/Group 1bg.png",
            fit: BoxFit.cover,
          ),
        ),
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Container(
                  width: _Dimens.backButtonSize,
                  height: _Dimens.backButtonSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF6F6F6),
                    border: Border.all(
                      color: const Color(0xFFE4E4E4),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(
                      Icons.chevron_left,
                      size: _Dimens.backButtonIconSize,
                      color: Colors.black,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Column(
                  children: [
                    Image.asset(
                      "assets/images/Group 2.png",
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.width * 0.15,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _Strings.alreadyClient,
                      style: TextStyle(
                        fontSize: math
                            .min(
                              MediaQuery.of(context).size.width * 0.06,
                              24.0,
                            )
                            .clamp(16.0, 24.0),
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      _Strings.loginToEnjoy,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextField(
          controller: _emailController,
          decoration: _buildInputDecoration(
            hintText: _Strings.emailHint,
            prefixIcon: Icons.email_outlined,
          ),
        ),
        const SizedBox(height: _Dimens.verticalPadding),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: _buildInputDecoration(
            hintText: _Strings.passwordHint,
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey[400],
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(context, '/forgot_password');
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6C63FF),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text(
              _Strings.forgotPassword,
              style: TextStyle(fontSize: 14, fontFamily: 'Poppins'),
            ),
          ),
        ),
        const SizedBox(height: _Dimens.verticalPadding),
        SizedBox(
          width: double.infinity,
          height: _Dimens.buttonHeight,
          child: ElevatedButton(
            onPressed: _isLoading ? null : loginUser,
            style: ElevatedButton.styleFrom(
              backgroundColor: FigmaColors.primaryMain,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_Dimens.buttonRadius),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                : const Text(
                    _Strings.login,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          _Strings.noAccount,
          style: TextStyle(
            color: Color(0xFF666666),
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, '/sign_up');
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: const Color(0xFF6C63FF),
          ),
          child: const Text(
            _Strings.signUp,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(
      {required String hintText,
      required IconData prefixIcon,
      Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 16,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: Colors.grey[400],
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_Dimens.textFieldRadius),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_Dimens.textFieldRadius),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_Dimens.textFieldRadius),
        borderSide: const BorderSide(
          color: Color(0xFF6C63FF),
        ),
      ),
    );
  }
}