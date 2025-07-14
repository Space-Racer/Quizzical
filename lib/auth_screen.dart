// auth_screen.dart
import 'package:flutter/material.dart';
// Re-enabled Firebase imports
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart'; // Added for Firebase.initializeApp()
import 'package:google_fonts/google_fonts.dart';
import 'package:my_spinner_quiz_app/app_navigation.dart'; // Assuming this exists
import 'package:my_spinner_quiz_app/background_painter.dart'; // Import the background painter
import 'package:my_spinner_quiz_app/app_theme.dart'; // Import app theme for colors
import 'dart:convert'; // For JSON decoding of firebaseConfig

// Define global variables for Firebase configuration (provided by Canvas environment)
// These variables are expected to be available in the Flutter web environment.
// For local development, you might need to mock them or provide actual values.
const String __app_id = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');
const String __firebase_config = String.fromEnvironment('FIREBASE_CONFIG', defaultValue: '{}');
const String __initial_auth_token = String.fromEnvironment('INITIAL_AUTH_TOKEN', defaultValue: '');

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
  bool _isLoading = false; // Re-enabled _isLoading for async operations

  // Firebase instances
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final String _appId;
  String? _userId; // To store the current user's UID

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  // Initializes Firebase and sets up authentication listener
  void _initializeFirebase() async {
    try {
      // Parse the Firebase config JSON string
      final Map<String, dynamic> firebaseConfig = jsonDecode(__firebase_config);

      // Initialize Firebase App
      // This is crucial for web/Canvas environments to ensure Firebase SDK is ready.
      // If Firebase is already initialized globally (e.g., in main.dart),
      // this call might not be strictly necessary here, but it's safer to include
      // it or ensure `Firebase.initializeApp()` is called once at app startup.
      // For Canvas, we assume it might not be initialized elsewhere.
      await Firebase.initializeApp(
        options: FirebaseOptions(
          apiKey: firebaseConfig['apiKey'] ?? '', // Provide default empty string if null
          appId: firebaseConfig['appId'] ?? '', // Provide default empty string if null
          messagingSenderId: firebaseConfig['messagingSenderId'] ?? '', // Provide default empty string if null
          projectId: firebaseConfig['projectId'] ?? '', // Provide default empty string if null
          authDomain: firebaseConfig['authDomain'] ?? '', // Provide default empty string if null
          databaseURL: firebaseConfig['databaseURL'] ?? '', // Provide default empty string if null
          storageBucket: firebaseConfig['storageBucket'] ?? '', // Provide default empty string if null
          measurementId: firebaseConfig['measurementId'] ?? '', // Provide default empty string if null
        ),
      );

      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _appId = __app_id; // Get the app ID from the environment

      // Listen to authentication state changes
      _auth.authStateChanges().listen((user) async {
        if (!mounted) return; // Ensure widget is still in the tree

        setState(() {
          _userId = user?.uid; // Update userId when auth state changes
        });

        // If user is logged in and not on the AuthScreen, navigate to AppNavigationScreen
        // This check prevents navigating away if the user is already on another screen
        // and the auth state changes (e.g., token refresh).
        if (user != null && ModalRoute.of(context)?.isCurrent == true) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AppNavigationScreen()),
          );
        }
      });

      // Attempt to sign in with custom token if provided (for Canvas environment)
      if (__initial_auth_token.isNotEmpty) {
        await _auth.signInWithCustomToken(__initial_auth_token);
        print('Signed in with custom token.');
      } else {
        // If no custom token, sign in anonymously to ensure a user ID is available
        // for Firestore rules that require `request.auth != null`.
        await _auth.signInAnonymously();
        print('Signed in anonymously.');
      }
    } on FirebaseException catch (e) {
      print('Firebase initialization error: ${e.code} - ${e.message}');
      if (mounted) {
        _showSnackBar('Failed to initialize Firebase: ${e.message}', isError: true);
      }
    } catch (e) {
      print('Error initializing Firebase: $e');
      if (mounted) {
        _showSnackBar('Failed to initialize authentication: $e', isError: true);
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
    // Check if the widget is still mounted before showing a SnackBar
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

  // Handles user login or registration
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
        // Login existing user
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        _showSnackBar('Login successful!');
      } else {
        // Register new user
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Get the newly created user's UID
        final newUserUid = userCredential.user!.uid;

        // Store user profile data in Firestore
        await _firestore
            .collection('artifacts')
            .doc(_appId)
            .collection('users')
            .doc(newUserUid)
            .collection('profile')
            .doc('data') // Use 'data' as the document ID for profile
            .set({
          'userId': newUserUid,
          'email': email,
          'displayName': displayName,
          'createdAt': Timestamp.now(),
        });

        _showSnackBar('Registration successful!');
      }

      // Navigation is handled by the authStateChanges listener,
      // which will trigger after successful sign-in.
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

  // Handles guest login
  void _continueAsGuest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInAnonymously();
      _showSnackBar('Signed in as Guest!');
      // Navigation is handled by the authStateChanges listener
    } on FirebaseAuthException catch (e) {
      _showSnackBar('Failed to sign in as guest: ${e.message}', isError: true);
    } catch (e) {
      _showSnackBar('An unexpected error occurred during guest sign-in: $e', isError: true);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768; // Define mobile breakpoint

    // Get the base style from the theme, or a default empty style if null
    final ButtonStyle baseButtonStyle = Theme.of(context).elevatedButtonTheme.style ?? const ButtonStyle();

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
            // BackgroundPainter for the subtle circles
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
                      ? const EdgeInsets.all(20.0) // Smaller padding for mobile
                      : const EdgeInsets.all(40.0), // Larger padding for web
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: AppBorderRadius.large,
                    boxShadow: AppShadows.heavy,
                  ),
                  constraints: const BoxConstraints(maxWidth: 600), // Max width for auth form
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // Use min size for column
                      children: <Widget>[
                        Text(
                          _isLogin ? 'Welcome Back!' : 'Join Amazing Trivia!',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: isMobile ? 2.8 * 16 : 4.0 * 16, // Responsive font size
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),

                        // Display Name field (only for registration)
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              labelText: 'Display Name',
                              hintText: 'Enter your display name',
                              prefixIcon: Icon(Icons.person),
                            ),
                            keyboardType: TextInputType.text,
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a display name.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                        ],

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
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

                        // Password Field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(Icons.lock),
                          ),
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

                        // Confirm Password Field (only for registration)
                        if (!_isLogin) ...[
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              hintText: 'Re-enter your password',
                              prefixIcon: Icon(Icons.lock_reset),
                            ),
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
                          const SizedBox(height: 30), // Spacing for login form
                        ],

                        // Login/Register Button
                        _isLoading
                            ? const CircularProgressIndicator() // Show loading indicator
                            : ElevatedButton(
                          onPressed: _submitAuthForm,
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 25 : 35,
                              vertical: isMobile ? 15 : 18,
                            ),
                            textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontSize: isMobile ? 1.1 * 16 : 1.2 * 16,
                            ),
                            backgroundColor: baseButtonStyle.backgroundColor?.resolve({}),
                            foregroundColor: baseButtonStyle.foregroundColor?.resolve({}),
                            shape: baseButtonStyle.shape?.resolve({}),
                            elevation: baseButtonStyle.elevation?.resolve({}),
                            shadowColor: baseButtonStyle.shadowColor?.resolve({}),
                          ),
                          child: Text(_isLogin ? 'Login' : 'Register'),
                        ),
                        const SizedBox(height: 20),

                        // Toggle Login/Register
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState?.reset(); // Clear form fields on toggle
                              _emailController.clear();
                              _passwordController.clear();
                              _confirmPasswordController.clear();
                              _displayNameController.clear();
                            });
                          },
                          child: Text(
                            _isLogin
                                ? 'Don\'t have an account? Register'
                                : 'Already have an account? Login',
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Guest Play Option
                        TextButton(
                          onPressed: _continueAsGuest, // Call the new _continueAsGuest method
                          child: const Text(
                            'Continue as Guest',
                            // Removed explicit style override to use theme's TextButton style
                          ),
                        ),
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
