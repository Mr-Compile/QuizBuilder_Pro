/// A multiple-choice question belonging to a topic.
class Question {
  final int? id;
  final int topicId;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String correctAnswer; // 'A', 'B', 'C' or 'D'
  final String difficulty; // Easy, Medium, Hard
  final String category;
  final String source; // 'manual' or 'ai'
  final int? createdBy;
  final String createdAt;

  Question({
    this.id,
    required this.topicId,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.correctAnswer,
    required this.difficulty,
    required this.category,
    this.source = 'manual',
    this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'topic_id': topicId,
      'question': question,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
      'correct_answer': correctAnswer,
      'difficulty': difficulty,
      'category': category,
      'source': source,
      'created_by': createdBy,
      'created_at': createdAt,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int?,
      topicId: map['topic_id'] as int,
      question: map['question'] as String,
      optionA: map['option_a'] as String,
      optionB: map['option_b'] as String,
      optionC: map['option_c'] as String,
      optionD: map['option_d'] as String,
      correctAnswer: map['correct_answer'] as String,
      difficulty: map['difficulty'] as String,
      category: map['category'] as String,
      source: map['source'] as String,
      createdBy: map['created_by'] as int?,
      createdAt: map['created_at'] as String,
    );
  }

  String optionLetterToText(String letter) {
    switch (letter.toUpperCase()) {
      case 'A':
        return optionA;
      case 'B':
        return optionB;
      case 'C':
        return optionC;
      case 'D':
        return optionD;
      default:
        return '';
    }
  }

  @override
  String toString() => 'Question(id: $id, topicId: $topicId, difficulty: $difficulty)';
}
