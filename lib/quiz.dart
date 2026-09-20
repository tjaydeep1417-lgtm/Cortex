class QuizQuestion {
  final String question;
  final List<String> options;
  final String answer;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answer,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      answer: json['answer']?.toString() ?? '',
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}
