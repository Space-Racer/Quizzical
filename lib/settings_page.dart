// lib/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizzical/app_theme.dart'; // Import app theme for colors
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizzical/auth_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Controllers for text input fields
  final TextEditingController _timerDurationController = TextEditingController(text: '10');
  final TextEditingController _userNameController = TextEditingController(text: 'PlayerOne');
  // State for the confetti toggle
  bool _confettiEnabled = true;
  bool _reviewModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  void _loadUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          _userNameController.text = data?['displayName'] ?? '';
          _timerDurationController.text = (data?['timerDuration'] ?? 10).toString();
          _confettiEnabled = data?['confettiEnabled'] ?? true;
          _reviewModeEnabled = data?['reviewModeEnabled'] ?? false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timerDurationController.dispose();
    _userNameController.dispose();
    super.dispose();
  }

  // Helper to show a SnackBar message
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.accentRed : AppColors.accentGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _saveTimerSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final int? newDuration = int.tryParse(_timerDurationController.text);
      if (newDuration != null && newDuration >= 5 && newDuration <= 60) {
        await FirebaseFirestore.instance
            .collection('artifacts')
            .doc('my-trivia-app-id')
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .doc('data')
            .update({'timerDuration': newDuration});
        _showSnackBar('Timer duration saved!');
      } else {
        _showSnackBar('Please enter a valid duration (5-60 seconds).', isError: true);
      }
    }
  }

  void _saveProfileSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final String userName = _userNameController.text.trim();
      if (userName.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('artifacts')
            .doc('my-trivia-app-id')
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .doc('data')
            .update({'displayName': userName});
        _showSnackBar('Profile settings saved!');
      } else {
        _showSnackBar('User Name cannot be empty.', isError: true);
      }
    }
  }

  void _saveVisualSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .update({'confettiEnabled': _confettiEnabled});
      _showSnackBar('Visual settings saved!');
    }
  }

  void _saveReviewModeSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .update({'reviewModeEnabled': _reviewModeEnabled});
      _showSnackBar('Review mode settings saved!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow gradient from parent
      appBar: AppBar(
        toolbarHeight: 0, // Makes app bar effectively invisible
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
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
            // BackgroundPainter for the subtle circles (if you want to keep it)
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPainter(), // BackgroundPainter is now defined below
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 15.0 : 30.0), // Responsive padding
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start, // Align content to the top
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'App Settings',
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 28 : 36, // Responsive font size
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 20 : 30),

                      // Timer Settings Section
                      _buildSettingsSection(
                        context,
                        title: 'Timer Settings',
                        children: [
                          Text(
                            'Timer Duration (seconds):',
                            style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                          ),
                          SizedBox(height: isMobile ? 8 : 10),
                          TextFormField(
                            controller: _timerDurationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g., 10',
                              border: OutlineInputBorder(
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide(color: AppColors.secondaryPurple),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide(color: AppColors.accentPink, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15, horizontal: 15),
                            ),
                            style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, color: AppColors.textDark),
                          ),
                          SizedBox(height: isMobile ? 15 : 20),
                          _buildSaveButton(
                            context,
                            text: 'Save Timer',
                            onPressed: _saveTimerSettings,
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 20 : 30),

                      // User Profile Section
                      _buildSettingsSection(
                        context,
                        title: 'User Profile',
                        children: [
                          Text(
                            'Your Name:',
                            style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                          ),
                          SizedBox(height: isMobile ? 8 : 10),
                          TextFormField(
                            controller: _userNameController,
                            decoration: InputDecoration(
                              hintText: 'e.g., PlayerOne',
                              border: OutlineInputBorder(
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide(color: AppColors.secondaryPurple),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: AppBorderRadius.small,
                                borderSide: BorderSide(color: AppColors.accentPink, width: 2),
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15, horizontal: 15),
                            ),
                            style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, color: AppColors.textDark),
                          ),
                          SizedBox(height: isMobile ? 15 : 20),
                          _buildSaveButton(
                            context,
                            text: 'Save Profile',
                            onPressed: _saveProfileSettings,
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 20 : 30),

                      // Visuals & Sounds Section
                      _buildSettingsSection(
                        context,
                        title: 'Visuals & Sounds',
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Enable Confetti on Correct Answer:',
                                style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                              ),
                              Switch(
                                value: _confettiEnabled,
                                onChanged: (bool value) {
                                  setState(() {
                                    _confettiEnabled = value;
                                  });
                                },
                                activeColor: AppColors.accentGreen,
                                inactiveThumbColor: AppColors.accentRed,
                                inactiveTrackColor: AppColors.accentRed.withOpacity(0.5),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 15 : 20),
                          _buildSaveButton(
                            context,
                            text: 'Save Visuals',
                            onPressed: _saveVisualSettings,
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 20 : 30), // Extra space at bottom

                      // Review Mode Section
                      _buildSettingsSection(
                        context,
                        title: 'Review Mode',
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Enable Review Mode:',
                                style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                              ),
                              Switch(
                                value: _reviewModeEnabled,
                                onChanged: (bool value) {
                                  setState(() {
                                    _reviewModeEnabled = value;
                                  });
                                },
                                activeColor: AppColors.accentGreen,
                                inactiveThumbColor: AppColors.accentRed,
                                inactiveTrackColor: AppColors.accentRed.withOpacity(0.5),
                              ),
                            ],
                          ),
                          SizedBox(height: isMobile ? 15 : 20),
                          _buildSaveButton(
                            context,
                            text: 'Save Review Mode',
                            onPressed: _saveReviewModeSettings,
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 20 : 30), // Extra space at bottom

                      // Logout Button
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                                (Route<dynamic> route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentRed,
                          foregroundColor: AppColors.textLight,
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 25 : 35, vertical: isMobile ? 12 : 15),
                          shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.15),
                        ),
                        child: Text(
                          'Logout',
                          style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
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
    );
  }

  // Helper method to build a consistent settings section card
  Widget _buildSettingsSection(BuildContext context, {required String title, required List<Widget> children}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600), // Max width for settings cards
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppBorderRadius.small,
        boxShadow: AppShadows.light,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 22 : 28,
            ),
            textAlign: TextAlign.center, // Center title within its section
          ),
          SizedBox(height: isMobile ? 15 : 25),
          ...children,
        ],
      ),
    );
  }

  // Helper method to build a consistent save button
  Widget _buildSaveButton(BuildContext context, {required String text, required VoidCallback onPressed}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentGreen, // Green for save buttons
        foregroundColor: AppColors.textLight,
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 25 : 35, vertical: isMobile ? 12 : 15),
        shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.15),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// BackgroundPainter is now defined directly in this file
class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.purple.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 50, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.7), 70, paint);

    paint.color = Colors.amber.withOpacity(0.1);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.05), 30, paint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.8), 40, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
