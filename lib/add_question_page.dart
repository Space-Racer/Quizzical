// lib/add_remove_questions_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_spinner_quiz_app/app_theme.dart'; // Import app theme for colors

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

// Re-using the Question model from quiz_game.dart
class Question {
  final String questionText;
  final List<String> answers;
  final String correctAnswer;

  Question({
    required this.questionText,
    required this.answers,
    required this.correctAnswer,
  });
}

class AddRemoveQuestionsScreen extends StatefulWidget {
  const AddRemoveQuestionsScreen({super.key});

  @override
  State<AddRemoveQuestionsScreen> createState() => _AddRemoveQuestionsScreenState();
}

class _AddRemoveQuestionsScreenState extends State<AddRemoveQuestionsScreen> {
  // Controllers for the add question form
  final TextEditingController _newQuestionTextController = TextEditingController();
  final TextEditingController _option1Controller = TextEditingController();
  final TextEditingController _option2Controller = TextEditingController();
  final TextEditingController _option3Controller = TextEditingController();
  final TextEditingController _option4Controller = TextEditingController();

  // To track which option is selected as correct (0-indexed)
  int? _correctOptionIndex;

  // Hardcoded list of questions for demonstration
  final List<Question> _questions = [
    Question(
      questionText: "What is the largest ocean on Earth?",
      answers: ["Atlantic Ocean", "Indian Ocean", "Arctic Ocean", "Pacific Ocean"],
      correctAnswer: "Pacific Ocean",
    ),
    Question(
      questionText: "Who wrote \"Romeo and Juliet\"?",
      answers: ["Charles Dickens", "William Shakespeare", "Jane Austen", "Mark Twain"],
      correctAnswer: "William Shakespeare",
    ),
    Question(
      questionText: "What is the chemical symbol for water?",
      answers: ["O2", "H2O", "CO2", "NaCl"],
      correctAnswer: "H2O",
    ),
  ];

  @override
  void dispose() {
    _newQuestionTextController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
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

  // Logic to add a new question
  void _addNewQuestion() {
    final String questionText = _newQuestionTextController.text.trim();
    final List<String> options = [
      _option1Controller.text.trim(),
      _option2Controller.text.trim(),
      _option3Controller.text.trim(),
      _option4Controller.text.trim(),
    ];

    if (questionText.isEmpty || options.any((opt) => opt.isEmpty) || _correctOptionIndex == null) {
      _showSnackBar('Please fill in all fields and select the correct answer.', isError: true);
      return;
    }

    final String correctAnswer = options[_correctOptionIndex!];

    setState(() {
      _questions.add(Question(
        questionText: questionText,
        answers: options,
        correctAnswer: correctAnswer,
      ));
      // Clear form fields
      _newQuestionTextController.clear();
      _option1Controller.clear();
      _option2Controller.clear();
      _option3Controller.clear();
      _option4Controller.clear();
      _correctOptionIndex = null; // Clear radio selection
    });

    _showSnackBar('Question added successfully!');
    // In a real app, you would save this to Firestore
  }

  // Logic to edit a question (simulated)
  void _editQuestion(int index) {
    _showSnackBar('Simulating edit for question: "${_questions[index].questionText}"');
    // In a real app, you would navigate to a form pre-filled with this question's data
  }

  // Logic to remove a question
  void _removeQuestion(int index) {
    // Show a confirmation dialog instead of alert()
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to remove "${_questions[index].questionText}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Remove', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
              onPressed: () {
                setState(() {
                  _questions.removeAt(index);
                });
                Navigator.of(context).pop();
                _showSnackBar('Question removed!');
                // In a real app, delete from Firestore
              },
            ),
          ],
        );
      },
    );
  }

  // Helper method to build a consistent section card
  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 700), // Max width for these cards
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      margin: EdgeInsets.only(bottom: isMobile ? 20 : 30), // Margin at bottom
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
            // BackgroundPainter for the subtle circles
            Positioned.fill(
              child: CustomPaint(
                painter: BackgroundPainter(),
              ),
            ),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 15.0 : 30.0), // Responsive padding
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'Manage Questions',
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 28 : 36,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isMobile ? 20 : 30),

                      // Add New Question Form
                      _buildSectionCard(
                        context,
                        title: 'Add New Question',
                        children: [
                          Text(
                            'Question:',
                            style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                          ),
                          SizedBox(height: isMobile ? 8 : 10),
                          TextFormField(
                            controller: _newQuestionTextController,
                            decoration: InputDecoration(
                              hintText: 'Enter your question here...',
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
                          Text(
                            'Options (select the correct one):',
                            style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.primaryBlue),
                          ),
                          SizedBox(height: isMobile ? 8 : 10),
                          // Option 1
                          _buildOptionField(
                              controller: _option1Controller,
                              optionText: 'Option A',
                              optionIndex: 0,
                              isMobile: isMobile),
                          // Option 2
                          _buildOptionField(
                              controller: _option2Controller,
                              optionText: 'Option B',
                              optionIndex: 1,
                              isMobile: isMobile),
                          // Option 3
                          _buildOptionField(
                              controller: _option3Controller,
                              optionText: 'Option C',
                              optionIndex: 2,
                              isMobile: isMobile),
                          // Option 4
                          _buildOptionField(
                              controller: _option4Controller,
                              optionText: 'Option D',
                              optionIndex: 3,
                              isMobile: isMobile),
                          SizedBox(height: isMobile ? 15 : 20),
                          ElevatedButton(
                            onPressed: _addNewQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPink, // Pink for add button
                              foregroundColor: AppColors.textLight,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 25 : 35, vertical: isMobile ? 12 : 15),
                              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                              elevation: 5,
                              shadowColor: Colors.black.withOpacity(0.15),
                            ),
                            child: Text(
                              'Add Question',
                              style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),

                      // Your Questions List
                      _buildSectionCard(
                        context,
                        title: 'Your Questions',
                        children: [
                          if (_questions.isEmpty)
                            Text(
                              'No questions added yet. Add some above!',
                              style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16, color: AppColors.textDark.withOpacity(0.7)),
                            )
                          else
                            ..._questions.asMap().entries.map((entry) {
                              int index = entry.key;
                              Question q = entry.value;
                              return _buildQuestionItem(context, q, index, isMobile);
                            }).toList(),
                        ],
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

  // Helper to build an option field with a radio button
  Widget _buildOptionField({
    required TextEditingController controller,
    required String optionText,
    required int optionIndex,
    required bool isMobile,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 10 : 15),
      child: Row(
        children: [
          Radio<int>(
            value: optionIndex,
            groupValue: _correctOptionIndex,
            onChanged: (int? value) {
              setState(() {
                _correctOptionIndex = value;
              });
            },
            activeColor: AppColors.primaryBlue,
          ),
          SizedBox(width: isMobile ? 5 : 10),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: optionText,
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
          ),
        ],
      ),
    );
  }

  // Helper to build a single question item in the list
  Widget _buildQuestionItem(BuildContext context, Question q, int index, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 15 : 20),
      margin: EdgeInsets.only(bottom: isMobile ? 10 : 15),
      decoration: BoxDecoration(
        color: AppColors.secondaryPurple,
        borderRadius: AppBorderRadius.small,
        boxShadow: AppShadows.light,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.questionText,
            style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.textLight),
          ),
          SizedBox(height: isMobile ? 5 : 8),
          Text(
            'Correct: ${q.correctAnswer}',
            style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16, fontStyle: FontStyle.italic, color: AppColors.textLight.withOpacity(0.8)),
          ),
          SizedBox(height: isMobile ? 10 : 15),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _editQuestion(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue, // Amber for edit
                  foregroundColor: AppColors.textLight,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 15 : 20, vertical: isMobile ? 8 : 10),
                  shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                  elevation: 3,
                ),
                child: Text('Edit', style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16)),
              ),
              SizedBox(width: isMobile ? 10 : 15),
              ElevatedButton(
                onPressed: () => _removeQuestion(index),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed, // Red for remove
                  foregroundColor: AppColors.textLight,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 15 : 20, vertical: isMobile ? 8 : 10),
                  shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                  elevation: 3,
                ),
                child: Text('Remove', style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
