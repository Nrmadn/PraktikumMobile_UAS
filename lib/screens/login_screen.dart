import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../services/firebase/firebase_auth_service.dart';  // ✅ TAMBAH

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  bool isLoading = false;
  bool rememberMe = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    
    // Setup animation - COMPLETE WITH ALL 3 ANIMATIONS
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animController, 
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn)
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController, 
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic)
    ));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut)
      ),
    );
    
    _animController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return emptyEmailError;
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
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

void handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        // ✅ GUNAKAN FIREBASE AUTH SERVICE
        final user = await FirebaseAuthService.login(
          emailController.text.trim(),
          passwordController.text,
        );

        if (user == null) {
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
                        'Email atau password salah! Silakan coba lagi.',
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

        // ✅ SIMPAN KE SHARED PREFERENCES (untuk offline access)
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', user.id);
        await prefs.setString('userEmail', user.email);
        await prefs.setString('userName', user.name);
        await prefs.setInt('userLevel', user.level);
        await prefs.setInt('userPoints', user.points);
        await prefs.setBool('isLoggedIn', true);

        if (mounted) {
          setState(() {
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Selamat datang, ${user.name}! 👋',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: successColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 2),
            ),
          );

          Navigator.pushReplacementNamed(context, '/home');
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
                minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: paddingLarge),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: paddingXLarge),
                        
                        // HEADER - CLEAN & SIMPLE (MATCHING REGISTER)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: ScaleTransition(
                            scale: _scaleAnimation,
                            child: Column(
                              children: [
                                // Logo with gradient background
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
                                    Icons.mosque,
                                    color: textColorWhite,
                                    size: 50,
                                  ),
                                ),
                                const SizedBox(height: paddingLarge),
                                
                                // Title with gradient
                                ShaderMask(
                                  shaderCallback: (bounds) => const LinearGradient(
                                    colors: [primaryColor, primaryColorDark],
                                  ).createShader(bounds),
                                  child: const Text(
                                    loginTitle,
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
                                  'Mulai perjalanan ibadah Anda hari ini ✨',
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

                        const SizedBox(height: paddingXLarge),

                        //  EMAIL INPUT WITH ENHANCED STYLE
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              children: [
                                CustomTextField(
                                  label: loginEmail,
                                  hint: 'contoh@email.com',
                                  controller: emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: Icons.email_outlined,
                                  validator: validateEmail,
                                ),

                                const SizedBox(height: paddingMedium + 4),

                                //  PASSWORD INPUT
                                CustomTextField(
                                  label: loginPassword,
                                  hint: 'Minimal 6 karakter',
                                  controller: passwordController,
                                  obscureText: true,
                                  prefixIcon: Icons.lock_outline,
                                  validator: validatePassword,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: paddingMedium),

                        // REMEMBER ME & FORGOT PASSWORD - IMPROVED
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remember me checkbox
                            InkWell(
                              onTap: () {
                                setState(() {
                                  rememberMe = !rememberMe;
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
                                        color: rememberMe ? primaryColor : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: rememberMe ? primaryColor : textColorLight.withOpacity(0.3),
                                          width: 2,
                                        ),
                                      ),
                                      child: rememberMe
                                          ? const Icon(
                                              Icons.check,
                                              size: 16,
                                              color: textColorWhite,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Ingat saya',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Forgot password
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.info_outline, color: Colors.white, size: 20),
                                        SizedBox(width: 12),
                                        Text('Fitur ini akan segera tersedia'),
                                      ],
                                    ),
                                    backgroundColor: primaryColor,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              child: const Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: paddingLarge + 8),

                        //  PREMIUM LOGIN BUTTON
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadiusMedium),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: CustomButton(
                            text: loginButton,
                            onPressed: handleLogin,
                            isLoading: isLoading,
                          ),
                        ),

                        const SizedBox(height: paddingLarge),

                        // Spacer untuk push content ke bawah
                        const Spacer(),

                        //  REGISTER LINK - ENHANCED
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: paddingMedium),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(borderRadiusMedium),
                            border: Border.all(
                              color: primaryColor.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: RichText(
                              text: TextSpan(
                                text: 'Belum punya akun? ',
                                style: const TextStyle(
                                  color: textColor,
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'Daftar Sekarang',
                                    style: const TextStyle(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      decoration: TextDecoration.underline,
                                      decorationColor: primaryColor,
                                    ),
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {
                                        Navigator.pushNamed(context, '/register');
                                      },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: paddingLarge),

                        // Version or copyright info
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