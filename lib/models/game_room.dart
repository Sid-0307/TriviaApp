import 'package:flutter/material.dart';
import 'package:trivia_game/models/player.dart';
import 'package:trivia_game/models/question.dart';

enum GameStatus { waiting, playing, finished }

class GameRoom {
  final String roomCode;
  final String hostId;
  List<Player> players;
  GameStatus status;
  List<TriviaQuestion> questions;
  int currentQuestionIndex;
  Map<String, int> answerOrder;

  GameRoom({
    required this.roomCode,
    required this.hostId,
    this.players = const [],
    this.status = GameStatus.waiting,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    Map<String, int>? answerOrder,
  }) : this.answerOrder = answerOrder ?? {};

  Map<String, dynamic> toJson() => {
    'roomCode': roomCode,
    'hostId': hostId,
    'players': players.map((p) => p.toJson()).toList(),
    'status': status.toString(),
    'currentQuestionIndex': currentQuestionIndex,
    'answerOrder': answerOrder,
    'questions': questions.map((q) => q.toJson()).toList(),
  };
}