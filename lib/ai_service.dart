import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';

import 'flashcard.dart';
import 'quiz.dart';

class AIService {
  // IMPORTANT:
  // Put your NEW / ROTATED Gemini API key here.
  static const String apiKey = 'API- Key';

  static GenerativeModel get model {
    return GenerativeModel(model: 'gemini-3.1-flash-lite', apiKey: apiKey);
  }

  // flashcards

  static Future<List<Flashcard>> generateFlashcards(String text) async {
    try {
      final prompt =
          '''
You are SmartStudy, an AI study-material generator for engineering students.

Convert the student's notes into clear, useful handwritten-note-style study cards.

IMPORTANT:
- Return ONLY a JSON array.
- Do NOT return Markdown.
- Do NOT return questions.
- Do NOT return answers.
- Do NOT return a summary.
- Do NOT return the original notes.
- Do NOT add unrelated information.
- Use ONLY information supported by the student's notes.

Each card MUST contain exactly:
"title"
"content"
"type"

The type MUST be one of:
"definition"
"formula"
"key_concept"
"comparison"
"process"

NUMBER OF CARDS:
- Do NOT use a fixed number.
- Generate cards according to the amount and importance of the notes.
- Cover important concepts.
- Merge closely related information when appropriate.
- Do not create unnecessary cards.

CONTENT:
Make every card more explanatory than a one-line definition.

For a definition, explain:
Definition:
Short explanation:
Remember:

For a formula:
Formula:
Meaning:
Remember:

For a key concept:
Concept:
Important points:
Remember:

For a comparison:
Concept A:
Concept B:
Main difference:
Remember:

For a process:
Steps:
1.
2.
3.
Remember:

Use \\n for line breaks inside content.

Keep explanations concise enough to fit on a mobile study card.

Example:

[
  {
    "title": "Coulomb's Law",
    "content": "Definition:\\nThe electrostatic force between two point charges.\\n\\nFormula:\\nF = k|q₁q₂|/r²\\n\\nRemember:\\nThe force is directly proportional to the product of charges and inversely proportional to the square of distance.",
    "type": "formula"
  }
]

STUDENT NOTES:
$text
''';

      final response = await model.generateContent([Content.text(prompt)]);

      final responseText = response.text;

      if (responseText == null || responseText.trim().isEmpty) {
        throw Exception('Gemini returned an empty response.');
      }

      String cleanedText = responseText.trim();

      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }

      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }

      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      cleanedText = cleanedText.trim();

      final start = cleanedText.indexOf('[');
      final end = cleanedText.lastIndexOf(']');

      if (start == -1 || end == -1) {
        throw Exception('Gemini did not return a JSON array.');
      }

      cleanedText = cleanedText.substring(start, end + 1);

      final decoded = jsonDecode(cleanedText);

      if (decoded is! List) {
        throw Exception('Gemini response is not a JSON list.');
      }

      final cards = decoded
          .map((item) => Flashcard.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      if (cards.isEmpty) {
        throw Exception('Gemini returned zero flashcards.');
      }

      return cards;
    } catch (e) {
      throw Exception(
        'Flashcard generation failed:\n'
        '${e.runtimeType}\n'
        '$e',
      );
    }
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  static Future<String> generateSummary(String text) async {
    try {
      final prompt =
          '''
You are SmartStudy, an AI study assistant for engineering students.

Create a concise and exam-focused summary from the student's notes.

IMPORTANT:
- Return ONLY normal readable text.
- NEVER return JSON.
- NEVER use { }.
- NEVER use [ ].
- NEVER use JSON keys.
- NEVER use code fences.
- Do not create flashcards.
- Do not create questions.
- Do not invent information.
- Use ONLY information present in the notes.

Use this style:

TOPIC NAME

Overview:
2–4 simple sentences.

Key Points:
• important point
• important point
• important point

Important Definitions:
• Term — definition

Important Formulas:
• Formula — meaning

Remember:
• important exam point

Only include sections that are relevant.

Keep it clean and easy to revise on a phone.

STUDENT NOTES:
$text
''';

      final response = await model.generateContent([Content.text(prompt)]);

      final result = response.text;

      if (result == null || result.trim().isEmpty) {
        throw Exception('Gemini returned an empty summary.');
      }

      String cleaned = result.trim();

      cleaned = cleaned.replaceAll('```text', '');
      cleaned = cleaned.replaceAll('```markdown', '');
      cleaned = cleaned.replaceAll('```', '');

      // Remove heading symbols
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'^\s*#{1,6}\s*', multiLine: true),
        (_) => '',
      );

      // Remove bold and italic Markdown
      cleaned = cleaned.replaceAll('**', '');
      cleaned = cleaned.replaceAll('*', '');

      // Convert Markdown bullets
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'^\s*[-*]\s+', multiLine: true),
        (_) => '• ',
      );

      return cleaned.trim();
    } catch (e) {
      throw Exception(
        'Summary generation failed:\n'
        '${e.runtimeType}\n'
        '$e',
      );
    }
  }

  // ============================================================
  // QUIZ
  // ============================================================

  static Future<List<QuizQuestion>> generateQuiz(String text) async {
    try {
      final prompt =
          '''
You are SmartStudy, an AI quiz generator for engineering students.

Create a multiple-choice practice quiz from the student's notes.

IMPORTANT:
- Return ONLY a valid JSON array.
- Do NOT return Markdown.
- Do NOT return any text outside the JSON.
- Use ONLY information from the student's notes.
- Do not invent information.
- Questions must be based on important concepts from the notes.
- Generate a reasonable number of questions based on the amount of content.
- Each question must have exactly 4 options.
- Only ONE option must be correct.
- The answer must exactly match one of the options.
- Include a short explanation of the correct answer.

Each question MUST contain exactly:

"question"
"options"
"answer"
"explanation"

Example:

[
  {
    "question": "What is the SI unit of electric charge?",
    "options": [
      "Coulomb",
      "Volt",
      "Ohm",
      "Newton"
    ],
    "answer": "Coulomb",
    "explanation": "Electric charge is measured in coulombs."
  }
]

STUDENT NOTES:
$text
''';

      final response = await model.generateContent([Content.text(prompt)]);

      final responseText = response.text;

      if (responseText == null || responseText.trim().isEmpty) {
        throw Exception('Gemini returned an empty quiz.');
      }

      String cleanedText = responseText.trim();

      if (cleanedText.startsWith('```json')) {
        cleanedText = cleanedText.substring(7);
      }

      if (cleanedText.startsWith('```')) {
        cleanedText = cleanedText.substring(3);
      }

      if (cleanedText.endsWith('```')) {
        cleanedText = cleanedText.substring(0, cleanedText.length - 3);
      }

      cleanedText = cleanedText.trim();

      final start = cleanedText.indexOf('[');
      final end = cleanedText.lastIndexOf(']');

      if (start == -1 || end == -1) {
        throw Exception('Gemini did not return a quiz JSON array.');
      }

      cleanedText = cleanedText.substring(start, end + 1);

      final decoded = jsonDecode(cleanedText);

      if (decoded is! List) {
        throw Exception('Quiz response is not a JSON list.');
      }

      final questions = decoded
          .map((item) => QuizQuestion.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      if (questions.isEmpty) {
        throw Exception('Gemini returned zero quiz questions.');
      }

      return questions;
    } catch (e) {
      throw Exception(
        'Quiz generation failed:\n'
        '${e.runtimeType}\n'
        '$e',
      );
    }
  }
}
