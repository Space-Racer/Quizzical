// lib/app_navigation.dart
import 'package:flutter/material.dart';
import 'package:quizzical/create_page.dart'; // Import the new question sets page
import 'package:quizzical/play_page.dart';
import 'package:quizzical/settings_page.dart'; // Import the new settings page
import 'package:google_nav_bar/google_nav_bar.dart';

class AppNavigationScreen extends StatefulWidget {
  const AppNavigationScreen({super.key});

  @override
  State<AppNavigationScreen> createState() => _AppNavigationScreenState();
}

class _AppNavigationScreenState extends State<AppNavigationScreen> {
  int _selectedIndex = 0; // Index of the currently selected tab

  // List of widgets (pages) to display in the navigation bar
  static final List<Widget> _widgetOptions = <Widget>[
    const PlayPage(), // Your main game page
    const CreatePage(), // Placeholder for adding questions
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardBackground,
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              color: Colors.black.withOpacity(.1),
            )
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8),
            child: GNav(
              rippleColor: Colors.grey[300]!,
              hoverColor: Colors.grey[100]!,
              gap: 8,
              activeColor: accentPink,
              iconSize: 24,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              duration: const Duration(milliseconds: 400),
              tabBackgroundColor: primaryBlue.withOpacity(0.1),
              color: primaryBlue.withOpacity(0.7),
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              tabs: const [
                GButton(
                  icon: Icons.casino,
                  text: 'Play',
                ),
                GButton(
                  icon: Icons.add_circle_outline,
                  text: 'Create',
                ),
                GButton(
                  icon: Icons.settings,
                  text: 'Settings',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabChange: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}