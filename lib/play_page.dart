// lib/select_set_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizzical/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizzical/multiple_choice_game.dart';
import 'package:quizzical/flashcards_game.dart';
import 'package:quizzical/create_page.dart'; // Import the QuestionSetsScreen
// Removed imports for settings_page.dart and google_nav_bar.dart as they are not used here anymore

class PlayPage extends StatelessWidget { // Changed back to StatelessWidget
  const PlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // This page no longer has its own Scaffold or AppBar.
    // It relies on a parent Scaffold (e.g., from AppNavigationScreen)
    // to provide the AppBar and BottomNavigationBar.
    return Container(
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
      child: Column( // Use a Column to place the title above the list
        children: [
          // The title is now part of the body content
          Padding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16.0, // Account for status bar and add padding
              left: isMobile ? 15.0 : 30.0,
              right: isMobile ? 15.0 : 30.0,
              bottom: 16.0,
            ),
            child: Align(
              alignment: Alignment.centerLeft, // Align title to the left
              child: Text(
                'Select a Set to Play',
                style: GoogleFonts.poppins(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 28 : 36,
                ),
              ),
            ),
          ),
          Expanded( // Let the GridView take the remaining space
            child: _buildQuestionSetsList(context, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSetsList(BuildContext context, bool isMobile) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
          child: Text('Please log in to see your question sets.'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('question_sets')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong.'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final sets = snapshot.data!.docs;

        if (sets.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 20.0 : 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Use min to wrap content
                children: [
                  Text(
                    'No sets to play yet!', // Updated message
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 22 : 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 15 : 25),
                  Text(
                    'It looks like you haven\'t created any quiz or flashcard sets. Let\'s make some!',
                    style: GoogleFonts.poppins(
                      fontSize: isMobile ? 16 : 18,
                      color: AppColors.textDark.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: isMobile ? 30 : 50),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to QuestionSetsScreen and tell it to open in create mode
                      // This navigation should ideally be handled by the parent AppNavigationScreen
                      // if this page is a direct tab.
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CreatePage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.add_circle_outline, // Fun icon
                      size: isMobile ? 30 : 40,
                      color: AppColors.textLight,
                    ),
                    label: Text(
                      'Create Your First Set!',
                      style: GoogleFonts.poppins(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textLight,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPink, // Vibrant color
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 30 : 50,
                        vertical: isMobile ? 18 : 25,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0), // More rounded
                      ),
                      elevation: 10, // More prominent shadow
                      shadowColor: AppColors.accentPink.withOpacity(0.4), // Shadow matching button color
                      animationDuration: const Duration(milliseconds: 300), // Smooth press animation
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: isMobile ? 15 : 20,
            mainAxisSpacing: isMobile ? 15 : 20,
            childAspectRatio: 0.8,
          ),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final set = sets[index];
            final setId = set.id;
            final setName = set['setName'];
            final setType = set['setType'];

            return GestureDetector(
              onTap: () {
                if (setType == 'Flashcards') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FlashcardsGamePage(setId: setId),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => QuizPage(setId: setId),
                    ),
                  );
                }
              },
              child: Container(
                constraints: BoxConstraints(maxWidth: isMobile ? 200 : 300),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: AppBorderRadius.small,
                  ),
                  elevation: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        setType == 'Flashcards'
                            ? Icons.style
                            : Icons.list_alt,
                        size: isMobile ? 40 : 60,
                        color: AppColors.primaryBlue,
                      ),
                      SizedBox(height: 10),
                      Text(
                        setName,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: isMobile ? 16 : 18,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        setType,
                        style: GoogleFonts.poppins(
                          fontSize: isMobile ? 12 : 14,
                          color: AppColors.textDark.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
