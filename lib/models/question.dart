class TriviaQuestion {
  final String question;
  final String correctAnswer;
  final List<String> incorrectAnswers;
  List<String> _shuffledAnswers = [];

  TriviaQuestion({
    required this.question,
    required this.correctAnswer,
    required this.incorrectAnswers,
  }) {
    _shuffledAnswers = [...incorrectAnswers, correctAnswer];
    _shuffledAnswers.shuffle();
  }

  List<String> get answers => _shuffledAnswers;

  factory TriviaQuestion.fromJson(Map<String, dynamic> json) {
    return TriviaQuestion(
      question: json['question'] as String,
      correctAnswer: json['correct_answer'] as String,
      incorrectAnswers: List<String>.from(json['incorrect_answers'] as List),
    );
  }

  Map<String, dynamic> toJson() => {
    'question': question,
    'correct_answer': correctAnswer,
    'incorrect_answers': incorrectAnswers,
    'shuffled_answers': _shuffledAnswers,
  };
}