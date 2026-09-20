import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'ai_service.dart';
import 'camera.dart';
import 'flashcard.dart';
import 'view.dart';
import 'ocr.dart';
import 'quiz.dart';
import 'qview.dart';

class SmartScreen extends StatefulWidget {
  const SmartScreen({super.key});

  @override
  State<SmartScreen> createState() => _SmartScreenState();
}

class _SmartScreenState extends State<SmartScreen>
    with SingleTickerProviderStateMixin {
  String extractedText = '';

  List<Flashcard> flashcards = [];
  List<QuizQuestion> quizQuestions = [];

  String summary = '';

  bool isProcessing = false;
  bool isSummaryLoading = false;
  bool isQuizLoading = false;

  int currentCardIndex = 0;

  late TabController tabController;

  @override
  void initState() {
    super.initState();

    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  // ============================================================
  // SCAN NOTES
  // ============================================================

  Future<void> scanNotes() async {
    setState(() {
      isProcessing = true;
      extractedText = '';
      flashcards = [];
      quizQuestions = [];
      summary = '';
      currentCardIndex = 0;
    });

    final XFile? image = await openCamera();

    if (image == null) {
      setState(() {
        isProcessing = false;
      });
      return;
    }

    // OCR
    final text = await OCRService.extractText(image.path);

    setState(() {
      extractedText = text;
    });

    if (text.isEmpty ||
        text.startsWith('OCR Error') ||
        text.startsWith('Could not') ||
        text.startsWith('No OCR')) {
      setState(() {
        isProcessing = false;
      });
      return;
    }

    // FlashCards
    try {
      final result = await AIService.generateFlashcards(text);

      setState(() {
        flashcards = result;
        currentCardIndex = 0;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Flashcard generation failed: $e')),
      );
    }
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Future<void> generateSummary() async {
    if (extractedText.isEmpty || isSummaryLoading) return;

    setState(() {
      isSummaryLoading = true;
    });

    try {
      final result = await AIService.generateSummary(extractedText);

      if (!mounted) return;

      setState(() {
        summary = result;
        isSummaryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSummaryLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Summary generation failed: $e')));
    }
  }

  // ============================================================
  // QUIZ
  // ============================================================

  Future<void> generateQuiz() async {
    if (extractedText.isEmpty || isQuizLoading) return;

    setState(() {
      isQuizLoading = true;
    });

    try {
      final result = await AIService.generateQuiz(extractedText);

      if (!mounted) return;

      setState(() {
        quizQuestions = result;
        isQuizLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isQuizLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Quiz generation failed: $e')));
    }
  }

  // ============================================================
  // SUMMARY UI
  // ============================================================

  Widget buildSummaryTab() {
    if (isSummaryLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Generating  your summary...', style: TextStyle(fontSize: 17)),
          ],
        ),
      );
    }

    if (summary.isEmpty) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: generateSummary,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate Summary'),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2930),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          summary,
          style: const TextStyle(fontSize: 17, height: 1.55),
        ),
      ),
    );
  }

  // ============================================================
  // QUIZ UI
  // ============================================================

  Widget buildQuizTab() {
    if (isQuizLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('''Generating your quiz...
              Get Ready!..''', style: TextStyle(fontSize: 17)),
          ],
        ),
      );
    }

    if (quizQuestions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined, size: 65),

              const SizedBox(height: 20),

              const Text(
                'Test Your Knowledge',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                'Gemini will create an interactive quiz from your scanned notes.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 25),

              ElevatedButton.icon(
                onPressed: generateQuiz,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Generate Quiz'),
              ),
            ],
          ),
        ),
      );
    }

    return QuizView(questions: quizQuestions);
  }

  // ============================================================
  // HOME
  // ============================================================

  Widget buildHome() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories, size: 70, color: Colors.tealAccent),

          SizedBox(height: 20),

          Text(
            'Hello Jaydeep!',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10),

          Text(
            'Scan your notes to start studying.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,

        title: Row(
          children: const [
            Icon(Icons.book),

            SizedBox(width: 10),

            Text(
              'Cortex',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
          ],
        ),
      ),

      // ========================================================
      // CAMERA
      // ========================================================
      floatingActionButton: FloatingActionButton(
        onPressed: scanNotes,
        shape: const CircleBorder(),
        child: const Icon(Icons.camera_alt, size: 30),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ========================================================
      // BOTTOM NAV
      // ========================================================
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,

        child: SizedBox(
          height: 65,

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,

            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.home)),

              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.calendar_month),
              ),

              const SizedBox(width: 50),

              IconButton(onPressed: () {}, icon: const Icon(Icons.menu_book)),

              IconButton(onPressed: () {}, icon: const Icon(Icons.person)),
            ],
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================
      body: isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),

                  SizedBox(height: 20),

                  Text(
                    'Creating your study material...',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            )
          : extractedText.isEmpty
          ? buildHome()
          : Column(
              children: [
                // ==================================================
                // SCROLLABLE TABS
                // ==================================================

                Material(
                  color: Theme.of(context).scaffoldBackgroundColor,

                  child: TabBar(
                    controller: tabController,

                    isScrollable: true,

                    tabAlignment: TabAlignment.start,

                    labelColor: Colors.tealAccent,

                    unselectedLabelColor: Colors.grey,

                    indicatorSize: TabBarIndicatorSize.label,

                    tabs: const [
                      Tab(text: 'FlashCards'),
                      Tab(text: 'Summary'),
                      Tab(text: 'Assignment / Quiz'),
                    ],
                  ),
                ),

                // ==================================================
                // TAB CONTENT
                // ==================================================
                Expanded(
                  child: TabBarView(
                    controller: tabController,

                    children: [
                      // FLASHCARDS
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: FlashcardView(
                          flashcards: flashcards,
                          currentIndex: currentCardIndex,

                          onNext: () {
                            if (currentCardIndex < flashcards.length - 1) {
                              setState(() {
                                currentCardIndex++;
                              });
                            }
                          },

                          onPrevious: () {
                            if (currentCardIndex > 0) {
                              setState(() {
                                currentCardIndex--;
                              });
                            }
                          },
                        ),
                      ),

                      // SUMMARY
                      buildSummaryTab(),

                      // QUIZ
                      buildQuizTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
