class Flashcard {
  final String title;
  final String content;
  final String type;

  Flashcard({required this.title, required this.content, required this.type});

  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      title: json['title']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      type: json['type']?.toString() ?? 'key_concept',
    );
  }
}
