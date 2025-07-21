// lib/quiz_game.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:vibration/vibration.dart';

// Re-using BackgroundPainter as it's a simple, abstract background
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

// Question model remains the same, but fromFirestore is removed as it's not used
class Question {
  final String questionText;
  final List<String> answers;
  final String correctAnswer;

  Question({
    required this.questionText,
    required this.answers,
    required this.correctAnswer,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Question(
      questionText: data['questionText'] ?? '',
      answers: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
    );
  }
}

class QuizPage extends StatefulWidget {
  final String setId;
  const QuizPage({super.key, required this.setId});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  // Removed SingleTickerProviderStateMixin
  int _score = 0;
  List<Question> _allQuestions = [];
  Question? _currentQuestion;
  String? _selectedAnswer;
  bool _answerSubmitted = false;
  int _currentQuestionIndex = 0; // To track current question for "Next" logic
  String _displayName = 'Player';
  int _xp = 0;

  Timer? _gameTimer;
  int _timeLeftInSeconds = 10;
  int _timerDuration = 10;

  bool _gameEnded = false;
  bool _isLoadingQuestions = true;
  bool _reviewModeEnabled = false;
  List<Question> _incorrectQuestions = [];
  bool _isReviewSession = false;

  late ConfettiController _confettiController;
  late AudioPlayer _correctAudioPlayer;
  late AudioPlayer _incorrectAudioPlayer;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 1));
    _correctAudioPlayer = AudioPlayer();
    _incorrectAudioPlayer = AudioPlayer();
    _loadAudio();

    _loadUserData();
    _fetchQuestions();
  }

  Future<void> _loadAudio() async {
    try {
      _correctAudioPlayer.setSource(AssetSource('audio/correct.mp3'));
      _incorrectAudioPlayer.setSource(AssetSource('audio/incorrect.mp3'));
    } catch (e) {
      print(
          "Error loading audio: $e. Make sure assets are correctly configured in pubspec.yaml");
    }
  }

  void _startTimer() {
    _timeLeftInSeconds = _timerDuration; // Reset timer for each question
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftInSeconds > 0) {
        setState(() {
          _timeLeftInSeconds--;
        });
      } else {
        _gameTimer?.cancel();
        // Time's up, automatically submit answer (or mark as incorrect/skipped)
        _submitAnswer(isTimeUp: true);
      }
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profileDoc = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .get();
      if (profileDoc.exists) {
        setState(() {
          _displayName = profileDoc.data()?['displayName'] ?? 'Player';
          _xp = profileDoc.data()?['xp'] ?? 0;
        });
      }

      if (!user.isAnonymous) {
        final settingsDoc = await FirebaseFirestore.instance
            .collection('artifacts')
            .doc('my-trivia-app-id')
            .collection('users')
            .doc(user.uid)
            .collection('profile')
            .doc('settings')
            .get();
        if (settingsDoc.exists) {
          setState(() {
            _reviewModeEnabled = settingsDoc.data()?['review'] ?? false;
            final confettiEnabled = settingsDoc.data()?['confetti'] ?? true;
            _timerDuration = settingsDoc.data()?['timerDuration'] ?? 10;
            _timeLeftInSeconds = _timerDuration;
            if (!confettiEnabled) {
              _confettiController.stop();
            }
          });
        }
      }
    }
  }

  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
      _currentQuestion = null;
      _selectedAnswer = null;
      _answerSubmitted = false;
      _currentQuestionIndex = 0;
      _gameEnded = false;
    });

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
      _allQuestions =
          snapshot.docs.map((doc) => Question.fromFirestore(doc)).toList();
    }

    if (_allQuestions.isEmpty) {
      // Handle case where user has no questions
      setState(() {
        _isLoadingQuestions = false;
        _currentQuestion = Question(
          questionText: "No questions available in this set.",
          answers: [],
          correctAnswer: "",
        );
      });
      return;
    }

    _allQuestions.shuffle();
    _loadNextQuestion();
    _startTimer();

    setState(() {
      _isLoadingQuestions = false;
    });
  }

  void _loadNextQuestion() {
    _gameTimer?.cancel();

    if (_currentQuestionIndex < _allQuestions.length) {
      setState(() {
        _currentQuestion = _allQuestions[_currentQuestionIndex];
        _currentQuestion!.answers.shuffle();
        _selectedAnswer = null;
        _answerSubmitted = false;
        _timeLeftInSeconds = _timerDuration;
      });
      _currentQuestionIndex++;
      _startTimer();
    } else if (_reviewModeEnabled &&
        _incorrectQuestions.isNotEmpty &&
        !_isReviewSession) {
      _startReviewSession();
    } else {
      setState(() {
        _gameEnded = true;
      });
      _showGameEndDialog();
    }
  }

  void _selectAnswer(String answer) {
    if (_answerSubmitted || _currentQuestion == null || _gameEnded) {
      return;
    }

    setState(() {
      _selectedAnswer = answer;
    });
    _submitAnswer(); // Automatically submit on selection based on mockup's implied interaction
  }

  void _submitAnswer({bool isTimeUp = false}) {
    if (_answerSubmitted || _currentQuestion == null || _gameEnded) {
      return;
    }

    _gameTimer?.cancel(); // Stop the timer immediately

    setState(() {
      _answerSubmitted = true;
      if (isTimeUp) {
        Vibration.vibrate(duration: 100);
        print("Time's up! Question skipped.");
        if (_reviewModeEnabled) {
          _incorrectQuestions.add(_currentQuestion!);
        }
      } else if (_selectedAnswer == _currentQuestion!.correctAnswer) {
        _score++;
        _updateXp(10);
        _correctAudioPlayer.resume();
        final user = FirebaseAuth.instance.currentUser;
        if (user != null && !user.isAnonymous) {
          FirebaseFirestore.instance
              .collection('artifacts')
              .doc('my-trivia-app-id')
              .collection('users')
              .doc(user.uid)
              .collection('profile')
              .doc('settings')
              .get()
              .then((doc) {
            if (doc.exists && (doc.data()?['confetti'] ?? true)) {
              _confettiController.play();
            }
          });
        } else if (user != null && user.isAnonymous) {
          _confettiController.play();
        }
        Vibration.vibrate(duration: 50);
      } else {
        // Only decrement score if an incorrect answer was explicitly selected, not just time up
        if (_selectedAnswer != null) {
          _score--;
          if (_reviewModeEnabled) {
            _incorrectQuestions.add(_currentQuestion!);
          }
          _incorrectAudioPlayer.resume();
          Vibration.vibrate(duration: 400);
        }
      }
    });

    // Move to next question after a short delay to show feedback
    Future.delayed(const Duration(milliseconds: 1500), () {
      _loadNextQuestion();
    });
  }

  void _startReviewSession() {
    setState(() {
      _isReviewSession = true;
      _allQuestions = _incorrectQuestions;
      _incorrectQuestions = [];
      _currentQuestionIndex = 0;
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review Time!'),
        content: Text('Let\'s go over the questions you got wrong.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadNextQuestion();
            },
            child: Text('Start Review'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _score = 0;
      _currentQuestion = null;
      _selectedAnswer = null;
      _answerSubmitted = false;
      _gameEnded = false;
      _isLoadingQuestions = true;
      _currentQuestionIndex = 0;
      _timeLeftInSeconds = _timerDuration; // Reset timer display
    });
    _gameTimer?.cancel();
    _loadUserData();
    _fetchQuestions();
  }

  void _updateXp(int amount) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .update({'xp': FieldValue.increment(amount)});
      setState(() {
        _xp += amount;
      });
    }
  }

  void _showGameEndDialog() {
    _updateXp(50); // Award bonus XP for completing the quiz
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .update({'score': FieldValue.increment(_score)});
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
          title: Text(
            'Game Over!',
            style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
                fontSize: 28),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Your final score is: $_score points!',
            style: GoogleFonts.poppins(
                fontSize: 20.0, color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              child: Text('Play Again',
                  style: Theme.of(context).textTheme.labelLarge),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _confettiController.dispose();
    _correctAudioPlayer.dispose();
    _incorrectAudioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    // int minutes = seconds ~/ 60; // Not needed for 10-second timer
    // int remainingSeconds = seconds % 60; // Not needed for 10-second timer
    return seconds.toString(); // Just show seconds directly for 10-second timer
  }

  @override
  Widget build(BuildContext context) {
    // Access theme colors
    final Color primaryPurpleDark = Theme.of(context).primaryColor;
    final Color secondaryPurpleMedium = const Color(0xFF8B5FBF); // From main.dart
    final Color accentPink = Theme.of(context).colorScheme.secondary;
    final Color cardWhite = Theme.of(context).colorScheme.surface;
    final Color textWhite = Theme.of(context).colorScheme.onPrimary;
    final Color successGreen = const Color(0xFF2ECC71); // Define success green
    final Color errorRed = Theme.of(context).colorScheme.error; // Define error red

    final bool showQuestionContent =
        _currentQuestion != null && !_isLoadingQuestions;

    // Determine if it's a mobile layout
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow gradient from parent
      // Extend body behind app bar to make the gradient continuous
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Multiple Choice',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: primaryPurpleDark, // Set title color to primaryPurpleDark
          ),
        ),
        centerTitle: true,
        // Set app bar background to transparent to show the body gradient
        backgroundColor: Colors.transparent,
        elevation: 0, // No shadow for a flat look
        iconTheme: IconThemeData(color: primaryPurpleDark), // Back button color to primaryPurpleDark
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD8BFD8), // Background gradient start from AppTheme
              Color(0xFFBA55D3), // Background gradient end from AppTheme
            ],
          ),
        ),
        child: SafeArea( // Ensures content is below the AppBar, especially on web/desktop
          child: Stack(
            children: [
              // BackgroundPainter for the subtle circles (if still desired)
              Positioned.fill(
                child: CustomPaint(
                  painter: BackgroundPainter(),
                ),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.all(isMobile ? 15.0 : 20.0), // Adjust margin for mobile
                  padding: EdgeInsets.all(isMobile ? 20.0 : 25.0), // Adjust padding for mobile
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(
                        isMobile ? 20.0 : 30.0), // Adjust border radius for mobile
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15), // Subtle shadow
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(maxWidth: 600), // Max width for the card
                  child: Column(
                    mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max, // Control height based on mobile
                    children: <Widget>[
                      // Top Row: User Info and Timer (instead of Question Number)
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 5.0 : 10.0,
                            vertical: isMobile ? 10.0 : 15.0), // Adjust padding for mobile
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // User Info
                            Flexible( // Use Flexible to prevent overflow on smaller screens
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // Shrink to fit content
                                children: [
                                  Text(
                                    'Hi, $_displayName!',
                                    style: GoogleFonts.poppins(
                                        fontSize: isMobile ? 16 : 18, // Smaller font for mobile
                                        color: primaryPurpleDark,
                                        fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis, // Handle overflow
                                  ),
                                  SizedBox(width: isMobile ? 5 : 10), // Smaller gap for mobile
                                  // Highlighted XP text
                                  Text(
                                    'XP: $_xp',
                                    style: GoogleFonts.poppins(
                                      fontSize: isMobile ? 16 : 18, // Smaller font for mobile
                                      color: Colors.amber[700], // Golden color
                                      fontWeight: FontWeight.bold, // Make it bolder
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Timer Container
                            Container(
                              width: isMobile ? 50 : 60, // Smaller timer circle for mobile
                              height: isMobile ? 50 : 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: secondaryPurpleMedium, // Solid purple background
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: isMobile ? 50 : 60,
                                      height: isMobile ? 50 : 60,
                                      child: CircularProgressIndicator(
                                        value: _timeLeftInSeconds /
                                            10, // Progress from 1.0 to 0.0 for 10 seconds
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            textWhite.withOpacity(0.5)),
                                        backgroundColor: Colors.transparent,
                                        strokeWidth: 4,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(_timeLeftInSeconds),
                                      style: GoogleFonts.poppins(
                                          fontSize: isMobile ? 20 : 24, // Smaller font for mobile
                                          fontWeight: FontWeight.bold,
                                          color: textWhite),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isMobile ? 15 : 25), // Smaller gap for mobile

                      // Question Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isMobile ? 20.0 : 30.0), // Adjust padding for mobile
                        decoration: BoxDecoration(
                          color: primaryPurpleDark, // Dark purple background
                          borderRadius:
                          BorderRadius.circular(isMobile ? 15.0 : 20.0), // Rounded corners
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isLoadingQuestions
                              ? CircularProgressIndicator(
                              valueColor:
                              AlwaysStoppedAnimation<Color>(textWhite))
                              : Text(
                            _currentQuestion?.questionText ??
                                'Loading Question...',
                            style: GoogleFonts.poppins(
                                fontSize: isMobile ? 18 : 22, // Smaller font for mobile
                                color: textWhite,
                                fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 30), // Smaller gap for mobile

                      // Answer Buttons Grid
                      if (showQuestionContent && _currentQuestion!.answers.isNotEmpty)
                        Expanded( // Use Expanded to fill remaining vertical space
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final double crossAxisSpacing = isMobile ? 10.0 : 15.0;
                              final double mainAxisSpacing = isMobile ? 10.0 : 15.0;
                              final double itemWidth = (constraints.maxWidth - crossAxisSpacing) / 2;

                              // Calculate button height dynamically based on available height,
                              // ensuring a minimum height for "big and fun"
                              final double availableHeight = constraints.maxHeight;
                              final int numRows = (_currentQuestion!.answers.length / 2).ceil();
                              final double totalSpacingHeight = (numRows - 1) * mainAxisSpacing;
                              // Ensure totalSpacingHeight is not negative for less than 2 rows
                              final double effectiveTotalSpacingHeight = max(0.0, totalSpacingHeight);

                              final double calculatedButtonHeight = (availableHeight - effectiveTotalSpacingHeight) / numRows;

                              // Ensure a minimum "fun" height, but allow it to grow if space allows
                              final double minFunButtonHeight = isMobile ? 60.0 : 75.0; // Adjusted for mobile height
                              final double finalButtonHeight = max(calculatedButtonHeight, minFunButtonHeight);

                              final double calculatedChildAspectRatio = itemWidth / finalButtonHeight;

                              return GridView.builder(
                                shrinkWrap: true, // Still shrinkWrap, but Expanded will provide constraints
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: crossAxisSpacing,
                                  mainAxisSpacing: mainAxisSpacing,
                                  childAspectRatio: calculatedChildAspectRatio,
                                ),
                                itemCount: _currentQuestion!.answers.length,
                                itemBuilder: (context, index) {
                                  final answer = _currentQuestion!.answers[index];
                                  return AnswerButton(
                                    answerText: answer,
                                    isSelected: _selectedAnswer == answer,
                                    isCorrect: _answerSubmitted &&
                                        answer == _currentQuestion!.correctAnswer,
                                    isIncorrect: _answerSubmitted &&
                                        _selectedAnswer == answer &&
                                        answer != _currentQuestion!.correctAnswer,
                                    onTap: _answerSubmitted || _gameEnded
                                        ? null
                                        : () => _selectAnswer(answer),
                                    primaryPurpleDark: primaryPurpleDark,
                                    secondaryPurpleMedium: secondaryPurpleMedium,
                                    textWhite: textWhite,
                                    successGreen: successGreen,
                                    errorRed: errorRed,
                                    isMobile: isMobile, // Pass isMobile to button
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      SizedBox(height: isMobile ? 15 : 30), // Smaller gap before next button/end

                      // Next Question Button (only appears after answer submitted)
                      if (_answerSubmitted && !_gameEnded)
                        ElevatedButton(
                          onPressed: _loadNextQuestion,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryPurpleDark, // Dark purple
                            foregroundColor: textWhite,
                            padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 25 : 40,
                                vertical: isMobile ? 10 : 15), // Adjust padding
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(isMobile ? 12.0 : 15.0)), // Adjust radius
                            elevation: 5,
                            shadowColor: Colors.black.withOpacity(0.15),
                          ),
                          child: Text('Next Question',
                              style: GoogleFonts.poppins(
                                  fontSize: isMobile ? 18 : 20, // Adjust font size
                                  fontWeight: FontWeight.bold)),
                        ),
                      SizedBox(height: isMobile ? 5 : 10), // Even smaller gap at bottom for mobile
                    ],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: pi / 2,
                  maxBlastForce: 20,
                  minBlastForce: 8,
                  emissionFrequency: 0.03,
                  numberOfParticles: 20,
                  gravity: 0.3,
                  colors: [accentPink, successGreen, primaryPurpleDark, textWhite],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Separate Widget for Answer Buttons for reusability and cleaner code
class AnswerButton extends StatelessWidget {
  final String answerText;
  final bool isSelected;
  final bool isCorrect;
  final bool isIncorrect;
  final VoidCallback? onTap;
  final bool isMobile; // Added to adjust button styling

  // Pass theme colors directly for more control within the button
  final Color primaryPurpleDark;
  final Color secondaryPurpleMedium;
  final Color textWhite;
  final Color successGreen;
  final Color errorRed;

  const AnswerButton({
    super.key,
    required this.answerText,
    this.isSelected = false,
    this.isCorrect = false,
    this.isIncorrect = false,
    this.onTap,
    required this.primaryPurpleDark,
    required this.secondaryPurpleMedium,
    required this.textWhite,
    required this.successGreen,
    required this.errorRed,
    this.isMobile = false, // Default to false for web
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = secondaryPurpleMedium; // Default unselected color
    Color textColor = textWhite;
    Color borderColor = secondaryPurpleMedium; // Default border color
    List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];

    // Apply colors based on answer state
    if (isCorrect) {
      backgroundColor = successGreen;
      borderColor = successGreen;
      shadows = [
        BoxShadow(
          color: successGreen.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];
    } else if (isIncorrect) {
      backgroundColor = errorRed;
      borderColor = errorRed;
      shadows = [
        BoxShadow(
          color: errorRed.withOpacity(0.3),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ];
    } else if (isSelected) {
      // If selected but not yet correct/incorrect (before submit feedback)
      borderColor = primaryPurpleDark; // Highlight selected with primary color
      // Keep background as default or slightly darker secondary
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            vertical: isMobile ? 10 : 15,
            horizontal: isMobile ? 8 : 10), // Adjusted padding for mobile
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius:
          BorderRadius.circular(isMobile ? 10.0 : 12.0), // Rounded corners for buttons
          border: Border.all(color: borderColor, width: 2), // Border for buttons
          boxShadow: shadows,
        ),
        child: Center(
          // Center the text within the button
          child: Text(
            answerText,
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 16 : 18, // Adjust text size for mobile/web
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}