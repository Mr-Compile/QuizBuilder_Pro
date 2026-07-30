/// A single question answer recorded during a quiz attempt.
class QuizAnswer {
  final int? id;
  final int resultId;
  final int questionId;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;

  QuizAnswer({
    this.id,
    required this.resultId,
    required this.questionId,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'result_id': resultId,
      'question_id': questionId,
      'user_answer': userAnswer,
      'correct_answer': correctAnswer,
      'is_correct': isCorrect ? 1 : 0,
    };
  }

  factory QuizAnswer.fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      id: map['id'] as int?,
      resultId: map['result_id'] as int,
      questionId: map['question_id'] as int,
      userAnswer: map['user_answer'] as String,
      correctAnswer: map['correct_answer'] as String,
      isCorrect: (map['is_correct'] as int) == 1,
    );
  }

  @override
  String toString() => 'QuizAnswer(resultId: $resultId, questionId: $questionId, isCorrect: $isCorrect)';
}
