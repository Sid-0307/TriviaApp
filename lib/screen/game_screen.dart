import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_room.dart';
import '../services/game_provider.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Timer? _timer;
  int _timeLeft = 30;
  int _lastQuestionIndex = -1;
  bool _answerSubmitted = false;


  @override
  void initState() {
    super.initState();
  }

  void startTimer() {
    _timeLeft = 30;
    _answerSubmitted = false;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _timer?.cancel();
          Provider.of<GameProvider>(context, listen: false).moveToNextQuestion();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        if (_lastQuestionIndex != gameProvider.currentQuestionIndex) {
          _lastQuestionIndex = gameProvider.currentQuestionIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            startTimer();
          });
        }
        final room = gameProvider.currentRoom;

        // Check for null or empty questions
        if (room?.questions == null || room!.questions.isEmpty) {
          return Scaffold(
            body: Center(
              child: Text('No questions available in this game room'),
            ),
          );
        }

        final currentQuestion = room.questions[gameProvider.currentQuestionIndex];

        return Scaffold(
          appBar: AppBar(
            title: Text('Question ${gameProvider.currentQuestionIndex + 1}'),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _timeLeft / 30,
                ),
                Text('Time left: $_timeLeft seconds'),
                SizedBox(height: 20),
                Text(
                  currentQuestion.question,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ...currentQuestion.answers.map(
                      (answer) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: ElevatedButton(
                      onPressed: _answerSubmitted ? null : () async {
                        setState(() {
                          _answerSubmitted = true;
                        });
                        await gameProvider.submitAnswer(answer);
                        // Show dialog for answer correctness
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(answer == currentQuestion.correctAnswer
                                ? 'Correct Answer!'
                                : 'Wrong Answer'),
                            content: Text(answer == currentQuestion.correctAnswer
                                ? 'Great job!'
                                : 'The correct answer was: ${currentQuestion.correctAnswer}'),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                      ),
                      child: Text(answer),
                    ),
                  ),
                ),
                Spacer(),
                buildLeaderboard(room),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildLeaderboard(GameRoom? room) {
    if (room == null) return SizedBox();

    final sortedPlayers = [...room.players]
      ..sort((a, b) => b.score.compareTo(a.score));

    return Container(
      height: 200,
      child: Card(
        child: ListView.builder(
          itemCount: sortedPlayers.length,
          itemBuilder: (context, index) {
            final player = sortedPlayers[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(player.name),
              trailing: Text('${player.score} pts'),
            );
          },
        ),
      ),
    );
  }
}