import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../api/ApiConfig.dart';
import '../../provider/student_provider.dart';
import '../../alerts/custom_alerts.dart';
import '../../alerts/custom_alerts.dart';

class McqsAttemptScreen extends StatefulWidget {
  final dynamic task;
  const McqsAttemptScreen({Key? key, required this.task}) : super(key: key);

  @override
  State<McqsAttemptScreen> createState() => _McqsAttemptScreenState();
}

class _McqsAttemptScreenState extends State<McqsAttemptScreen> {
  late List<Map<String, dynamic>> questions;
  Map<String, String?> selectedAnswers = {};
  int currentQuestionIndex = 0;
  bool _isSubmitting = false;
  bool _showResults = false;
  Map<String, dynamic>? _quizResults;
  Map<String, dynamic> sourceAnswers = {
  };
  // Theme Colors
  static const Color primaryColor = Color(0xFF4361EE);
  static const Color secondaryColor = Color(0xFF3A0CA3);
  static const Color accentColor = Color(0xFF7209B7);
  static const Color successColor = Color(0xFF4CC9F0);
  static const Color errorColor = Color(0xFFF94144);
  static const Color surfaceColor = Color(0xFFF8F9FA);
  static const Color onSurfaceColor = Color(0xFF212529);

  @override
  void initState() {
    super.initState();
    try {
      questions = (widget.task['MCQS'] as List?)?.map((q) {
        return (q as Map?)?.cast<String, dynamic>() ?? {};
      }).toList() ?? [];
    } catch (e) {
      questions = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.task['title']?.toString() ?? 'MCQ Quiz',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Quiz info header
          _buildQuizHeader(),
          Expanded(
            child: _showResults
                ? _buildResultsScreen()
                : _buildQuestionScreen(),
          ),
        ],
      ),
      bottomNavigationBar: _showResults ? null : _buildBottomNavBar(),
    );
  }

  Widget _buildQuizHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: primaryColor.withOpacity(0.3)),
            ),
            child: Text(
              widget.task['type']?.toString() ?? 'MCQS',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task['course_name']?.toString() ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Due: ${_formatDateTime(widget.task['due_date']?.toString())}',
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurfaceColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Chip(
            label: Text(
              '${widget.task['points']?.toString() ?? '0'} pts',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
            backgroundColor: primaryColor,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionScreen() {
    if (questions.isEmpty) {
      return Center(
        child: Text(
          'No questions available',
          style: TextStyle(color: onSurfaceColor.withOpacity(0.6)),
        ),
      );
    }

    final question = questions[currentQuestionIndex];
    final questionId = question['ID']?.toString() ?? 'q${currentQuestionIndex}';
    final questionText = question['Question']?.toString() ?? 'Question';
    final options = _getQuestionOptions(question);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(
            value: (currentQuestionIndex + 1) / questions.length,
            backgroundColor: Colors.grey.shade200,
            color: primaryColor,
            minHeight: 6,
          ),
          const SizedBox(height: 20),
          Text(
            'Question ${currentQuestionIndex + 1} of ${questions.length}',
            style: TextStyle(
              color: onSurfaceColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            questionText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() {
                      selectedAnswers[questionId] = option;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selectedAnswers[questionId] == option
                            ? primaryColor
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selectedAnswers[questionId] == option
                                  ? primaryColor
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: selectedAnswers[questionId] == option
                              ? Icon(
                            Icons.circle,
                            size: 12,
                            color: primaryColor,
                          )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<String> _getQuestionOptions(Map<String, dynamic> question) {
    final options = <String>[];
    for (var i = 1; i <= 4; i++) {
      final option = question['Option $i']?.toString();
      if (option != null && option.isNotEmpty) {
        options.add(option);
      }
    }
    return options;
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          if (currentQuestionIndex > 0)
            OutlinedButton(
              onPressed: () => setState(() => currentQuestionIndex--),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryColor),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Previous'),
            ),
          const Spacer(),
          if (currentQuestionIndex < questions.length - 1)
            ElevatedButton(
              onPressed: () {
                final questionId = questions[currentQuestionIndex]['ID']?.toString() ?? 'q$currentQuestionIndex';
                if (selectedAnswers[questionId] == null) {
                  CustomAlert.warning(context, 'Please select an answer');
                  return;
                }
                setState(() => currentQuestionIndex++);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Next'),
            ),
          if (currentQuestionIndex == questions.length - 1)
            ElevatedButton(
              onPressed: _submitQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text('Submit Quiz'),
            ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    if (_quizResults == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalMarks = widget.task['points'] ?? 0;
    final obtainedMarks = _quizResults!['Obtained Marks'] ?? 0;
    final userSubmissions = _quizResults!['Your Submissions'] as List? ?? [];
// Convert submissions to a map with QNo as key for easier lookup
    final userAnswers = {
      for (var submission in userSubmissions)
        'Q${submission['QNo']}': submission['StudentAnswer']
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'Quiz Results',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: successColor.withOpacity(0.1),
              border: Border.all(color: successColor, width: 2),
            ),
            child: Text(
              '$obtainedMarks/$totalMarks',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: successColor,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            obtainedMarks >= totalMarks * 0.7
                ? 'Excellent Work! 🎉'
                : obtainedMarks >= totalMarks * 0.5
                ? 'Good Job! 👍'
                : 'Keep Practicing! 💪',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: onSurfaceColor,
            ),
          ),
          const SizedBox(height: 30),
          const Text(
            'Question Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: questions.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final question = questions[index];
              final questionId = question['ID']?.toString() ?? 'q$index';
              final questionNo = question['Question NO'] ?? index + 1;
              final correctAnswer = question['Answer']?.toString() ?? '';

              final userAnswer = userAnswers['Q$questionNo'] ?? 'Not answered';
              final isCorrect = userAnswer.toString() == correctAnswer;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCorrect ? successColor : errorColor,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Q$questionNo: ${question['Question']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          isCorrect ? Icons.check_circle : Icons.cancel,
                          color: isCorrect ? successColor : errorColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCorrect ? 'Correct' : 'Incorrect',
                          style: TextStyle(
                            color: isCorrect ? successColor : errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${question['Points'] ?? 0} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your answer: ${userAnswer.toString()}',
                      style: TextStyle(
                        color: isCorrect ? successColor : errorColor,
                      ),
                    ),
                    Text(
                      'Correct answer: $correctAnswer',
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Back to Tasks'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitQuiz() async {
    final confirmed = await CustomAlert.confirm(
        context,
        'Are you sure you want to submit this quiz?'
    );
    if (!confirmed) return;

    setState(() => _isSubmitting = true);

    try {
      final studentProvider = Provider.of<StudentProvider>(context, listen: false);
      final studentId = studentProvider.student?.id;
      if (studentId == null) throw Exception('Student ID not found');

      final taskId = widget.task['task_id'];
      if (taskId == null) throw Exception('Task ID not found');

      // Prepare answers in correct format
      final answers = selectedAnswers.entries.map((entry) {
        return {
          'QNo': _getQuestionNumber(entry.key) ?? 0,
          'StudentAnswer': entry.value ?? '',
        };
      }).toList();

      final response = await http.post(
        Uri.parse('${ApiConfig.apiBaseUrl}Students/submit-quiz'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentId,
          'task_id': taskId,
          'Answer': answers,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _quizResults = Map<String, dynamic>.from(responseData);
          _showResults = true;
        });
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?.toString() ?? 'Submission failed');
      }
    } catch (e) {
      CustomAlert.error(context, 'Submission Error', e.toString());
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  int? _getQuestionNumber(String questionId) {
    try {
      for (var i = 0; i < questions.length; i++) {
        if (questions[i]['ID']?.toString() == questionId) {
          return questions[i]['Question NO'] ?? (i + 1);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null || dateTime.isEmpty) return 'N/A';
    try {
      return DateFormat('MMM d, y • h:mm a').format(DateTime.parse(dateTime));
    } catch (e) {
      return dateTime;
    }
  }
}