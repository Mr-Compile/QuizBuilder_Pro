import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/question.dart';

/// Service that calls the Groq API to generate quiz questions.
class GroqAiService {
  final SharedPreferences _prefs;
  final DatabaseHelper _db;

  GroqAiService(this._prefs, this._db);

  /// Stores the Groq API key in SharedPreferences.
  Future<void> saveApiKey(String key) async {
    await _prefs.setString(AppConstants.prefsApiKey, key.trim());
  }

  /// Returns the stored Groq API key, or null if not set.
  String? getApiKey() {
    return _prefs.getString(AppConstants.prefsApiKey);
  }

  /// Removes the stored API key.
  Future<void> clearApiKey() async {
    await _prefs.remove(AppConstants.prefsApiKey);
  }

  /// Sends the prompt to Groq and returns a list of parsed [Question] objects.
  /// [topicId] is the selected topic, [difficulty] is Easy/Medium/Hard and
  /// [quantity] is the number of questions to generate.
  Future<List<Question>> generateQuestions({
    required int topicId,
    required String difficulty,
    required int quantity,
    String category = 'General',
  }) async {
    final apiKey = getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key is not configured. Go to Settings to add your key.');
    }

    final hasInternet = await _hasInternet();
    if (!hasInternet) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    final prompt = _buildPrompt(
      topicId: topicId,
      difficulty: difficulty,
      quantity: quantity,
      category: category,
    );

    final response = await http.post(
      Uri.parse(AppConstants.groqEndpoint),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': AppConstants.groqModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful quiz generator. Always respond with a single valid JSON array of questions. Each question must have fields: question, option_a, option_b, option_c, option_d, correct_answer (one of A, B, C, D), and category. Do not include explanations or markdown.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 401) {
      throw Exception('Invalid Groq API key.');
    }
    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.statusCode} - ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from Groq.');
    }

    final message = choices.first['message'] as Map<String, dynamic>;
    final content = message['content'] as String;

    return _parseGeneratedJson(content, topicId, difficulty);
  }

  /// Quick connectivity probe before calling the Groq API.
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('api.groq.com')
          .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Builds the user prompt sent to Groq.
  String _buildPrompt({
    required int topicId,
    required String difficulty,
    required int quantity,
    required String category,
  }) {
    final topic = 'topic_id $topicId';
    return 'Generate $quantity multiple choice questions for $topic at $difficulty difficulty. '
        'Return only a valid JSON array. Each object must contain: '
        'question, option_a, option_b, option_c, option_d, correct_answer (A/B/C/D), category. '
        'Category should be "$category". Make sure options are plausible and one is clearly correct.';
  }

  /// Parses the AI response content into [Question] objects.
  List<Question> _parseGeneratedJson(String content, int topicId, String difficulty) {
    String cleaned = content.trim();

    // Sometimes the model wraps the JSON in markdown code blocks.
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.replaceFirst('```json', '');
      cleaned = cleaned.replaceFirst('```', '');
      cleaned = cleaned.trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst('```', '');
      cleaned = cleaned.replaceFirst('```', '');
      cleaned = cleaned.trim();
    }

    final parsed = jsonDecode(cleaned);
    if (parsed is! List) {
      throw Exception('Expected a JSON array of questions.');
    }

    final now = DateTime.now().toIso8601String();
    final questions = <Question>[];

    for (int i = 0; i < parsed.length; i++) {
      final item = parsed[i];
      if (item is! Map<String, dynamic>) {
        throw Exception('Question $i is not a valid object.');
      }

      final questionText = item['question']?.toString() ?? '';
      final optionA = item['option_a']?.toString() ?? '';
      final optionB = item['option_b']?.toString() ?? '';
      final optionC = item['option_c']?.toString() ?? '';
      final optionD = item['option_d']?.toString() ?? '';
      var correct = item['correct_answer']?.toString().toUpperCase() ?? '';

      if (!['A', 'B', 'C', 'D'].contains(correct)) {
        throw Exception('Question $i has an invalid correct_answer: $correct');
      }
      if (questionText.isEmpty || optionA.isEmpty || optionB.isEmpty) {
        throw Exception('Question $i is missing required fields.');
      }

      questions.add(Question(
        topicId: topicId,
        question: questionText,
        optionA: optionA,
        optionB: optionB,
        optionC: optionC,
        optionD: optionD,
        correctAnswer: correct,
        difficulty: difficulty,
        category: item['category']?.toString() ?? 'General',
        source: AppConstants.sourceAi,
        createdBy: null,
        createdAt: now,
      ));
    }

    return questions;
  }

  /// Persists selected AI-generated questions into SQLite.
  Future<List<int>> saveQuestions(List<Question> questions, int createdBy) async {
    final now = DateTime.now().toIso8601String();
    final ids = <int>[];

    for (final q in questions) {
      final questionToInsert = Question(
        topicId: q.topicId,
        question: q.question,
        optionA: q.optionA,
        optionB: q.optionB,
        optionC: q.optionC,
        optionD: q.optionD,
        correctAnswer: q.correctAnswer,
        difficulty: q.difficulty,
        category: q.category,
        source: AppConstants.sourceAi,
        createdBy: createdBy,
        createdAt: now,
      );
      ids.add(await _db.insertQuestion(questionToInsert));
    }

    return ids;
  }
}
