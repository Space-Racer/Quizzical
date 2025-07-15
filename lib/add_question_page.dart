// lib/add_question_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quizzical/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddRemoveQuestionsScreen extends StatefulWidget {
  final bool isFlashcard;
  final String? setId;

  const AddRemoveQuestionsScreen(
      {super.key, required this.isFlashcard, this.setId});

  @override
  State<AddRemoveQuestionsScreen> createState() =>
      _AddRemoveQuestionsScreenState();
}

class _AddRemoveQuestionsScreenState extends State<AddRemoveQuestionsScreen> {
  final TextEditingController _setNameController = TextEditingController();
  final TextEditingController _questionTextController = TextEditingController();
  final TextEditingController _option1Controller = TextEditingController();
  final TextEditingController _option2Controller = TextEditingController();
  final TextEditingController _option3Controller = TextEditingController();
  final TextEditingController _option4Controller = TextEditingController();
  final TextEditingController _frontController = TextEditingController();
  final TextEditingController _backController = TextEditingController();

  int? _correctOptionIndex;
  String? _currentSetId;
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _currentSetId = widget.setId;
    if (_currentSetId != null) {
      _fetchQuestions();
    }
  }

  @override
  void dispose() {
    _setNameController.dispose();
    _questionTextController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    _frontController.dispose();
    _backController.dispose();
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

  Future<void> _createOrUpdateSet() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final setName = _setNameController.text.trim();
    if (setName.isEmpty) {
      _showSnackBar('Please enter a name for the set.', isError: true);
      return;
    }

    if (_currentSetId == null) {
      final newSet = await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('question_sets')
          .add({
        'setName': setName,
        'setType': widget.isFlashcard ? 'Flashcards' : 'Multiple Choice',
        'createdAt': Timestamp.now(),
      });
      setState(() {
        _currentSetId = newSet.id;
      });
      _showSnackBar('Set created! Now add questions.');
    } else {
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('question_sets')
          .doc(_currentSetId)
          .update({'setName': setName});
      _showSnackBar('Set name updated!');
    }
  }

  Future<void> _fetchQuestions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentSetId == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('artifacts')
        .doc('my-trivia-app-id')
        .collection('users')
        .doc(user.uid)
        .collection('question_sets')
        .doc(_currentSetId)
        .collection('questions')
        .get();

    setState(() {
      // Store the document ID with the question data
      _questions = snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    });
  }

  void _addQuestion() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar('Please log in to add questions.', isError: true);
      return;
    }

    if (_currentSetId == null) {
      await _createOrUpdateSet();
    }

    if (_currentSetId == null) {
      return;
    }

    if (widget.isFlashcard) {
      final front = _frontController.text.trim();
      final back = _backController.text.trim();

      if (front.isEmpty || back.isEmpty) {
        _showSnackBar('Please fill in both the front and back of the flashcard.',
            isError: true);
        return;
      }

      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('question_sets')
          .doc(_currentSetId)
          .collection('questions')
          .add({
        'front': front,
        'back': back,
      });

      _frontController.clear();
      _backController.clear();
    } else {
      final questionText = _questionTextController.text.trim();
      final options = [
        _option1Controller.text.trim(),
        _option2Controller.text.trim(),
        _option3Controller.text.trim(),
        _option4Controller.text.trim(),
      ];

      if (questionText.isEmpty ||
          options.any((opt) => opt.isEmpty) ||
          _correctOptionIndex == null) {
        _showSnackBar(
            'Please fill in all fields and select the correct answer.',
            isError: true);
        return;
      }

      final correctAnswer = options[_correctOptionIndex!];

      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('question_sets')
          .doc(_currentSetId)
          .collection('questions')
          .add({
        'questionText': questionText,
        'options': options,
        'correctAnswer': correctAnswer,
      });

      _questionTextController.clear();
      _option1Controller.clear();
      _option2Controller.clear();
      _option3Controller.clear();
      _option4Controller.clear();
      setState(() {
        _correctOptionIndex = null;
      });
    }

    _showSnackBar('Question added successfully!');
    _fetchQuestions(); // Refresh the list of questions
  }

  // --- Add the _editQuestion method here ---
  void _editQuestion(Map<String, dynamic> question) {
    // You'll need to implement the logic to pre-fill the form with
    // the question data and allow the user to modify it.
    // For example, you might open a dialog or navigate to a new screen.
    // After editing, you would call Firebase to update the question.
    _showSnackBar('Edit functionality not yet implemented for this question.');
    print('Attempting to edit question: $question');
    // Example: if you want to set the text fields for editing
    if (widget.isFlashcard) {
      _frontController.text = question['front'];
      _backController.text = question['back'];
    } else {
      _questionTextController.text = question['questionText'];
      _option1Controller.text = question['options'][0];
      _option2Controller.text = question['options'][1];
      _option3Controller.text = question['options'][2];
      _option4Controller.text = question['options'][3];
      // Find the index of the correct answer from options and set _correctOptionIndex
      final List<dynamic> options = question['options'];
      final String correctAnswer = question['correctAnswer'];
      setState(() {
        _correctOptionIndex = options.indexOf(correctAnswer);
      });
    }
  }

  // --- Add the _deleteQuestion method here ---
  Future<void> _deleteQuestion(String? questionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _currentSetId == null || questionId == null) {
      _showSnackBar('Could not delete question. Missing information.', isError: true);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('artifacts')
          .doc('my-trivia-app-id')
          .collection('users')
          .doc(user.uid)
          .collection('question_sets')
          .doc(_currentSetId)
          .collection('questions')
          .doc(questionId)
          .delete();

      _showSnackBar('Question deleted successfully!');
      _fetchQuestions(); // Refresh the list after deletion
    } catch (e) {
      _showSnackBar('Error deleting question: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          widget.setId == null ? 'Create New Set' : 'Edit Set',
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
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 15.0 : 30.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildSectionCard(
                  context,
                  title: 'Set Details',
                  children: [
                    TextFormField(
                      controller: _setNameController,
                      decoration: InputDecoration(
                        labelText: 'Set Name',
                        hintText: 'e.g., European Capitals',
                        border: OutlineInputBorder(
                          borderRadius: AppBorderRadius.small,
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 15 : 20),
                    ElevatedButton(
                      onPressed: _createOrUpdateSet,
                      child: Text(_currentSetId == null
                          ? 'Create Set'
                          : 'Update Set Name'),
                    ),
                  ],
                ),
                _buildSectionCard(
                  context,
                  title: widget.isFlashcard ? 'Create New Flashcard' : 'Add a New Question', // Conditional title
                  children: widget.isFlashcard
                      ? _buildFlashcardForm(isMobile)
                      : _buildMultipleChoiceForm(isMobile),
                ),
                if (_questions.isNotEmpty)
                  _buildSectionCard(
                    context,
                    title: widget.isFlashcard ? 'Flashcards in this Set' : 'Questions in this Set', // Conditional title
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _questions.length,
                        itemBuilder: (context, index) {
                          final question = _questions[index];
                          return Card(
                            // Enhanced styling for the question tiles
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15), // Slightly more rounded corners
                              side: const BorderSide(
                                color: AppColors.secondaryPurple, // Subtle border color
                                width: 1.5, // Slightly thicker border
                              ),
                            ),
                            elevation: 8, // Increased elevation for more distinct shadow
                            color: AppColors.cardBackground, // Keep background consistent, rely on border/shadow
                            child: Padding(
                              padding: const EdgeInsets.all(12.0), // Add internal padding
                              child: ListTile(
                                title: Text(
                                  widget.isFlashcard
                                      ? question['front'] ?? 'No front text'
                                      : question['questionText'] ?? 'No question text',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600, // Make title bolder
                                    color: AppColors.primaryBlue, // Primary text color
                                    fontSize: isMobile ? 16 : 18, // Responsive font size
                                  ),
                                ),
                                subtitle: Text(
                                  widget.isFlashcard
                                      ? question['back'] ?? 'No back text'
                                      : 'Correct: ${question['correctAnswer'] ?? 'N/A'}',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textDark.withOpacity(0.8), // Slightly darker subtitle
                                    fontSize: isMobile ? 12 : 14, // Responsive font size
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.primaryBlue), // Consistent icon color
                                      onPressed: () {
                                        _editQuestion(question);
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.accentRed), // Consistent icon color
                                      onPressed: () {
                                        _deleteQuestion(question['id'] as String?);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFlashcardForm(bool isMobile) {
    return [
      TextFormField(
        controller: _frontController,
        decoration: const InputDecoration(labelText: 'Front of Card'),
      ),
      SizedBox(height: isMobile ? 15 : 20),
      TextFormField(
        controller: _backController,
        decoration: const InputDecoration(labelText: 'Back of Card'),
      ),
      SizedBox(height: isMobile ? 15 : 20),
      ElevatedButton(
        onPressed: _addQuestion,
        child: const Text('Add Flashcard'),
      ),
    ];
  }

  List<Widget> _buildMultipleChoiceForm(bool isMobile) {
    return [
      TextFormField(
        controller: _questionTextController,
        decoration: const InputDecoration(labelText: 'Question'),
      ),
      SizedBox(height: isMobile ? 15 : 20),
      ...List.generate(4, (index) {
        final controllers = [
          _option1Controller,
          _option2Controller,
          _option3Controller,
          _option4Controller
        ];
        return _buildOptionField(
          controller: controllers[index],
          optionText: 'Option ${index + 1}',
          optionIndex: index,
          isMobile: isMobile,
        );
      }),
      SizedBox(height: isMobile ? 15 : 20),
      ElevatedButton(
        onPressed: _addQuestion,
        child: const Text('Add Multiple Choice Question'),
      ),
    ];
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
                  borderSide:
                  const BorderSide(color: AppColors.secondaryPurple),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppBorderRadius.small,
                  borderSide:
                  const BorderSide(color: AppColors.accentPink, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                    vertical: isMobile ? 12 : 15, horizontal: 15),
              ),
              style: GoogleFonts.poppins(
                  fontSize: isMobile ? 16 : 18, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context,
      {required String title, required List<Widget> children}) {
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
}
