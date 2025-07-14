// lib/quiz_game.dart
import 'package:flutter/material.dart';
import 'dart:math'; // Still needed for random question selection
import 'dart:async'; // Still needed for game timer
// Removed Firebase imports:
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Import for Google Fonts
// import 'package:confetti/confetti.dart'; // Keep if you want confetti
// import 'package:just_audio/just_audio.dart'; // Keep if you want sound effects

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

// Removed factory Question.fromFirestore as Firebase is no longer used here
}

class SpinnerQuizPage extends StatefulWidget { // Renaming this to QuizPage might be better, but keeping for now
  const SpinnerQuizPage({super.key});

  @override
  State<SpinnerQuizPage> createState() => _SpinnerQuizPageState();
}

class _SpinnerQuizPageState extends State<SpinnerQuizPage> { // Removed SingleTickerProviderStateMixin
  int _score = 0;
  List<Question> _allQuestions = [];
  Question? _currentQuestion;
  String? _selectedAnswer;
  bool _answerSubmitted = false;
  int _currentQuestionIndex = 0; // To track current question for "Next" logic

  Timer? _gameTimer;
  int _timeLeftInSeconds = 10; // Changed to 10 seconds as per HTML mockup timer

  bool _gameEnded = false;
  bool _isLoadingQuestions = true;

  // Confetti controller (keep if you want the effect)
  // late ConfettiController _confettiController;
  // Audio players for sound effects (keep if you want sounds)
  // late AudioPlayer _correctAudioPlayer;
  // late AudioPlayer _incorrectAudioPlayer;

  @override
  void initState() {
    super.initState();
    // _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    // _correctAudioPlayer = AudioPlayer();
    // _incorrectAudioPlayer = AudioPlayer();
    // _loadAudio(); // Uncomment if using audio

    _fetchQuestions();
  }

  // Uncomment and implement if using audio
  // Future<void> _loadAudio() async {
  //   try {
  //     await _correctAudioPlayer.setAsset('assets/audio/correct.mp3');
  //     await _incorrectAudioPlayer.setAsset('assets/audio/incorrect.mp3');
  //   } catch (e) {
  //     print("Error loading audio: $e. Make sure assets are correctly configured.");
  //   }
  // }

  void _startTimer() {
    _timeLeftInSeconds = 10; // Reset timer for each question
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

  // Modified to use hardcoded questions
  Future<void> _fetchQuestions() async {
    setState(() {
      _isLoadingQuestions = true;
      _currentQuestion = null;
      _selectedAnswer = null;
      _answerSubmitted = false;
      _currentQuestionIndex = 0; // Reset question index
      _gameEnded = false; // Ensure game is not marked as ended
    });

    // Simulate fetching questions with a delay
    await Future.delayed(const Duration(seconds: 1));

    _allQuestions = [
      Question(
        questionText: "What is the capital of France?",
        answers: ["London", "Berlin", "Paris", "Rome"],
        correctAnswer: "Paris",
      ),
      Question(
        questionText: "Which planet is known as the Red Planet?",
        answers: ["Earth", "Mars", "Jupiter", "Venus"],
        correctAnswer: "Mars",
      ),
      Question(
        questionText: "What is the largest mammal in the world?",
        answers: ["Elephant", "Blue Whale", "Great White Shark", "Giraffe"],
        correctAnswer: "Blue Whale",
      ),
      Question(
        questionText: "What is the chemical symbol for Gold?",
        answers: ["Au", "Ag", "Fe", "Cu"],
        correctAnswer: "Au",
      ),
    ];

    _allQuestions.shuffle(); // Shuffle all questions once
    _loadNextQuestion(); // Load the first question
    _startTimer();

    setState(() {
      _isLoadingQuestions = false;
    });
  }

  void _loadNextQuestion() {
    _gameTimer?.cancel(); // Stop timer for previous question

    if (_allQuestions.isEmpty) {
      _currentQuestion = Question(
        questionText: "No questions available.",
        answers: [],
        correctAnswer: "",
      );
      return;
    }
    if (_currentQuestionIndex < _allQuestions.length) {
      setState(() {
        _currentQuestion = _allQuestions[_currentQuestionIndex];
        _currentQuestion!.answers.shuffle(); // Shuffle answers for display
        _selectedAnswer = null;
        _answerSubmitted = false;
        _timeLeftInSeconds = 10; // Reset timer for new question
      });
      _currentQuestionIndex++; // Increment for next question
      _startTimer(); // Start timer for new question
    } else {
      // All questions played, end game
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
        print("Time's up! Question skipped.");
        // Optionally penalize for time up or just move on
      } else if (_selectedAnswer == _currentQuestion!.correctAnswer) {
        _score++;
        // _correctAudioPlayer.seek(Duration.zero); // Uncomment for audio
        // _correctAudioPlayer.play(); // Uncomment for audio
        // _confettiController.play(); // Uncomment for confetti
      } else {
        // Only decrement score if an incorrect answer was explicitly selected, not just time up
        if (_selectedAnswer != null) {
          _score--;
        }
        // _incorrectAudioPlayer.seek(Duration.zero); // Uncomment for audio
        // _incorrectAudioPlayer.play(); // Uncomment for audio
      }
    });

    // Move to next question after a short delay to show feedback
    Future.delayed(const Duration(milliseconds: 1500), () {
      _loadNextQuestion();
    });
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
      _timeLeftInSeconds = 10; // Reset timer display
    });
    _gameTimer?.cancel();
    _fetchQuestions();
  }

  void _showGameEndDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.0)),
          title: Text(
            'Game Over!',
            style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold, fontSize: 28),
            textAlign: TextAlign.center,
          ),
          content: Text(
            'Your final score is: $_score points!',
            style: GoogleFonts.poppins(fontSize: 20.0, color: Theme.of(context).colorScheme.onSurface),
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              child: Text('Play Again', style: Theme.of(context).textTheme.labelLarge),
              onPressed: () {
                Navigator.of(context).pop();
                _resetGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // _spinnerController.dispose(); // No longer needed if spinner is removed
    _gameTimer?.cancel();
    // _confettiController.dispose(); // Uncomment if using confetti
    // _correctAudioPlayer.dispose(); // Uncomment if using audio
    // _incorrectAudioPlayer.dispose(); // Uncomment if using audio
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
    final Color textDark = Theme.of(context).colorScheme.onSurface;
    final Color successGreen = const Color(0xFF2ECC71); // Define success green
    final Color errorRed = Theme.of(context).colorScheme.error; // Define error red

    final bool showQuestionContent = _currentQuestion != null && !_isLoadingQuestions;

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow gradient from parent
      appBar: AppBar(
        // The mockup doesn't show an AppBar, so we'll make it transparent/empty
        // or remove it if AppNavigationScreen handles it. For now, let's remove it
        // as the design has top-left user info and top-right question number.
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
              Color(0xFFD8BFD8), // Background gradient start from AppTheme
              Color(0xFFBA55D3), // Background gradient end from AppTheme
            ],
          ),
        ),
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
                margin: const EdgeInsets.all(20.0), // Margin around the main white card
                padding: const EdgeInsets.all(25.0), // Padding inside the main white card
                decoration: BoxDecoration(
                  color: cardWhite,
                  borderRadius: BorderRadius.circular(30.0), // Large border radius for the main card
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
                  mainAxisSize: MainAxisSize.min, // Wrap content
                  children: <Widget>[
                    // Top Row: User Info and Timer (instead of Question Number)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 15.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // User Info
                          Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: accentPink, width: 2), // Pink border
                                  color: textWhite, // White background
                                ),
                                child: Center(
                                  child: Text(
                                    'JP', // Placeholder for user initials
                                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: accentPink),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Hi, PlayerOne!', // Placeholder for user name
                                style: GoogleFonts.poppins(fontSize: 18, color: primaryPurpleDark, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          // Timer Container
                          Container(
                            width: 60, // Smaller timer circle
                            height: 60,
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
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(
                                      value: _timeLeftInSeconds / 10, // Progress from 1.0 to 0.0 for 10 seconds
                                      valueColor: AlwaysStoppedAnimation<Color>(textWhite.withOpacity(0.5)),
                                      backgroundColor: Colors.transparent,
                                      strokeWidth: 4,
                                    ),
                                  ),
                                  Text(
                                    _formatTime(_timeLeftInSeconds),
                                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textWhite),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Question Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(30.0),
                      decoration: BoxDecoration(
                        color: primaryPurpleDark, // Dark purple background
                        borderRadius: BorderRadius.circular(20.0), // Rounded corners
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
                            ? CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(textWhite))
                            : Text(
                          _currentQuestion?.questionText ?? 'Loading Question...',
                          style: GoogleFonts.poppins(fontSize: 22, color: textWhite, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Answer Buttons Grid
                    if (showQuestionContent && _currentQuestion!.answers.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true, // Important for GridView inside Column
                        physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // 2 buttons per row
                          crossAxisSpacing: 15.0, // Horizontal spacing
                          mainAxisSpacing: 15.0, // Vertical spacing
                          childAspectRatio: 2.5, // Adjust aspect ratio for button height
                        ),
                        itemCount: _currentQuestion!.answers.length,
                        itemBuilder: (context, index) {
                          final answer = _currentQuestion!.answers[index];
                          return AnswerButton(
                            answerText: answer,
                            isSelected: _selectedAnswer == answer,
                            isCorrect: _answerSubmitted && answer == _currentQuestion!.correctAnswer,
                            isIncorrect: _answerSubmitted && _selectedAnswer == answer && answer != _currentQuestion!.correctAnswer,
                            onTap: _answerSubmitted || _gameEnded ? null : () => _selectAnswer(answer),
                            primaryPurpleDark: primaryPurpleDark,
                            secondaryPurpleMedium: secondaryPurpleMedium,
                            textWhite: textWhite,
                            successGreen: successGreen,
                            errorRed: errorRed,
                          );
                        },
                      ),
                    const SizedBox(height: 30),

                    // Next Question Button (only appears after answer submitted)
                    if (_answerSubmitted && !_gameEnded)
                      ElevatedButton(
                        onPressed: _loadNextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryPurpleDark, // Dark purple
                          foregroundColor: textWhite,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.15),
                        ),
                        child: Text('Next Question', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    const SizedBox(height: 10), // Small space at bottom
                  ],
                ),
              ),
            ),
            // Confetti overlay (uncomment if using confetti)
            // Align(
            //   alignment: Alignment.topCenter,
            //   child: ConfettiWidget(
            //     confettiController: _confettiController,
            //     blastDirection: pi / 2,
            //     maxBlastForce: 20,
            //     minBlastForce: 8,
            //     emissionFrequency: 0.03,
            //     numberOfParticles: 20,
            //     gravity: 0.3,
            //     colors: [accentPink, successGreen, primaryPurpleDark, textWhite],
            //   ),
            // ),
          ],
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
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10), // Adjusted padding for buttons
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0), // Rounded corners for buttons
          border: Border.all(color: borderColor, width: 2), // Border for buttons
          boxShadow: shadows,
        ),
        child: Center( // Center the text within the button
          child: Text(
            answerText,
            style: GoogleFonts.poppins(
              fontSize: 18,
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
