import 'package:flutter/material.dart';

import 'flashcard.dart';

class FlashcardView extends StatelessWidget {
  final List<Flashcard> flashcards;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const FlashcardView({
    super.key,
    required this.flashcards,
    required this.currentIndex,
    required this.onNext,
    required this.onPrevious,
  });

  Color getTypeColor(String type) {
    switch (type) {
      case 'definition':
        return const Color(0xFF5B8DEF);

      case 'formula':
        return const Color(0xFFE5A33D);

      case 'comparison':
        return const Color(0xFF9B72CF);

      case 'process':
        return const Color(0xFF55A879);

      default:
        return const Color(0xFFE27D60);
    }
  }

  String getTypeText(String type) {
    switch (type) {
      case 'definition':
        return 'DEFINITION';

      case 'formula':
        return 'FORMULA';

      case 'comparison':
        return 'COMPARISON';

      case 'process':
        return 'PROCESS';

      default:
        return 'KEY CONCEPT';
    }
  }

  List<InlineSpan> buildContent(String content) {
    final lines = content.split('\n');
    final List<InlineSpan> spans = [];

    for (final line in lines) {
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      final lower = trimmed.toLowerCase();

      if (lower.startsWith('definition:') ||
          lower.startsWith('formula:') ||
          lower.startsWith('concept:') ||
          lower.startsWith('steps:') ||
          lower.startsWith('remember:') ||
          lower.startsWith('important points:') ||
          lower.startsWith('main difference:') ||
          lower.startsWith('meaning:')) {
        spans.add(
          TextSpan(
            text: '$trimmed\n',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF303030),
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$trimmed\n',
            style: const TextStyle(
              fontSize: 17,
              height: 1.45,
              color: Color(0xFF303030),
            ),
          ),
        );
      }
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    if (flashcards.isEmpty) {
      return const Center(child: Text('No flashcards generated.'));
    }

    final card = flashcards[currentIndex];
    final typeColor = getTypeColor(card.type);

    return Column(
      children: [
        // Progress
        Row(
          children: List.generate(flashcards.length, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: index == currentIndex
                      ? Colors.tealAccent
                      : Colors.grey.shade700,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 12),

        // Card
        Expanded(
          child: GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity == null) return;

              if (details.primaryVelocity! < 0) {
                onNext();
              } else if (details.primaryVelocity! > 0) {
                onPrevious();
              }
            },
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD8D0B8), width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 12,
                    offset: Offset(0, 5),
                    color: Color(0x40000000),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Notebook lines
                  Positioned.fill(
                    child: CustomPaint(painter: NotebookLinesPainter()),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Type
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                getTypeText(card.type),
                                style: TextStyle(
                                  color: typeColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Title
                        Text(
                          card.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF202020),
                          ),
                        ),

                        Container(
                          width: 100,
                          height: 4,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: typeColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Content
                        Expanded(
                          child: SingleChildScrollView(
                            child: RichText(
                              text: TextSpan(
                                children: buildContent(card.content),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Bottom navigation
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: currentIndex > 0 ? onPrevious : null,
                              icon: const Icon(Icons.arrow_back_ios_new),
                              color: Colors.black87,
                            ),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFE9D8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${currentIndex + 1} / ${flashcards.length}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                ),
                              ),
                            ),

                            IconButton(
                              onPressed: currentIndex < flashcards.length - 1
                                  ? onNext
                                  : null,
                              icon: const Icon(Icons.arrow_forward_ios),
                              color: Colors.black87,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class NotebookLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E0D2)
      ..strokeWidth = 1;

    const double spacing = 34;

    for (double y = 100; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
