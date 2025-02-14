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

        // Game Over and other conditions remain the same...
        if (room?.status == GameStatus.finished) {
          // ... existing game over code ...
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
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: buildLeaderboard(room),
                  ),
                  if (room?.hostId == gameProvider.currentPlayer?.id)
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
            ),
          );
        }

        if (_lastQuestionIndex != gameProvider.currentQuestionIndex) {
          _lastQuestionIndex = gameProvider.currentQuestionIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            startTimer();
          });
        }

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
          body: SafeArea(
            child: Column(
              children: [
                // Timer Section (Fixed at top)
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _timeLeft / 15,
                        backgroundColor: Colors.amber.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Time left: $_timeLeft seconds',
                        style: TextStyle(color: Colors.amber),
                      ),
                    ],
                  ),
                ),

                // Question and Options Section (Expanded with even spacing)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Question Text
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxHeight * 0.3,
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  currentQuestion.question,
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),

                            // Answer Options
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: constraints.maxHeight * 0.6,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: currentQuestion.answers.map(
                                      (answer) => ElevatedButton(
                                    onPressed: _answerSubmitted ? null : () async {
                                      setState(() {
                                        _answerSubmitted = true;
                                      });
                                      await gameProvider.submitAnswer(answer);
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
                                    child: Text(
                                      answer,
                                      style: TextStyle(fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ).toList(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Leaderboard Section (Fixed at bottom)
                Container(
                  height: 200,
                  padding: EdgeInsets.all(16.0),
                  child: buildLeaderboard(room),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // buildLeaderboard method remains the same...
  Widget buildLeaderboard(GameRoom? room) {
    if (room == null) return SizedBox();

    final sortedPlayers = [...room.players]
      ..sort((a, b) => b.score.compareTo(a.score));

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          physics: ClampingScrollPhysics(),
          shrinkWrap: true,
          itemCount: sortedPlayers.length,
          itemBuilder: (context, index) {
            final player = sortedPlayers[index];
            return Container(
              color: index.isEven ? Colors.grey[900] : Colors.black,
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  backgroundColor: Colors.amber,
                  radius: 15,
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ),
                title: Text(
                  player.name,
                  style: TextStyle(color: Colors.amber, fontSize: 14),
                ),
                trailing: Text(
                  '${player.score} pts',
                  style: TextStyle(color: Colors.amber, fontSize: 14),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}