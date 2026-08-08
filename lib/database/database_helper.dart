import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants/app_constants.dart';
import '../models/quiz_answer.dart';
import '../models/quiz_result.dart';
import '../models/question.dart';
import '../models/topic.dart';
import '../models/user.dart';

/// Singleton helper that manages the SQLite database for QuizBuilder Pro.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  static const String _dbName = 'quizbuilder_pro.db';
  static const int _dbVersion = 2;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
    await _createIndexes(db);
    await _seedDatabase(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createAiGenerationsTable(db);
      await _createIndexes(db);
    }
  }

  Future<void> _createTables(Database db) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        full_name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Topics table
    await db.execute('''
      CREATE TABLE topics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL
      )
    ''');

    // Questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        topic_id INTEGER NOT NULL,
        question TEXT NOT NULL,
        option_a TEXT NOT NULL,
        option_b TEXT NOT NULL,
        option_c TEXT NOT NULL,
        option_d TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        category TEXT NOT NULL,
        source TEXT NOT NULL,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL
      )
    ''');

    // Quiz results table
    await db.execute('''
      CREATE TABLE quiz_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        topic_id INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        score INTEGER NOT NULL,
        total_questions INTEGER NOT NULL,
        percentage REAL NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
      )
    ''');

    // Quiz answers table
    await db.execute('''
      CREATE TABLE quiz_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        result_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        user_answer TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        FOREIGN KEY (result_id) REFERENCES quiz_results(id) ON DELETE CASCADE,
        FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
      )
    ''');

    await _createAiGenerationsTable(db);
  }

  Future<void> _createAiGenerationsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_generations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        created_by INTEGER NOT NULL,
        topic_id INTEGER NOT NULL,
        difficulty TEXT NOT NULL,
        count INTEGER NOT NULL,
        generated_at TEXT NOT NULL,
        FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (topic_id) REFERENCES topics(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('CREATE INDEX IF NOT EXISTS idx_questions_topic ON questions(topic_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_questions_difficulty ON questions(difficulty)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quiz_results_user ON quiz_results(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quiz_results_topic ON quiz_results(topic_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_quiz_answers_result ON quiz_answers(result_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ai_generations_created_by ON ai_generations(created_by)');
  }

  /// Inserts the default sample data required by the project brief.
  Future<void> _seedDatabase(Database db) async {
    // Teacher
    await db.insert('users', {
      'full_name': 'Teacher',
      'username': AppConstants.defaultTeacherUsername,
      'password': AppConstants.defaultTeacherPassword,
      'role': AppConstants.roleTeacher,
      'is_active': 1,
    });

    // Sample students
    final students = [
      {'full_name': 'Alice Johnson', 'username': 'alice', 'password': 'alice123', 'role': AppConstants.roleStudent, 'is_active': 1},
      {'full_name': 'Bob Smith', 'username': 'bob', 'password': 'bob123', 'role': AppConstants.roleStudent, 'is_active': 1},
      {'full_name': 'Charlie Brown', 'username': 'charlie', 'password': 'charlie123', 'role': AppConstants.roleStudent, 'is_active': 1},
    ];
    for (final s in students) {
      await db.insert('users', s);
    }

    // Sample topics
    final topicNames = {
      'Mathematics': 'Numbers, algebra and basic arithmetic.',
      'Science': 'General science and everyday phenomena.',
      'English': 'Grammar, vocabulary and reading.',
      'History': 'Important events and people.',
      'Geography': 'Countries, landscapes and maps.',
    };
    final topicIds = <String, int>{};
    for (final entry in topicNames.entries) {
      topicIds[entry.key] = await db.insert('topics', {
        'name': entry.key,
        'description': entry.value,
      });
    }

    // Seed questions: 2 easy, 2 medium, 2 hard per topic (30 total)
    final seedQuestions = _buildSeedQuestions(topicIds);
    for (final q in seedQuestions) {
      await db.insert('questions', q);
    }
  }

  /// Builds the list of seed question maps.
  List<Map<String, dynamic>> _buildSeedQuestions(Map<String, int> topicIds) {
    final now = DateTime.now().toIso8601String();
    final questions = <Map<String, dynamic>>[];

    void add(String topic, String difficulty, String question, String a, String b, String c, String d, String correct, String source) {
      questions.add({
        'topic_id': topicIds[topic]!,
        'question': question,
        'option_a': a,
        'option_b': b,
        'option_c': c,
        'option_d': d,
        'correct_answer': correct,
        'difficulty': difficulty,
        'category': topic,
        'source': source,
        'created_by': null,
        'created_at': now,
      });
    }

    // Mathematics
    add('Mathematics', AppConstants.difficultyEasy, 'What is 5 + 7?', '10', '11', '12', '13', 'C', AppConstants.sourceManual);
    add('Mathematics', AppConstants.difficultyEasy, 'What is 9 x 3?', '18', '27', '24', '21', 'B', AppConstants.sourceAi);
    add('Mathematics', AppConstants.difficultyMedium, 'What is the value of x in 2x + 4 = 10?', '2', '3', '4', '5', 'B', AppConstants.sourceManual);
    add('Mathematics', AppConstants.difficultyMedium, 'What is 25% of 80?', '15', '20', '25', '30', 'B', AppConstants.sourceAi);
    add('Mathematics', AppConstants.difficultyHard, 'What is the square root of 144?', '10', '11', '12', '13', 'C', AppConstants.sourceManual);
    add('Mathematics', AppConstants.difficultyHard, 'Solve for y: 3y - 7 = 14', '6', '7', '8', '9', 'B', AppConstants.sourceAi);

    // Science
    add('Science', AppConstants.difficultyEasy, 'What do plants need for photosynthesis?', 'Oxygen', 'Sunlight', 'Sugar', 'Nitrogen', 'B', AppConstants.sourceAi);
    add('Science', AppConstants.difficultyEasy, 'What is the chemical formula of water?', 'H2O', 'CO2', 'O2', 'NaCl', 'A', AppConstants.sourceManual);
    add('Science', AppConstants.difficultyMedium, 'What planet is known as the Red Planet?', 'Venus', 'Jupiter', 'Mars', 'Saturn', 'C', AppConstants.sourceManual);
    add('Science', AppConstants.difficultyMedium, 'Which gas do humans breathe in?', 'Carbon dioxide', 'Oxygen', 'Nitrogen', 'Hydrogen', 'B', AppConstants.sourceAi);
    add('Science', AppConstants.difficultyHard, 'What is the powerhouse of the cell?', 'Nucleus', 'Ribosome', 'Mitochondria', 'Cytoplasm', 'C', AppConstants.sourceAi);
    add('Science', AppConstants.difficultyHard, 'What is the speed of light approximately?', '300,000 km/s', '150,000 km/s', '30,000 km/s', '1,000 km/s', 'A', AppConstants.sourceManual);

    // English
    add('English', AppConstants.difficultyEasy, 'Which is a noun?', 'Run', 'Quickly', 'Apple', 'Beautiful', 'C', AppConstants.sourceManual);
    add('English', AppConstants.difficultyEasy, 'What is the opposite of "happy"?', 'Angry', 'Sad', 'Tired', 'Excited', 'B', AppConstants.sourceAi);
    add('English', AppConstants.difficultyMedium, 'Which sentence is correct?', 'She go to school.', 'She goes to school.', 'She going to school.', 'She gone to school.', 'B', AppConstants.sourceManual);
    add('English', AppConstants.difficultyMedium, 'What is a synonym for "big"?', 'Small', 'Tiny', 'Large', 'Little', 'C', AppConstants.sourceAi);
    add('English', AppConstants.difficultyHard, 'What is the past tense of "run"?', 'Runned', 'Ran', 'Running', 'Runs', 'B', AppConstants.sourceAi);
    add('English', AppConstants.difficultyHard, 'Which word is an adverb?', 'Fast', 'Happiness', 'Slowly', 'Blue', 'C', AppConstants.sourceManual);

    // History
    add('History', AppConstants.difficultyEasy, 'Which country was the first to land humans on the Moon?', 'USSR', 'USA', 'China', 'India', 'B', AppConstants.sourceAi);
    add('History', AppConstants.difficultyEasy, 'Who was the first President of the United States?', 'Lincoln', 'Jefferson', 'Washington', 'Adams', 'C', AppConstants.sourceManual);
    add('History', AppConstants.difficultyMedium, 'In which year did World War II end?', '1940', '1945', '1950', '1939', 'B', AppConstants.sourceManual);
    add('History', AppConstants.difficultyMedium, 'Who wrote the play "Romeo and Juliet"?', 'Charles Dickens', 'William Shakespeare', 'Mark Twain', 'Jane Austen', 'B', AppConstants.sourceAi);
    add('History', AppConstants.difficultyHard, 'Which empire built the Colosseum?', 'Greek Empire', 'Roman Empire', 'Ottoman Empire', 'British Empire', 'B', AppConstants.sourceAi);
    add('History', AppConstants.difficultyHard, 'Who discovered penicillin?', 'Marie Curie', 'Alexander Fleming', 'Isaac Newton', 'Albert Einstein', 'B', AppConstants.sourceManual);

    // Geography
    add('Geography', AppConstants.difficultyEasy, 'Which is the largest ocean on Earth?', 'Atlantic', 'Indian', 'Pacific', 'Arctic', 'C', AppConstants.sourceManual);
    add('Geography', AppConstants.difficultyEasy, 'Which is the capital of France?', 'London', 'Berlin', 'Paris', 'Rome', 'C', AppConstants.sourceAi);
    add('Geography', AppConstants.difficultyMedium, 'Which country has the largest population?', 'India', 'China', 'USA', 'Indonesia', 'B', AppConstants.sourceAi);
    add('Geography', AppConstants.difficultyMedium, 'What is the longest river in the world?', 'Amazon', 'Nile', 'Yangtze', 'Mississippi', 'B', AppConstants.sourceManual);
    add('Geography', AppConstants.difficultyHard, 'Which continent is the Sahara Desert located in?', 'Asia', 'Australia', 'Africa', 'South America', 'C', AppConstants.sourceManual);
    add('Geography', AppConstants.difficultyHard, 'Mount Everest is located in which mountain range?', 'Alps', 'Andes', 'Himalayas', 'Rockies', 'C', AppConstants.sourceAi);

    return questions;
  }

  // ---------------- Users ----------------

  Future<int> insertUser(User user) async {
    final db = await database;
    return db.insert('users', user.toMap());
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final maps = await db.query('users', where: 'username = ?', whereArgs: [username], limit: 1);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return User.fromMap(maps.first);
  }

  Future<List<User>> getAllStudents() async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: [AppConstants.roleStudent],
      orderBy: 'full_name ASC',
    );
    return maps.map(User.fromMap).toList();
  }

  Future<List<User>> getAllUsers() async {
    final db = await database;
    final maps = await db.query('users', orderBy: 'full_name ASC');
    return maps.map(User.fromMap).toList();
  }

  Future<int> countStudents({bool activeOnly = false}) async {
    final db = await database;
    final condition = activeOnly ? 'role = ? AND is_active = 1' : 'role = ?';
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM users WHERE $condition',
      [AppConstants.roleStudent],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ---------------- Topics ----------------

  Future<int> insertTopic(Topic topic) async {
    final db = await database;
    return db.insert('topics', topic.toMap());
  }

  Future<int> updateTopic(Topic topic) async {
    final db = await database;
    return db.update('topics', topic.toMap(), where: 'id = ?', whereArgs: [topic.id]);
  }

  Future<int> deleteTopic(int id) async {
    final db = await database;
    return db.delete('topics', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Topic>> getAllTopics() async {
    final db = await database;
    final maps = await db.query('topics', orderBy: 'name ASC');
    return maps.map(Topic.fromMap).toList();
  }

  Future<Topic?> getTopicById(int id) async {
    final db = await database;
    final maps = await db.query('topics', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Topic.fromMap(maps.first);
  }

  Future<Topic?> getTopicByName(String name) async {
    final db = await database;
    final maps = await db.query('topics', where: 'name = ?', whereArgs: [name], limit: 1);
    if (maps.isEmpty) return null;
    return Topic.fromMap(maps.first);
  }

  Future<int> getQuestionCountByTopic(int topicId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions WHERE topic_id = ?',
      [topicId],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ---------------- Questions ----------------

  Future<int> insertQuestion(Question question) async {
    final db = await database;
    return db.insert('questions', question.toMap());
  }

  Future<int> updateQuestion(Question question) async {
    final db = await database;
    return db.update('questions', question.toMap(), where: 'id = ?', whereArgs: [question.id]);
  }

  Future<int> deleteQuestion(int id) async {
    final db = await database;
    return db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Question>> getQuestions({int? topicId, String? difficulty, String? search}) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (topicId != null) {
      where.add('topic_id = ?');
      whereArgs.add(topicId);
    }
    if (difficulty != null) {
      where.add('difficulty = ?');
      whereArgs.add(difficulty);
    }
    if (search != null && search.trim().isNotEmpty) {
      where.add('question LIKE ?');
      whereArgs.add('%$search%');
    }

    final whereString = where.isNotEmpty ? where.join(' AND ') : null;
    final maps = await db.query(
      'questions',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'id DESC',
    );
    return maps.map(Question.fromMap).toList();
  }

  Future<Question?> getQuestionById(int id) async {
    final db = await database;
    final maps = await db.query('questions', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Question.fromMap(maps.first);
  }

  Future<int> countQuestions() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM questions');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<Question>> getAllQuestions() async {
    return getQuestions();
  }

  // ---------------- Quiz Results ----------------

  Future<int> insertQuizResult(QuizResult result) async {
    final db = await database;
    return db.insert('quiz_results', result.toMap());
  }

  Future<List<QuizResult>> getResultsForUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'quiz_results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map(QuizResult.fromMap).toList();
  }

  Future<List<QuizResult>> getAllResults() async {
    final db = await database;
    final maps = await db.query('quiz_results', orderBy: 'created_at DESC');
    return maps.map(QuizResult.fromMap).toList();
  }

  Future<List<QuizResult>> getAllQuizResults() async {
    return getAllResults();
  }

  Future<QuizResult?> getResultById(int id) async {
    final db = await database;
    final maps = await db.query(
      'quiz_results',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return QuizResult.fromMap(maps.first);
  }

  Future<List<QuizResult>> getResultsForStudent(int userId) async {
    final db = await database;
    final maps = await db.query(
      'quiz_results',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map(QuizResult.fromMap).toList();
  }

  Future<int> countResults() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM quiz_results');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getTopicPerformanceForStudent(int userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT 
        t.id as topic_id,
        t.name as topic_name,
        COUNT(qr.id) as attempts,
        AVG(qr.percentage) as avg_percentage,
        MAX(qr.percentage) as best_percentage,
        SUM(qr.total_questions) as total_questions,
        SUM(qr.score) as total_correct
      FROM quiz_results qr
      JOIN topics t ON qr.topic_id = t.id
      WHERE qr.user_id = ?
      GROUP BY t.id
      ORDER BY avg_percentage ASC
    ''', [userId]);
  }

  Future<List<Map<String, dynamic>>> getWrongAnswersForStudent(int userId, {int limit = 50}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT DISTINCT
        q.id,
        q.topic_id,
        q.question,
        q.option_a,
        q.option_b,
        q.option_c,
        q.option_d,
        q.correct_answer,
        q.difficulty,
        q.category,
        t.name as topic_name,
        qa.user_answer as last_user_answer
      FROM quiz_answers qa
      JOIN quiz_results qr ON qa.result_id = qr.id
      JOIN questions q ON qa.question_id = q.id
      JOIN topics t ON q.topic_id = t.id
      WHERE qr.user_id = ? AND qa.is_correct = 0
      ORDER BY qr.created_at DESC
      LIMIT ?
    ''', [userId, limit]);
  }

  // ---------------- Quiz Answers ----------------

  Future<int> insertQuizAnswer(QuizAnswer answer) async {
    final db = await database;
    return db.insert('quiz_answers', answer.toMap());
  }

  Future<int> insertQuizAnswers(List<QuizAnswer> answers) async {
    final db = await database;
    int count = 0;
    for (final answer in answers) {
      count += await db.insert('quiz_answers', answer.toMap());
    }
    return count;
  }

  Future<List<QuizAnswer>> getAnswersForResult(int resultId) async {
    final db = await database;
    final maps = await db.query(
      'quiz_answers',
      where: 'result_id = ?',
      whereArgs: [resultId],
      orderBy: 'id ASC',
    );
    return maps.map(QuizAnswer.fromMap).toList();
  }

  Future<List<QuizAnswer>> getAllQuizAnswers() async {
    final db = await database;
    final maps = await db.query('quiz_answers', orderBy: 'id ASC');
    return maps.map(QuizAnswer.fromMap).toList();
  }

  // ---------------- AI Generation History ----------------

  Future<int> recordAiGeneration({
    required int createdBy,
    required int topicId,
    required String difficulty,
    required int count,
    required String generatedAt,
  }) async {
    final db = await database;
    return db.insert('ai_generations', {
      'created_by': createdBy,
      'topic_id': topicId,
      'difficulty': difficulty,
      'count': count,
      'generated_at': generatedAt,
    });
  }

  Future<List<Map<String, dynamic>>> getAiGenerationHistory({
    int? createdBy,
    int? topicId,
    int limit = 50,
  }) async {
    final db = await database;
    final where = <String>[];
    final whereArgs = <dynamic>[];

    if (createdBy != null) {
      where.add('created_by = ?');
      whereArgs.add(createdBy);
    }
    if (topicId != null) {
      where.add('topic_id = ?');
      whereArgs.add(topicId);
    }

    final maps = await db.query(
      'ai_generations',
      where: where.isNotEmpty ? where.join(' AND ') : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'generated_at DESC',
      limit: limit,
    );
    return maps;
  }

  Future<int> countAiGenerations() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM ai_generations');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> getAllAiGenerations() async {
    final db = await database;
    final maps = await db.query('ai_generations', orderBy: 'generated_at DESC');
    return maps;
  }
}
