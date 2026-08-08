import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants/app_constants.dart';
import '../database/database_helper.dart';
import '../models/question.dart';
import '../models/user.dart';
import 'quota_service.dart';
import 'secure_storage_service.dart';

/// Service that calls the Groq API to generate quiz questions.
/// Enforces daily quota limits before allowing any generation.
class GroqAiService {
  final SecureStorageService _secure;
  final DatabaseHelper _db;
  final QuotaService _quota;

  GroqAiService(this._secure, this._db, this._quota);

  /// Stores the Groq API key securely.
  Future<void> saveApiKey(String key) async {
    await _secure.saveApiKey(key);
  }

  /// Returns the stored Groq API key, or null if not set.
  Future<String?> getApiKey() async {
    return _secure.getApiKey();
  }

  /// Returns a masked API key for display.
  Future<String?> getMaskedApiKey() async {
    return _secure.getMaskedApiKey();
  }

  /// Removes the stored API key.
  Future<void> clearApiKey() async {
    await _secure.deleteApiKey();
  }

  /// Validates that the stored API key looks like a valid Groq key.
  Future<bool> hasValidApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty && apiKey.startsWith('gsk_');
  }

  /// Sends the prompt to Groq and returns a list of parsed [Question] objects.
  /// [topicId] is the selected topic, [difficulty] is Easy/Medium/Hard and
  /// [quantity] is the number of questions to generate.
  /// [user] is the user requesting the generation (required for quota enforcement).
  Future<List<Question>> generateQuestions({
    required int topicId,
    required String difficulty,
    required int quantity,
    String category = 'General',
    int maxRetries = 2,
    required User user,
  }) async {
    // SECURITY: Enforce quota check before any API calls
    await _quota.checkQuotaAndThrowIfExceeded(user);

    final apiKey = await getApiKey();
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

    final responseContent = await _callGroqWithRetry(
      apiKey: apiKey,
      prompt: prompt,
      maxRetries: maxRetries,
    );

    final questions = _parseGeneratedJson(responseContent, topicId, difficulty);
    final validated = _validateQuestions(questions, expectedCount: quantity);

    // Record the successful generation for quota tracking
    await _quota.recordGeneration(
      userId: user.id!,
      topicId: topicId,
      difficulty: difficulty,
      count: validated.length,
    );

    return validated;
  }

  /// Calls the Groq API with exponential backoff retries.
  Future<String> _callGroqWithRetry({
    required String apiKey,
    required String prompt,
    required int maxRetries,
  }) async {
    var attempts = 0;
    Duration delay = const Duration(seconds: 1);

    while (true) {
      try {
        final response = await _callGroq(apiKey: apiKey, prompt: prompt);
        return response;
      } on SocketException catch (_) {
        throw Exception('No internet connection. Please check your network and try again.');
      } on TimeoutException catch (_) {
        if (attempts >= maxRetries) {
          throw Exception('Groq API request timed out. Please try again later.');
        }
      } on FormatException catch (_) {
        throw Exception('Groq returned an unexpected response format. Please try again.');
      } on Exception catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        if (message.contains('401')) {
          throw Exception('Invalid Groq API key. Please check your key in Settings.');
        }
        if (attempts >= maxRetries) {
          throw Exception('Groq API error: $message');
        }
      }

      attempts++;
      await Future<void>.delayed(delay);
      delay = delay * 2;
    }
  }

  /// Makes the actual HTTP call to Groq.
  Future<String> _callGroq({
    required String apiKey,
    required String prompt,
  }) async {
    final response = await http
        .post(
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
                'content': _systemPrompt,
              },
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.7,
            'max_tokens': 4096,
          }),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode == 401) {
      throw Exception('401 Invalid Groq API key.');
    }
    if (response.statusCode == 429) {
      throw Exception('429 Rate limit reached. Please wait a moment and try again.');
    }
    if (response.statusCode != 200) {
      throw Exception('${response.statusCode} ${response.body}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('No response from Groq.');
    }

    final message = choices.first['message'] as Map<String, dynamic>;
    final content = message['content'] as String;
    return content;
  }

  /// System prompt that instructs the model to produce valid JSON questions.
  String get _systemPrompt {
    return 'You are a helpful quiz generator. Always respond with a single valid JSON array of questions. '
        'Each question must have fields: question (string), option_a, option_b, option_c, option_d (all strings), '
        'correct_answer (one of A, B, C, D), and category (string). '
        'Do not include explanations, markdown, or any other text. Make options plausible with one clearly correct answer.';
  }

  /// Quick connectivity probe before calling the Groq API.
  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup('api.groq.com').timeout(const Duration(seconds: 5));
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
        'Category should be "$category". Make sure options are plausible and one is clearly correct. '
        'Vary the questions so they are not repetitive.';
  }

  /// Parses the AI response content into [Question] objects.
  List<Question> _parseGeneratedJson(String content, int topicId, String difficulty) {
    String cleaned = content.trim();

    // Sometimes the model wraps the JSON in markdown code blocks.
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
      if (cleaned.contains('```')) {
        cleaned = cleaned.substring(0, cleaned.lastIndexOf('```'));
      }
      cleaned = cleaned.trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
      if (cleaned.contains('```')) {
        cleaned = cleaned.substring(0, cleaned.lastIndexOf('```'));
      }
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

      final questionText = item['question']?.toString().trim() ?? '';
      final optionA = item['option_a']?.toString().trim() ?? '';
      final optionB = item['option_b']?.toString().trim() ?? '';
      final optionC = item['option_c']?.toString().trim() ?? '';
      final optionD = item['option_d']?.toString().trim() ?? '';
      var correct = item['correct_answer']?.toString().trim().toUpperCase() ?? '';

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
        category: item['category']?.toString().trim() ?? 'General',
        source: AppConstants.sourceAi,
        createdBy: null,
        createdAt: now,
      ));
    }

    return questions;
  }

  /// Validates generated questions for quality and uniqueness.
  List<Question> _validateQuestions(List<Question> questions, {required int expectedCount}) {
    if (questions.length < expectedCount) {
      throw Exception('Groq returned fewer questions than requested. Got ${questions.length}, expected $expectedCount.');
    }

    final seen = <String>{};
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];

      // Check for duplicate questions
      final normalized = q.question.toLowerCase().trim();
      if (seen.contains(normalized)) {
        throw Exception('Duplicate question detected at index $i.');
      }
      seen.add(normalized);

      // Check for duplicate options
      final options = {q.optionA.toLowerCase(), q.optionB.toLowerCase(), q.optionC.toLowerCase(), q.optionD.toLowerCase()};
      if (options.length < 4) {
        throw Exception('Question ${i + 1} has duplicate or empty options.');
      }

      // Check that the correct answer is not obviously marked in the text
      final correctOption = _getCorrectOptionText(q);
      if (q.question.toLowerCase().contains(correctOption.toLowerCase())) {
        // Just a warning, not a hard failure
      }
    }

    return questions;
  }

  String _getCorrectOptionText(Question q) {
    switch (q.correctAnswer.toUpperCase()) {
      case 'A':
        return q.optionA;
      case 'B':
        return q.optionB;
      case 'C':
        return q.optionC;
      case 'D':
        return q.optionD;
      default:
        return '';
    }
  }

  /// Persists selected AI-generated questions into SQLite and records the generation.
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

    await _db.recordAiGeneration(
      createdBy: createdBy,
      topicId: questions.first.topicId,
      difficulty: questions.first.difficulty,
      count: ids.length,
      generatedAt: now,
    );

    return ids;
  }

  /// Regenerate a single question with a different version.
  Future<Question> regenerateSingleQuestion({
    required Question originalQuestion,
    required String topicName,
    int maxRetries = 2,
  }) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key is not configured. Go to Settings to add your key.');
    }

    final hasInternet = await _hasInternet();
    if (!hasInternet) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    final prompt = _buildRegeneratePrompt(
      originalQuestion: originalQuestion,
      topicName: topicName,
    );

    final responseContent = await _callGroqWithRetry(
      apiKey: apiKey,
      prompt: prompt,
      maxRetries: maxRetries,
    );

    return _parseSingleQuestionJson(responseContent, originalQuestion.topicId, originalQuestion.difficulty);
  }

  /// Regenerate multiple selected questions.
  Future<List<Question>> regenerateSelectedQuestions({
    required List<Question> questions,
    required String topicName,
    int maxRetries = 2,
  }) async {
    final regenerated = <Question>[];
    for (final question in questions) {
      try {
        final newQuestion = await regenerateSingleQuestion(
          originalQuestion: question,
          topicName: topicName,
          maxRetries: maxRetries,
        );
        regenerated.add(newQuestion);
      } catch (e) {
        // If regeneration fails, keep the original
        regenerated.add(question);
      }
    }
    return regenerated;
  }

  /// Generate questions from custom topic text.
  Future<List<Question>> generateFromCustomTopic({
    required String customTopic,
    required int topicId,
    required String difficulty,
    required int quantity,
    String category = 'General',
    int maxRetries = 2,
    required User user,
  }) async {
    // SECURITY: Enforce quota check before any API calls
    await _quota.checkQuotaAndThrowIfExceeded(user);

    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key is not configured. Go to Settings to add your key.');
    }

    final hasInternet = await _hasInternet();
    if (!hasInternet) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    final prompt = _buildCustomTopicPrompt(
      customTopic: customTopic,
      difficulty: difficulty,
      quantity: quantity,
      category: category,
    );

    final responseContent = await _callGroqWithRetry(
      apiKey: apiKey,
      prompt: prompt,
      maxRetries: maxRetries,
    );

    final questions = _parseGeneratedJson(responseContent, topicId, difficulty);
    final validated = _validateQuestions(questions, expectedCount: quantity);

    // Record the successful generation for quota tracking
    await _quota.recordGeneration(
      userId: user.id!,
      topicId: topicId,
      difficulty: difficulty,
      count: validated.length,
    );

    return validated;
  }

  /// Generate questions from file content.
  Future<List<Question>> generateFromFileContent({
    required String fileContent,
    required int topicId,
    required String difficulty,
    required int quantity,
    String category = 'General',
    int maxRetries = 2,
    required User user,
  }) async {
    // SECURITY: Enforce quota check before any API calls
    await _quota.checkQuotaAndThrowIfExceeded(user);

    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key is not configured. Go to Settings to add your key.');
    }

    final hasInternet = await _hasInternet();
    if (!hasInternet) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    final prompt = _buildFileContentPrompt(
      fileContent: fileContent,
      difficulty: difficulty,
      quantity: quantity,
      category: category,
    );

    final responseContent = await _callGroqWithRetry(
      apiKey: apiKey,
      prompt: prompt,
      maxRetries: maxRetries,
    );

    final questions = _parseGeneratedJson(responseContent, topicId, difficulty);
    final validated = _validateQuestions(questions, expectedCount: quantity);

    // Record the successful generation for quota tracking
    await _quota.recordGeneration(
      userId: user.id!,
      topicId: topicId,
      difficulty: difficulty,
      count: validated.length,
    );

    return validated;
  }

  /// Identify the topic from given text using AI.
  Future<String> identifyTopic(String text) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key is not configured. Go to Settings to add your key.');
    }

    final hasInternet = await _hasInternet();
    if (!hasInternet) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    final prompt = _buildTopicIdentificationPrompt(text);

    final responseContent = await _callGroqWithRetry(
      apiKey: apiKey,
      prompt: prompt,
      maxRetries: 1,
    );

    return _parseTopicIdentification(responseContent);
  }

  /// Search the internet for topic information (simulated via AI knowledge).
  Future<String> searchTopicInfo(String topic) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('Groq API key is not configured. Go to Settings to add your key.');
    }

    final hasInternet = await _hasInternet();
    if (!hasInternet) {
      throw Exception('No internet connection. Please check your network and try again.');
    }

    final prompt = _buildTopicSearchPrompt(topic);

    final responseContent = await _callGroqWithRetry(
      apiKey: apiKey,
      prompt: prompt,
      maxRetries: 1,
    );

    return responseContent.trim();
  }

  /// Build prompt for regenerating a single question.
  String _buildRegeneratePrompt({
    required Question originalQuestion,
    required String topicName,
  }) {
    return 'Generate a different multiple choice question for the topic "$topicName" at ${originalQuestion.difficulty} difficulty. '
        'The original question was: "${originalQuestion.question}" '
        'Create a new question that tests the same concept but is different in wording and options. '
        'Return only a valid JSON object with fields: question, option_a, option_b, option_c, option_d, correct_answer (A/B/C/D), category. '
        'Category should be "${originalQuestion.category}". Make sure options are plausible and one is clearly correct.';
  }

  /// Build prompt for custom topic generation.
  String _buildCustomTopicPrompt({
    required String customTopic,
    required String difficulty,
    required int quantity,
    required String category,
  }) {
    return 'Generate $quantity multiple choice questions for the topic: "$customTopic" at $difficulty difficulty. '
        'Return only a valid JSON array. Each object must contain: '
        'question, option_a, option_b, option_c, option_d, correct_answer (A/B/C/D), category. '
        'Category should be "$category". Make sure options are plausible and one is clearly correct. '
        'Vary the questions so they are not repetitive.';
  }

  /// Build prompt for file content generation.
  String _buildFileContentPrompt({
    required String fileContent,
    required String difficulty,
    required int quantity,
    required String category,
  }) {
    final truncatedContent = fileContent.length > 2000 
        ? '${fileContent.substring(0, 2000)}...' 
        : fileContent;
    
    return 'Generate $quantity multiple choice questions based on the following content at $difficulty difficulty. '
        'Content: "$truncatedContent" '
        'Return only a valid JSON array. Each object must contain: '
        'question, option_a, option_b, option_c, option_d, correct_answer (A/B/C/D), category. '
        'Category should be "$category". Make sure options are plausible and one is clearly correct. '
        'Vary the questions so they are not repetitive.';
  }

  /// Build prompt for topic identification.
  String _buildTopicIdentificationPrompt(String text) {
    final truncatedText = text.length > 500 ? '${text.substring(0, 500)}...' : text;
    return 'Identify the main educational topic or subject from the following text. '
        'Text: "$truncatedText" '
        'Return only the topic name (e.g., "Mathematics", "Science", "History", etc.). '
        'Do not include explanations or additional text.';
  }

  /// Build prompt for topic search.
  String _buildTopicSearchPrompt(String topic) {
    return 'Provide a brief overview and key concepts for the topic: "$topic". '
        'Include the main subtopics and important areas that should be covered in a quiz. '
        'Keep it concise and educational.';
  }

  /// Parse a single question JSON response.
  Question _parseSingleQuestionJson(String content, int topicId, String difficulty) {
    String cleaned = content.trim();

    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
      if (cleaned.contains('```')) {
        cleaned = cleaned.substring(0, cleaned.lastIndexOf('```'));
      }
      cleaned = cleaned.trim();
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
      if (cleaned.contains('```')) {
        cleaned = cleaned.substring(0, cleaned.lastIndexOf('```'));
      }
      cleaned = cleaned.trim();
    }

    final parsed = jsonDecode(cleaned);
    if (parsed is! Map<String, dynamic>) {
      throw Exception('Expected a JSON object for a single question.');
    }

    final now = DateTime.now().toIso8601String();
    final questionText = parsed['question']?.toString().trim() ?? '';
    final optionA = parsed['option_a']?.toString().trim() ?? '';
    final optionB = parsed['option_b']?.toString().trim() ?? '';
    final optionC = parsed['option_c']?.toString().trim() ?? '';
    final optionD = parsed['option_d']?.toString().trim() ?? '';
    var correct = parsed['correct_answer']?.toString().trim().toUpperCase() ?? '';

    if (!['A', 'B', 'C', 'D'].contains(correct)) {
      throw Exception('Invalid correct_answer: $correct');
    }
    if (questionText.isEmpty || optionA.isEmpty || optionB.isEmpty) {
      throw Exception('Question is missing required fields.');
    }

    return Question(
      topicId: topicId,
      question: questionText,
      optionA: optionA,
      optionB: optionB,
      optionC: optionC,
      optionD: optionD,
      correctAnswer: correct,
      difficulty: difficulty,
      category: parsed['category']?.toString().trim() ?? 'General',
      source: AppConstants.sourceAi,
      createdBy: null,
      createdAt: now,
    );
  }

  /// Parse topic identification response.
  String _parseTopicIdentification(String content) {
    String cleaned = content.trim();
    
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll('```', '').trim();
    }
    
    if (cleaned.startsWith('"') && cleaned.endsWith('"')) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }
    
    return cleaned;
  }
}
