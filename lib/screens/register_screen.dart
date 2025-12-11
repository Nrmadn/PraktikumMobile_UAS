import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:targetibadah_gamifikasi/services/firebase/firebase_auth_service.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  bool isLoading = false;
  bool agreeToTerms = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    // Setup animation - ENHANCED
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
          parent: _animController,
          curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return emptyNameError;
    }
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    return null;
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return emptyEmailError;
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return invalidEmailError;
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return emptyPasswordError;
    }
    if (value.length < 6) {
      return passwordTooShortError;
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    if (value != passwordController.text) {
      return passwordMismatchError;
    }
    return null;
  }

  void handleRegister() async {
    if (_formKey.currentState!.validate()) {
      if (!agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Anda harus menyetujui Syarat & Ketentuan',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: warningColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }

      setState(() {
        isLoading = true;
      });

      try {
        // ✅ GUNAKAN FIREBASE AUTH SERVICE
        final emailExists = await FirebaseAuthService.isEmailExists(
          emailController.text.trim(),
        );

        if (emailExists) {
          if (mounted) {
            setState(() {
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: const [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Email sudah terdaftar! Silakan gunakan email lain atau login.',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                backgroundColor: errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }

        // ✅ REGISTER USER
        final user = await FirebaseAuthService.register(
          name: nameController.text.trim(),
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        if (mounted) {
          setState(() {
            isLoading = false;
          });

          if (user != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pendaftaran berhasil! Silakan login dengan akun Anda.',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: successColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 3),
              ),
            );

            Navigator.pushReplacementNamed(context, '/login');
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Pendaftaran gagal. Silakan coba lagi.'),
                  ],
                ),
                backgroundColor: errorColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Terjadi kesalahan: $e',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor.withOpacity(0.1),
              backgroundColor,
              primaryColorDark.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: screenHeight -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: paddingLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: paddingLarge),

                        //  HEADER - FIXED
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              children: [
                                // Logo Container - Simpler & Cleaner
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [primaryColor, primaryColorDark],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.5),
                                        blurRadius: 25,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_add_outlined,
                                    color: textColorWhite,
                                    size: 50,
                                  ),
                                ),

                                const SizedBox(height: paddingLarge),

                                // Title with gradient
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [primaryColor, primaryColorDark],
                                  ).createShader(bounds),
                                  child: const Text(
                                    registerTitle,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: textColorWhite,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: paddingSmall),

                                const Text(
                                  'Bergabunglah dengan komunitas ibadah ✨',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: textColorLight,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: paddingLarge + 8),

                        // INPUT FIELDS WITH ANIMATION
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                // FULL NAME
                                CustomTextField(
                                  label: registerFullName,
                                  hint: 'contoh: Ahmad Fauzi',
                                  controller: nameController,
                                  keyboardType: TextInputType.name,
                                  prefixIcon: Icons.person_outline,
                                  validator: validateName,
                                ),

                                const SizedBox(height: paddingMedium),

                                //  EMAIL
                                CustomTextField(
                                  label: registerEmail,
                                  hint: 'contoh@email.com',
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  validator: validateEmail,
                                ),

                                const SizedBox(height: paddingMedium),

                                // PASSWORD
                                CustomTextField(
                                  label: registerPassword,
                                  hint: 'Minimal 6 karakter',
                                  controller: passwordController,
                                  obscureText: true,
                                  prefixIcon: Icons.lock_outline,
                                  validator: validatePassword,
                                ),

                                const SizedBox(height: paddingMedium),

                                // CONFIRM PASSWORD
                                CustomTextField(
                                  label: registerConfirmPassword,
                                  hint: 'Masukkan ulang password',
                                  controller: confirmPasswordController,
                                  obscureText: true,
                                  prefixIcon: Icons.lock_outline,
                                  validator: validateConfirmPassword,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: paddingMedium),

                        //  TERMS & CONDITIONS - ENHANCED
                        InkWell(
                          onTap: () {
                            setState(() {
                              agreeToTerms = !agreeToTerms;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: agreeToTerms
                                        ? primaryColor
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: agreeToTerms
                                          ? primaryColor
                                          : textColorLight.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: agreeToTerms
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: textColorWhite,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: const Row(
                                            children: [
                                              Icon(Icons.info_outline,
                                                  color: Colors.white,
                                                  size: 20),
                                              SizedBox(width: 12),
                                              Text(
                                                  'Syarat & Ketentuan akan segera tersedia'),
                                            ],
                                          ),
                                          backgroundColor: infoColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    child: RichText(
                                      text: const TextSpan(
                                        text: 'Saya setuju dengan ',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Syarat & Ketentuan',
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: primaryColor,
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
                        ),

                        const SizedBox(height: paddingLarge + 8),

                        //  REGISTER BUTTON - PREMIUM
                        Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(borderRadiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CustomButton(
                            text: registerButton,
                            onPressed: handleRegister,
                            isLoading: isLoading,
                          ),
                        ),

                        const SizedBox(height: paddingLarge),

                        // Spacer
                        const Spacer(),

                        //  LOGIN LINK - ENHANCED
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: paddingMedium),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            borderRadius:
                                BorderRadius.circular(borderRadiusMedium),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                text: 'Sudah punya akun? ',
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Masuk di sini',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      decoration: TextDecoration.underline,
                                      decorationColor: primaryColor,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pop(context);
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: paddingLarge),

                        // Version info
                        Center(
                          child: Text(
                            'Target Ibadah Harian v1.0',
                            style: TextStyle(
                              color: textColorLight.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: paddingMedium),
                      ],
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
}
