// lib/app_navigation.dart
import 'package:flutter/material.dart';
import 'package:my_spinner_quiz_app/quiz_game.dart'; // Import your existing quiz game page
import 'package:my_spinner_quiz_app/add_question_page.dart'; // Import the new add question page
import 'package:my_spinner_quiz_app/settings_page.dart'; // Import the new settings page
import 'package:google_fonts/google_fonts.dart'; // NEW: Import google_fonts for custom text styles

class AppNavigationScreen extends StatefulWidget {
  const AppNavigationScreen({super.key});

  @override
  State<AppNavigationScreen> createState() => _AppNavigationScreenState();
}

class _AppNavigationScreenState extends State<AppNavigationScreen> {
  int _selectedIndex = 0; // Index of the currently selected tab

  // List of widgets (pages) to display in the navigation bar
  static final List<Widget> _widgetOptions = <Widget>[
    const SpinnerQuizPage(), // Your main game page
    const AddRemoveQuestionsScreen(), // Placeholder for adding questions
    const SettingsScreen(),   // Placeholder for settings
  ];

  // Function to handle tab selection
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Access theme colors
    final Color primaryBlue = Theme.of(context).primaryColor;
    final Color accentPink = Theme.of(context).colorScheme.secondary;
    final Color textDark = Theme.of(context).colorScheme.onSurface; // For unselected text
    final Color cardBackground = Theme.of(context).colorScheme.surface; // Used for nav bar background

    return Scaffold(
      // Set Scaffold background to transparent to allow the body's gradient to show
      backgroundColor: Colors.transparent,
      body: Container(
        // Apply the background gradient from the HTML mockup
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD8BFD8), // --background-gradient-start
              Color(0xFFBA55D3), // --background-gradient-end
            ],
          ),
        ),
        // The body displays the currently selected page
        child: Center(
          child: _widgetOptions.elementAt(_selectedIndex),
        ),
      ),
      // Bottom navigation bar
      bottomNavigationBar: Container( // Wrap BottomNavigationBar in a Container for shadow
        decoration: BoxDecoration(
          color: cardBackground, // Use the card background color for the nav bar
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15), // --shadow-light from HTML
              blurRadius: 10,
              offset: const Offset(0, -5), // Shadow pointing upwards
            ),
          ],
          borderRadius: const BorderRadius.only( // Optional: rounded top corners for nav bar
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: BottomNavigationBar(
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: const Icon(Icons.casino), // Icon for the spinner game
              label: 'Play',
              backgroundColor: cardBackground, // Ensure item background matches container
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline), // Icon for adding questions
              label: 'Add Questions',
              backgroundColor: cardBackground,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings), // Icon for settings
              label: 'Settings',
              backgroundColor: cardBackground,
            ),
          ],
          currentIndex: _selectedIndex, // Highlight the current tab
          selectedItemColor: accentPink, // Vibrant pink for selected item
          unselectedItemColor: primaryBlue.withOpacity(0.7), // Muted primary blue for unselected
          onTap: _onItemTapped, // Call _onItemTapped when a tab is tapped
          backgroundColor: Colors.transparent, // Set to transparent as container handles color
          type: BottomNavigationBarType.fixed, // Ensures all labels are visible
          selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14), // Poppins bold
          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.normal, fontSize: 12), // Poppins normal
          elevation: 0, // Remove default elevation as container provides shadow
        ),
      ),
    );
  }
}