import 'package:flutter/material.dart';

import 'quiz.dart';

class QuizView extends StatefulWidget {
  final List<QuizQuestion> questions;

  const QuizView({super.key, required this.questions});

  @override
  State<QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<QuizView> {
  int currentQuestion = 0;
  int score = 0;

  String? selectedAnswer;
  bool answered = false;

  void selectAnswer(String answer) {
    if (answered) return;

    final question = widget.questions[currentQuestion];

    setState(() {
      selectedAnswer = answer;
      answered = true;

      if (answer == question.answer) {
        score++;
      }
    });
  }

  void nextQuestion() {
    if (currentQuestion < widget.questions.length - 1) {
      setState(() {
        currentQuestion++;
        selectedAnswer = null;
        answered = false;
      });
    } else {
      showResult();
    }
  }

  void showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Quiz Complete 🎉'),
          content: Text(
            'Your score\n\n$score / ${widget.questions.length}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);

                setState(() {
                  currentQuestion = 0;
                  score = 0;
                  selectedAnswer = null;
                  answered = false;
                });
              },
              child: const Text('Try Again'),
            ),
          ],
        );
      },
    );
  }

  Color optionColor(String option, QuizQuestion question) {
    if (!answered) {
      return Colors.white10;
    }

    if (option == question.answer) {
      return Colors.green.withValues(alpha: 0.25);
    }

    if (option == selectedAnswer) {
      return Colors.red.withValues(alpha: 0.25);
    }

    return Colors.white10;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(child: Text('No quiz questions generated.'));
    }

    final question = widget.questions[currentQuestion];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${currentQuestion + 1}/${widget.questions.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Score: $score',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          Text(
            question.question,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              height: 1.35,
            ),
          ),

          const SizedBox(height: 25),

          ...question.options.map((option) {
            final bool isCorrect = answered && option == question.answer;

            final bool isWrong =
                answered &&
                option == selectedAnswer &&
                option != question.answer;

            return GestureDetector(
              onTap: () => selectAnswer(option),
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: optionColor(option, question),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.green
                        : isWrong
                        ? Colors.red
                        : Colors.white24,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(fontSize: 16, height: 1.3),
                      ),
                    ),

                    if (isCorrect)
                      const Icon(Icons.check_circle, color: Colors.green),

                    if (isWrong) const Icon(Icons.cancel, color: Colors.red),
                  ],
                ),
              ),
            );
          }),

          if (answered) ...[
            const SizedBox(height: 15),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Explanation:\n${question.explanation}',
                style: const TextStyle(fontSize: 15, height: 1.5),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: nextQuestion,
                child: Text(
                  currentQuestion == widget.questions.length - 1
                      ? 'Finish Quiz'
                      : 'Next Question',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
