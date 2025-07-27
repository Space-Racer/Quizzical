// auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizzical/utilities/app_navigation.dart';
import 'package:quizzical/utilities/background_painter.dart';
import 'package:quizzical/utilities/app_theme.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? _userId;

  // It's good practice to initialize GoogleSignIn instance once
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  void _initializeFirebase() async {
    try {
      _auth.authStateChanges().listen((user) async {
        if (!mounted) return;

        setState(() {
          _userId = user?.uid;
        });

        if (user != null && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AppNavigationScreen()),
          );
        }
      });
    } catch (e) {
      print('Error initializing Firebase auth listener: $e');
      if (mounted) {
        _showSnackBar('Failed to set up authentication listener: $e', isError: true);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.accentRed : AppColors.accentGreen,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _submitAuthForm() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final displayName = _displayNameController.text.trim();

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        _showSnackBar('Login successful!');
      } else {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        final newUserUid = userCredential.user!.uid;

        await _firestore
            .collection('artifacts')
            .doc('my-trivia-app-id')
            .collection('users')
            .doc(newUserUid)
            .collection('profile')
            .doc('data')
            .set({
          'userId': newUserUid,
          'email': email,
          'displayName': displayName,
          'createdAt': Timestamp.now(),
        });

        _showSnackBar('Registration successful!');
      }
    } on FirebaseAuthException catch (e) {
      String message;
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'An account already exists for that email.';
      } else if (e.code == 'user-not-found' || e.code == 'wrong-password') {
        message = 'Invalid credentials. Please check your email and password.';
      } else {
        message = 'Authentication failed. Please try again later. Error: ${e.message}';
      }
      _showSnackBar(message, isError: true);
    } catch (e) {
      _showSnackBar('An unexpected error occurred: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use the initialized _googleSignIn instance
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken, // This should now be accessible
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user; // User can be null

      if (user == null) {
        _showSnackBar('Google sign-in failed: User data is null.', isError: true);
        if (mounted) setState(() => _isLoading = false);
        return;
      }


      // Check if it's a new user and create a profile document
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        await _firestore
            .collection('artifacts')
            .doc('my-trivia-app-id') // Consider making this configurable or a constant
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .doc('data')
            .set({
          'userId': user.uid,
          'email': user.email,
          'displayName': user.displayName,
          'createdAt': Timestamp.now(),
        });
      }

      _showSnackBar('Signed in with Google successfully!');
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Failed to sign in with Google: ${e.message}', isError: true);
    } catch (e) {
      _showSnackBar('An unexpected error occurred during Google sign-in: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.backgroundGradientStart,
              AppColors.backgroundGradientEnd,
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPainter(),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: isMobile
                      ? const EdgeInsets.all(20.0)
                      : const EdgeInsets.all(40.0),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground, // Using AppColors for consistency
                    borderRadius: AppBorderRadius.large, // Using AppBorderRadius
                    boxShadow: AppShadows.heavy, // Using AppShadows
                  ),
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          _isLogin ? 'Welcome to Quizzical!' : 'Join Quizzical!', // Changed title
                          style: GoogleFonts.montserrat( // Changed font to Montserrat
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 32 : 40, // Adjusted font size
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _displayNameController,
                            decoration: InputDecoration( // Using InputDecoration directly for more control
                              labelText: 'Display Name',
                              hintText: 'Enter your display name',
                              prefixIcon: Icon(Icons.person, color: AppColors.primaryBlue),
                              filled: true, // Make text field filled
                              fillColor: AppColors.backgroundGradientStart.withOpacity(0.1), // Light fill color
                              border: OutlineInputBorder(
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide.none, // No border by default
                              ),
                              enabledBorder: OutlineInputBorder( // Border when enabled
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide(color: AppColors.secondaryPurple.withOpacity(0.5), width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder( // Border when focused
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide(color: AppColors.accentPink, width: 2.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15, horizontal: 15),
                            ),
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.words,
                            style: GoogleFonts.montserrat(fontSize: isMobile ? 16 : 18, color: AppColors.textDark), // Montserrat font
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a display name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email, color: AppColors.primaryBlue),
                            filled: true,
                            fillColor: AppColors.backgroundGradientStart.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: AppBorderRadius.small,
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.small,
                              borderSide: BorderSide(color: AppColors.secondaryPurple.withOpacity(0.5), width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.small,
                              borderSide: BorderSide(color: AppColors.accentPink, width: 2.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15, horizontal: 15),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.montserrat(fontSize: isMobile ? 16 : 18, color: AppColors.textDark), // Montserrat font
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email address.';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email address.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(Icons.lock, color: AppColors.primaryBlue),
                            filled: true,
                            fillColor: AppColors.backgroundGradientStart.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: AppBorderRadius.small,
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.small,
                              borderSide: BorderSide(color: AppColors.secondaryPurple.withOpacity(0.5), width: 1.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: AppBorderRadius.small,
                              borderSide: BorderSide(color: AppColors.accentPink, width: 2.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15, horizontal: 15),
                          ),
                          style: GoogleFonts.montserrat(fontSize: isMobile ? 16 : 18, color: AppColors.textDark), // Montserrat font
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a password.';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters long.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              prefixIcon: Icon(Icons.lock_reset, color: AppColors.primaryBlue),
                              filled: true,
                              fillColor: AppColors.backgroundGradientStart.withOpacity(0.1),
                              border: OutlineInputBorder(
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide(color: AppColors.secondaryPurple.withOpacity(0.5), width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide(color: AppColors.accentPink, width: 2.0),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15, horizontal: 15),
                            ),
                            style: GoogleFonts.montserrat(fontSize: isMobile ? 16 : 18, color: AppColors.textDark), // Montserrat font
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please confirm your password.';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 30),
                        ] else ...[
                          const SizedBox(height: 30),
                        ],

                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                          onPressed: _submitAuthForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue, // Explicitly set primary blue
                            foregroundColor: AppColors.textLight, // White text
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 30 : 40, // Increased padding
                              vertical: isMobile ? 16 : 20, // Increased padding
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: AppBorderRadius.small, // Consistent border radius
                            ),
                            elevation: 8, // More prominent shadow
                            shadowColor: AppColors.primaryBlue.withOpacity(0.3), // Shadow matching button color
                          ),
                          child: Text(
                            _isLogin ? 'Login' : 'Register',
                            style: GoogleFonts.montserrat( // Montserrat font
                              fontSize: isMobile ? 18 : 20, // Adjusted font size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState?.reset();
                              _emailController.clear();
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                              _displayNameController.clear();
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue, // Primary blue for text button
                            textStyle: GoogleFonts.montserrat( // Montserrat font
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          child: Text(
                            _isLogin
                                ? 'Don\'t have an account? Register'
                                : 'Already have an account? Login',
                          ),
                        ),

                        // *** Google Sign-In ***
                        const SizedBox(height: 20), // Spacing after the previous button

                        _isLoading
                            ? const SizedBox.shrink() // Don't show another progress indicator if one is already showing
                            : Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobile ? double.infinity : 300,
                            ),
                            child: OutlinedButton(
                              onPressed: _signInWithGoogle,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textDark,
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.dividerColor, width: 1.0),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: isMobile ? 12 : 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: AppBorderRadius.small,
                                ),
                                elevation: 2,
                                shadowColor: Colors.black.withOpacity(0.1),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/google_logo.png',
                                    height: 24.0,
                                    width: 24.0,
                                    errorBuilder: (context, error, stackTrace) {
                                      print('Error loading Google logo: $error');
                                      return const Icon(Icons.error_outline, color: Colors.red);
                                    },
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Sign in with Google',
                                    style: GoogleFonts.montserrat(
                                      fontSize: isMobile ? 16 : 18,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
