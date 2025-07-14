// lib/add_remove_questions_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_spinner_quiz_app/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Question {
  final String id;
  final String questionText;
  final List<String> answers;
  final String correctAnswer;

  Question({
    required this.id,
    required this.questionText,
    required this.answers,
    required this.correctAnswer,
  });

  factory Question.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Question(
      id: doc.id,
      questionText: data['questionText'] ?? '',
      answers: List<String>.from(data['options'] ?? []),
      correctAnswer: data['correctAnswer'] ?? '',
    );
  }
}

class AddRemoveQuestionsScreen extends StatefulWidget {
  const AddRemoveQuestionsScreen({super.key});

  @override
  State<AddRemoveQuestionsScreen> createState() => _AddRemoveQuestionsScreenState();
}

class _AddRemoveQuestionsScreenState extends State<AddRemoveQuestionsScreen> {
  final TextEditingController _newQuestionTextController = TextEditingController();
  final TextEditingController _option1Controller = TextEditingController();
  final TextEditingController _option2Controller = TextEditingController();
  final TextEditingController _option3Controller = TextEditingController();
  final TextEditingController _option4Controller = TextEditingController();

  int? _correctOptionIndex;
  final List<Question> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  @override
  void dispose() {
    _newQuestionTextController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    super.dispose();
  }

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

  Future<void> _fetchQuestions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snapshot = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('questions')
          .get();
      setState(() {
        _questions.clear();
        _questions.addAll(snapshot.docs.map((doc) => Question.fromFirestore(doc)));
      });
    }
  }

  void _addNewQuestion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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

    await FirebaseFirestore.instance
        .collection('artifacts')
        .doc('my-trivia-app-id')
        .collection('users')
        .doc(user.uid)
        .collection('questions')
        .add({
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'createdAt': Timestamp.now(),
    });

    _newQuestionTextController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    setState(() {
      _correctOptionIndex = null;
    });

    _showSnackBar('Question added successfully!');
    _fetchQuestions();
  }

  void _editQuestion(Question question) {
    _newQuestionTextController.text = question.questionText;
    _option1Controller.text = question.answers[0];
    _option2Controller.text = question.answers[1];
    _option3Controller.text = question.answers[2];
    _option4Controller.text = question.answers[3];
    setState(() {
      _correctOptionIndex = question.answers.indexOf(question.correctAnswer);
    });

    _showSnackBar('Editing question. Make changes and add again to save.');
  }

  void _removeQuestion(String questionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to remove this question?'),
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
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('artifacts')
                    .doc('my-trivia-app-id')
                    .collection('users')
                    .doc(user.uid)
                    .collection('questions')
                    .doc(questionId)
                    .delete();
                Navigator.of(context).pop();
                _showSnackBar('Question removed!');
                _fetchQuestions();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 700),
      padding: EdgeInsets.all(isMobile ? 20 : 30),
      margin: EdgeInsets.only(bottom: isMobile ? 20 : 30),
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
            textAlign: TextAlign.center,
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
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        toolbarHeight: 0,
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
            Positioned.fill(child: CustomPaint(painter: BackgroundPainter())),
            Positioned.fill(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
                child: Center(
                  child: Column(
                    children: <Widget>[
                      Text(
                        'Manage Questions',
                        style: GoogleFonts.poppins(
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 28 : 36,
                        ),
                      ),
                      SizedBox(height: isMobile ? 20 : 30),
                      _buildSectionCard(
                        context,
                        title: 'Add New Question',
                        children: [
                          Text('Question:', style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                          SizedBox(height: isMobile ? 8 : 10),
                          TextFormField(
                            controller: _newQuestionTextController,
                            decoration: InputDecoration(
                              hintText: 'Enter your question here...',
                              border: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide(color: AppColors.secondaryPurple)),
                              focusedBorder: OutlineInputBorder(borderRadius: AppBorderRadius.small, borderSide: BorderSide(color: AppColors.accentPink, width: 2)),
                              contentPadding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 15, horizontal: 15),
                            ),
                            style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, color: AppColors.textDark),
                          ),
                          SizedBox(height: isMobile ? 15 : 20),
                          Text('Options (select the correct one):', style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.primaryBlue)),
                          SizedBox(height: isMobile ? 8 : 10),
                          _buildOptionField(controller: _option1Controller, optionText: 'Option A', optionIndex: 0, isMobile: isMobile),
                          _buildOptionField(controller: _option2Controller, optionText: 'Option B', optionIndex: 1, isMobile: isMobile),
                          _buildOptionField(controller: _option3Controller, optionText: 'Option C', optionIndex: 2, isMobile: isMobile),
                          _buildOptionField(controller: _option4Controller, optionText: 'Option D', optionIndex: 3, isMobile: isMobile),
                          SizedBox(height: isMobile ? 15 : 20),
                          ElevatedButton(
                            onPressed: _addNewQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentPink,
                              foregroundColor: AppColors.textLight,
                              padding: EdgeInsets.symmetric(horizontal: isMobile ? 25 : 35, vertical: isMobile ? 12 : 15),
                              shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                              elevation: 5,
                              shadowColor: Colors.black.withOpacity(0.15),
                            ),
                            child: Text('Add Question', style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      _buildSectionCard(
                        context,
                        title: 'Your Questions',
                        children: [
                          if (_questions.isEmpty)
                            Text('No questions added yet. Add some above!', style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16, color: AppColors.textDark.withOpacity(0.7)))
                          else
                            ..._questions.map((q) => _buildQuestionItem(context, q, isMobile)).toList(),
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

  Widget _buildQuestionItem(BuildContext context, Question q, bool isMobile) {
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
          Text(q.questionText, style: GoogleFonts.poppins(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.w600, color: AppColors.textLight)),
          SizedBox(height: isMobile ? 5 : 8),
          Text('Correct: ${q.correctAnswer}', style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16, fontStyle: FontStyle.italic, color: AppColors.textLight.withOpacity(0.8))),
          SizedBox(height: isMobile ? 10 : 15),
          Row(
            children: [
              ElevatedButton(
                onPressed: () => _editQuestion(q),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: AppColors.textLight,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 15 : 20, vertical: isMobile ? 8 : 10),
                  shape: RoundedRectangleBorder(borderRadius: AppBorderRadius.small),
                  elevation: 3,
                ),
                child: Text('Edit', style: GoogleFonts.poppins(fontSize: isMobile ? 14 : 16)),
              ),
              SizedBox(width: isMobile ? 10 : 15),
              ElevatedButton(
                onPressed: () => _removeQuestion(q.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
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
