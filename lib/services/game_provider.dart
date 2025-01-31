import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:trivia_game/services/trivia_service.dart';

import '../models/game_room.dart';
import '../models/player.dart';
import '../models/question.dart';
import '../screen/loader_screen.dart';

class GameProvider with ChangeNotifier {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  GameRoom? currentRoom;
  Player? currentPlayer;
  StreamSubscription<DatabaseEvent>? _roomSubscription;
  List<TriviaQuestion> questions = [];
  int currentQuestionIndex = 0;
  static final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> moveToNextQuestion() async {
    if (currentRoom == null || questions.isEmpty) return;

    currentQuestionIndex++;

    if (currentQuestionIndex >= questions.length) {
      // Set all players to inactive when game finishes
      final updatedPlayers = currentRoom!.players.map((player) {
        return Player(
          id: player.id,
          name: player.name,
          score: player.score,
        );
      }).toList();

      await _database.ref('rooms/${currentRoom!.roomCode}').update({
        'status': GameStatus.finished.toString(),
        'currentQuestionIndex': currentQuestionIndex,
        'players': updatedPlayers.map((p) => p.toJson()).toList(),
        'answerOrder':[],
      });
    } else {
      await _database.ref('rooms/${currentRoom!.roomCode}').update({
        'currentQuestionIndex': currentQuestionIndex,
        'answerOrder':[],
      });
    }

    notifyListeners();
  }

  // In GameProvider.dart, add this new method:
  Future<void> kickPlayer(String playerId) async {
    if (currentRoom == null || currentPlayer?.id != currentRoom!.hostId) return;

    final updatedPlayers = currentRoom!.players
        .where((player) => player.id != playerId)
        .toList();

    await _database.ref('rooms/${currentRoom!.roomCode}/players')
        .set(updatedPlayers.map((p) => p.toJson()).toList());

    notifyListeners();
  }

  Future<void> rejoinWaitingRoom(BuildContext context) async {
    if (currentRoom == null || currentPlayer == null) return;

    final roomRef = _database.ref('rooms/${currentRoom!.roomCode}');

    final updatedPlayers = currentRoom!.players.map((player) {
      return Player(
        id: player.id,
        name: player.name,
        score: 0,
      );
    }).toList();

    await roomRef.update({
      'status': GameStatus.waiting.toString(),
      'currentQuestionIndex': 0,
      'players': updatedPlayers.map((p) => p.toJson()).toList(),
    });
  }

  String generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ123456789';
    String code = '';
    for (var i = 0; i < 6; i++) {
      code += chars[DateTime.now().microsecondsSinceEpoch % chars.length];
    }
    return code;
  }

  Future<void> createRoom(String playerName) async {
    final roomCode = generateRoomCode();
    final playerId = _database.ref().push().key!;

    final player = Player(id: playerId, name: playerName);
    final room = GameRoom(
      roomCode: roomCode,
      hostId: playerId,
      players: [player],
      status: GameStatus.waiting,
    );

    await _database.ref('rooms/$roomCode').set(room.toJson());
    currentRoom = room;
    currentPlayer = player;
    _startListeningToRoom(roomCode);
    notifyListeners();
  }

  Future<void> joinRoom(String roomCode, String playerName) async {
    final ref = _database.ref('rooms/$roomCode');
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      throw Exception('Room not found');
    }

    final playerId = _database.ref().push().key!;
    final player = Player(id: playerId, name: playerName);

    // Get the current players list
    final playersSnapshot = await ref.child('players').get();
    List<Player> currentPlayers = [];

    if (playersSnapshot.exists) {
      final playersList = playersSnapshot.value as List<Object?>;
      for (var playerData in playersList) {
        if (playerData != null) {
          currentPlayers.add(
              Player.fromJson(Map<String, dynamic>.from(playerData as Map))
          );
        }
      }
    }

    // Add the new player
    currentPlayers.add(player);

    // Update local state
    currentPlayer = player;
    currentRoom = GameRoom(
      roomCode: roomCode,
      hostId: snapshot.child('hostId').value as String,
      players: currentPlayers,
      status: GameStatus.waiting,
    );

    // Update Firebase - update the entire players list
    await ref.child('players').set(
        currentPlayers.map((p) => p.toJson()).toList()
    );

    // Start listening to room changes
    _startListeningToRoom(roomCode);
    notifyListeners();
  }

  void _startListeningToRoom(String roomCode) {
    _roomSubscription?.cancel();

    _roomSubscription = _database
        .ref('rooms/$roomCode')
        .onValue
        .listen((DatabaseEvent event) {
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;

        // Convert players list to List<Player>
        List<Player> players = [];
        if (data['players'] != null) {
          final playersList = data['players'] as List<Object?>;
          for (var playerData in playersList) {
            if (playerData != null) {
              players.add(
                  Player.fromJson(Map<String, dynamic>.from(playerData as Map))
              );
            }
          }
        }

        // Check if current player has been kicked
        if (currentPlayer != null &&
            !players.any((p) => p.id == currentPlayer!.id)) {
          // Player has been kicked - clean up and navigate out
          currentRoom = null;
          currentPlayer = null;
          _roomSubscription?.cancel();
          notifyListeners();

          // Post frame callback to avoid build errors
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Get context using our navigatorKey
            final context = navigatorKey.currentContext;
            if (context != null) {
              // Clear navigation stack and go to home
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);

              // Show kicked message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You have been removed from the room'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          });
          return;
        }

        // Parse questions if they exist
        List<TriviaQuestion> parsedQuestions = [];
        if (data['questions'] != null) {
          final questionsList = data['questions'] as List<Object?>;
          parsedQuestions = questionsList
              .where((q) => q != null)
              .map((q) => TriviaQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
              .toList();
        }

        // Update current question index
        int parsedQuestionIndex = data['currentQuestionIndex'] ?? 0;

        currentRoom = GameRoom(
          roomCode: data['roomCode'] as String,
          hostId: data['hostId'] as String,
          players: players,
          status: GameStatus.values.firstWhere(
                (e) => e.toString() == data['status'],
            orElse: () => GameStatus.waiting,
          ),
          questions: parsedQuestions,
        );

        // Update local state
        questions = parsedQuestions;
        currentQuestionIndex = parsedQuestionIndex;

        notifyListeners();
      }
    });
  }

  Future<void> startGame() async {
    if (currentRoom == null) return;

    // Filter out inactive players before starting the game
    // final activePlayers = currentRoom!.players
    //     .where((player) => player.status == PlayerStatus.active)
    //     .toList();

    final fetchedQuestions = await TriviaService().fetchQuestions();

    await _database.ref('rooms/${currentRoom!.roomCode}').update({
      'status': GameStatus.playing.toString(),
      'questions': fetchedQuestions.map((q) => q.toJson()).toList(),
      'currentQuestionIndex': 0,
      // 'players': activePlayers.map((p) => p.toJson()).toList(),
    });

    questions = fetchedQuestions;
    currentQuestionIndex = 0;
    notifyListeners();
  }

  TriviaQuestion? getCurrentQuestion() {
    if (questions.isEmpty || currentQuestionIndex < 0 || currentQuestionIndex >= questions.length) {
      return null;
    }
    return questions[currentQuestionIndex];
  }

  Future<void> submitAnswer(String answer) async {
    if (currentRoom == null || currentPlayer == null || questions.isEmpty) return;

    final currentQuestion = questions[currentQuestionIndex];
    final isCorrectAnswer = currentQuestion.correctAnswer == answer;

    final roomRef = _database.ref('rooms/${currentRoom!.roomCode}');
    final answerOrderRef = roomRef.child('answerOrder');

    final transaction = await answerOrderRef.runTransaction((Object? curr) {
      List<String> answers = curr != null ? List<String>.from(curr as List) : [];
      if (!answers.contains(currentPlayer!.id) && isCorrectAnswer) {
        answers.add(currentPlayer!.id);
      }
      return Transaction.success(answers);
    });

    if (transaction.committed) {
      final answers = transaction.snapshot.value != null
          ? List<String>.from(transaction.snapshot.value as List)
          : <String>[];

      final position = answers.contains(currentPlayer!.id)
          ? answers.indexOf(currentPlayer!.id)
          : -1;

      int points = 0;
      if (isCorrectAnswer) {
        if (position == 0) {
          points = 5;
        } else if (position == 1) {
          points = 4;
        }
        else if (position == 2) {
          points = 3;
        }
        else {
          points = 1;
        }
      } else {
        points = -5; // Wrong answer
      }

      final playerIndex = currentRoom!.players.indexWhere(
              (p) => p.id == currentPlayer!.id
      );

      if (playerIndex != -1) {
        final playerSnapshot = await _database
            .ref('rooms/${currentRoom!.roomCode}/players/$playerIndex')
            .get();

        int currentScore = (playerSnapshot.value as Map)['score'] ?? 0;
        int newScore = currentScore + points;

        await _database
            .ref('rooms/${currentRoom!.roomCode}/players/$playerIndex/score')
            .set(newScore);

        notifyListeners();
      }
    }
  }

  Future<void> skipQuestion() async {
    if (currentRoom == null || currentPlayer == null) return;

    final playerIndex = currentRoom!.players.indexWhere(
            (p) => p.id == currentPlayer!.id
    );

    if (playerIndex != -1) {
      final updatedPlayers = List<Player>.from(currentRoom!.players);
      updatedPlayers[playerIndex] = Player(
        id: currentPlayer!.id,
        name: currentPlayer!.name,
        score: (currentPlayer!.score ?? 0) - 1,
      );

      await _database.ref('rooms/${currentRoom!.roomCode}/players')
          .set(updatedPlayers.map((p) => p.toJson()).toList());
    }
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    super.dispose();
  }
}