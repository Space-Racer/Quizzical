// lib/question_sets_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizzical/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quizzical/flashcards_game.dart'; // Import for navigation to flashcards
import 'package:quizzical/multiple_choice_game.dart'; // Import for navigation to quiz game
import 'package:quizzical/add_question_page.dart'; // Required for set creation options

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  // State to control which view is shown: list of sets or create new set options
  bool _isCreatingNewSet = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // Dynamically adjust toolbar height and title based on the view
        toolbarHeight: null, // Always show toolbar
        title: Text(
          _isCreatingNewSet ? 'Create New Set' : 'Your Quizzical Sets', // Dynamic title
          style: GoogleFonts.poppins(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 28 : 36,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
        // Add a back button when in the create set view
        leading: _isCreatingNewSet
            ? IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() {
              _isCreatingNewSet = false; // Go back to the sets list
            });
          },
        )
            : null, // No back button on the main sets list view
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
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPainter(),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
                child: Center(
                  // Conditional rendering based on _isCreatingNewSet state
                  child: _isCreatingNewSet
                      ? _buildCreateSetContent(context, isMobile) // Show create set options
                      : Column( // Show existing sets list view
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // The main title "Your Quizzical Sets" is now in the AppBar
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isCreatingNewSet = true; // Switch to create set view
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentPink,
                          foregroundColor: AppColors.textLight,
                          padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 25 : 35,
                              vertical: isMobile ? 12 : 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppBorderRadius.small),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.15),
                        ),
                        child: Text(
                          'Create New Set',
                          style: GoogleFonts.poppins(
                              fontSize: isMobile ? 16 : 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 30),
                      _buildQuestionSetsList(context, isMobile),
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

  // --- Methods from original create_set_page.dart, now integrated ---

  // New method to build the content for creating a new set
  Widget _buildCreateSetContent(BuildContext context, bool isMobile) {
    return Padding(
      // Padding is already handled by SingleChildScrollView, no extra padding here
      padding: EdgeInsets.all(0.0),
      child: isMobile
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _buildSetTypeBoxes(context, isMobile),
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _buildSetTypeBoxes(context, isMobile),
      ),
    );
  }

  List<Widget> _buildSetTypeBoxes(BuildContext context, bool isMobile) {
    return [
      _buildSetTypeBox(
        context,
        isMobile,
        'Flashcards',
        'Create a set of flashcards with a front and back.',
        Icons.style,
            () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddRemoveQuestionsScreen(
                isFlashcard: true,
              ),
            ),
          );
        },
      ),
      SizedBox(width: isMobile ? 0 : 30, height: isMobile ? 20 : 0),
      _buildSetTypeBox(
        context,
        isMobile,
        'Multiple Choice',
        'Create a multiple choice quiz with one correct answer.',
        Icons.list_alt,
            () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddRemoveQuestionsScreen(
                isFlashcard: false,
              ),
            ),
          );
        },
      ),
    ];
  }

  Widget _buildSetTypeBox(
      BuildContext context,
      bool isMobile,
      String title,
      String description,
      IconData icon,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        // Added fixed height for web to ensure consistent box size
        height: isMobile ? null : 250,
        padding: EdgeInsets.all(isMobile ? 20 : 30),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: AppBorderRadius.small,
          boxShadow: AppShadows.light,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: isMobile ? 50 : 70,
              color: AppColors.primaryBlue,
            ),
            SizedBox(height: isMobile ? 15 : 20),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: AppColors.primaryBlue,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 22 : 28,
              ),
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textDark,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Existing methods for CreatePage ---

  Widget _buildQuestionSetsList(BuildContext context, bool isMobile) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('Please log in to see your question sets.');
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
          return const Text('Something went wrong.');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        final sets = snapshot.data!.docs;

        if (sets.isEmpty) {
          // If no sets, automatically switch to the create new set view
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) { // Ensure the widget is still mounted before setState
              setState(() {
                _isCreatingNewSet = true;
              });
            }
          });
          return Container(); // Return an empty container while the state updates
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sets.length,
          itemBuilder: (context, index) {
            final set = sets[index];
            final setName = set['setName'] as String;
            final setType = set['setType'] as String;
            final setId = set.id;

            return Card(
              margin: EdgeInsets.only(bottom: isMobile ? 10 : 20),
              shape: RoundedRectangleBorder(
                borderRadius: AppBorderRadius.small,
              ),
              elevation: 3,
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddRemoveQuestionsScreen(
                        isFlashcard: setType == 'Flashcards',
                        setId: setId,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: isMobile ? null : 100,
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 8.0 : 16.0,
                    horizontal: isMobile ? 16.0 : 24.0,
                  ),
                  child: Row(
                    children: [
                      if (!isMobile)
                        Icon(
                          setType == 'Flashcards'
                              ? Icons.style
                              : Icons.list_alt,
                          size: 60,
                          color: AppColors.primaryBlue,
                        ),
                      if (!isMobile)
                        SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              setName,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryBlue,
                                fontSize: isMobile ? 18 : 22,
                              ),
                            ),
                            Text(
                              'Type: $setType',
                              style: GoogleFonts.poppins(
                                fontSize: isMobile ? 14 : 16,
                                color: AppColors.textDark.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: AppColors.primaryBlue),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => AddRemoveQuestionsScreen(
                                    isFlashcard: setType == 'Flashcards',
                                    setId: setId,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: AppColors.accentRed),
                            onPressed: () {
                              _deleteSet(context, setId);
                            },
                          ),
                        ],
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

void _deleteSet(BuildContext context, String setId) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Delete Set'),
        content: const Text('Are you sure you want to delete this set? This will also delete all questions in this set.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                await FirebaseFirestore.instance
                    .collection('artifacts')
                    .doc('my-trivia-app-id')
                    .collection('users')
                    .doc(user.uid)
                    .collection('question_sets')
                    .doc(setId)
                    .delete();
              }
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
