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
  int _timeLeft = 15;
  int _lastQuestionIndex = -1;
  bool _answerSubmitted = false;

  @override
  void initState() {
    super.initState();
  }

  void startTimer() {
    _timeLeft = 15;
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
        final room = gameProvider.currentRoom;

        if(room?.status == GameStatus.waiting){
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/loader');
          });
        }



        if (room?.status == GameStatus.finished) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              title: Text(
                'Game Over',
                style: TextStyle(color: Colors.amber),
              ),
              automaticallyImplyLeading: false,
            ),
            body: Column(
              children: [
                Expanded(
                  child: buildLeaderboard(room),
                ),
                if (room?.hostId == gameProvider.currentPlayer?.id) // Only show for host
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: () async {
                        await gameProvider.rejoinWaitingRoom(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Back to Room'),
                    ),
                  ),
              ],
            ),
          );
        }

        if (_lastQuestionIndex != gameProvider.currentQuestionIndex) {
          _lastQuestionIndex = gameProvider.currentQuestionIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            startTimer();
          });
        }

        // Check for null or empty questions
        if (room?.questions == null || room!.questions.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                'No questions available in this game room',
                style: TextStyle(color: Colors.amber),
              ),
            ),
          );
        }

        final currentQuestion = room.questions[gameProvider.currentQuestionIndex];

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.amber,
            title: Text(
              'Question ${gameProvider.currentQuestionIndex + 1} of ${gameProvider.questions.length}',
              style: TextStyle(color: Colors.black),
            ),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              children: [
                LinearProgressIndicator(
                  value: _timeLeft / 15,
                  backgroundColor: Colors.amber.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                ),
                Text(
                  'Time left: $_timeLeft seconds',
                  style: TextStyle(color: Colors.amber),
                ),
                SizedBox(height: 40),
                Text(
                  currentQuestion.question,
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                ...currentQuestion.answers.map(
                      (answer) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
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
                            backgroundColor: Colors.black,
                            title: Text(
                              answer == currentQuestion.correctAnswer
                                  ? 'Correct Answer!'
                                  : 'Wrong Answer',
                              style: TextStyle(color: Colors.amber),
                            ),
                            content: Text(
                              answer == currentQuestion.correctAnswer
                                  ? 'Great job!'
                                  : 'The correct answer was: ${currentQuestion.correctAnswer}',
                              style: TextStyle(color: Colors.amber),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        disabledBackgroundColor: Colors.grey[800],
                        disabledForegroundColor: Colors.grey[500],
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(answer,style: TextStyle(fontSize: 16),),
                    ),
                  ),
                ),
                SizedBox(height: 20),
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
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListView.builder(
        itemCount: sortedPlayers.length,
        itemBuilder: (context, index) {
          final player = sortedPlayers[index];
          return ListTile(
            tileColor: index.isEven ? Colors.grey[800] : Colors.black,
            leading: CircleAvatar(
              backgroundColor: Colors.amber,
              child: Text(
                '${index + 1}',
                style: TextStyle(color: Colors.black),
              ),
            ),
            title: Text(
              player.name,
              style: TextStyle(color: Colors.amber),
            ),
            trailing: Text(
              '${player.score} pts',
              style: TextStyle(color: Colors.amber),
            ),
          );
        },
      ),
    );
  }
}