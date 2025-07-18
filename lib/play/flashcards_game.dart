// lib/flashcards_game.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizzical/utilities/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class FlashcardsGamePage extends StatefulWidget {
  final String setId;

  const FlashcardsGamePage({super.key, required this.setId});

  @override
  State<FlashcardsGamePage> createState() => _FlashcardsGamePageState();
}

class _FlashcardsGamePageState extends State<FlashcardsGamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isFront = true;

  List<Map<String, String>> _flashcards = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _fetchFlashcards();
  }

  Future<void> _fetchFlashcards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('question_sets')
          .doc(widget.setId)
          .collection('questions')
          .get();

      setState(() {
        _flashcards = snapshot.docs
            .map((doc) => {
          'front': doc['front'] as String,
          'back': doc['back'] as String,
        })
            .toList();
        _isLoading = false;
      });
    }
  }

  void _flipCard() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isFront = !_isFront;
    });
  }

  void _nextCard() {
    setState(() {
      if (_currentIndex < _flashcards.length - 1) {
        _currentIndex++;
      } else {
        _currentIndex = 0; // Loop back to the start
      }
      if (!_isFront) {
        _flipCard();
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (_currentIndex > 0) {
        _currentIndex--;
      } else {
        _currentIndex = _flashcards.length - 1; // Loop back to the end
      }
      if (!_isFront) {
        _flipCard();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Helper to build the flashcard widget (the flippable card itself)
  Widget _buildFlashcardWidget(bool isMobile) {
    return GestureDetector(
      onTap: _flipCard,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * pi;
          // Apply a 3D transformation for the flip effect
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspective effect
              ..rotateY(angle), // Rotate around Y-axis
            child: _isFront
                ? _buildCard(context, _flashcards[_currentIndex]['front']!) // Front side of the card
                : Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()..rotateY(pi), // Rotate back for the back side
              child: _buildCard(context, _flashcards[_currentIndex]['back']!), // Back side of the card
            ),
          );
        },
      ),
    );
  }

  // Helper to build the navigation buttons (Previous and Next)
  Widget _buildButtonsWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // Center buttons horizontally
      children: [
        ElevatedButton(
          onPressed: _previousCard,
          child: const Text('Previous Card'),
        ),
        const SizedBox(width: 20), // Spacing between buttons
        ElevatedButton(
          onPressed: _nextCard,
          child: const Text('Next Card'),
        ),
      ],
    );
  }

  // Main layout builder that arranges the flashcard and buttons responsively
  Widget _buildFlashcardLayout(bool isMobile) {
    // For both mobile and web, we want the buttons below the flashcard,
    // so a Column is the appropriate main arrangement.
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // Center the entire column vertically
      children: [
        _buildFlashcardWidget(isMobile), // The flashcard itself
        SizedBox(height: isMobile ? 20 : 40), // Vertical space between card and buttons. Increased for web.
        _buildButtonsWidget(), // The row of navigation buttons
      ],
    );
  }

  // Builds the visual card container with text
  Widget _buildCard(BuildContext context, String text) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        // Adjust width and height based on whether it's mobile or web
        width: isMobile ? 300 : 650, // Increased width for web to make it more rectangular
        height: isMobile ? 400 : 400, // Height remains the same for web
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryBlue,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Flashcards',
          style: GoogleFonts.poppins(
            color: AppColors.primaryBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primaryBlue),
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
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator() // Show loading indicator
              : _flashcards.isEmpty
              ? Text(
            'No flashcards in this set.', // Message if no flashcards
            style: GoogleFonts.poppins(
              fontSize: 18,
              color: AppColors.textDark,
            ),
          )
              : _buildFlashcardLayout(isMobile), // Use the responsive layout builder
        ),
      ),
    );
  }
}
