/// The outcome of a single quiz attempt by a student.
class QuizResult {
  final int? id;
  final int userId;
  final int topicId;
  final String difficulty;
  final int score;
  final int totalQuestions;
  final double percentage;
  final String createdAt;

  QuizResult({
    this.id,
    required this.userId,
    required this.topicId,
    required this.difficulty,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'topic_id': topicId,
      'difficulty': difficulty,
      'score': score,
      'total_questions': totalQuestions,
      'percentage': percentage,
      'created_at': createdAt,
    };
  }

  factory QuizResult.fromMap(Map<String, dynamic> map) {
    return QuizResult(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      topicId: map['topic_id'] as int,
      difficulty: map['difficulty'] as String,
      score: map['score'] as int,
      totalQuestions: map['total_questions'] as int,
      percentage: map['percentage'] as double,
      createdAt: map['created_at'] as String,
    );
  }

  bool get passed => percentage >= 60.0;

  @override
  String toString() => 'QuizResult(id: $id, score: $score/$totalQuestions)';
}
