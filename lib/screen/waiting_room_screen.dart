import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_room.dart';
import '../models/player.dart';
import '../services/game_provider.dart';
import '../services/trivia_service.dart';

class WaitingRoomScreen extends StatefulWidget {
  const WaitingRoomScreen({super.key});

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  final TextEditingController _questionCountController = TextEditingController(text: '5');
  TriviaCategory _selectedCategory = TriviaCategory.sports;
  TriviaDifficulty _selectedDifficulty = TriviaDifficulty.easy;

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Game Settings',
                style: TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text("Questions", style: TextStyle(color: Colors.amber)),
                  ),
                  SizedBox(width: 10),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _questionCountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(color: Colors.amber),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text("Category", style: TextStyle(color: Colors.amber)),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<TriviaCategory>(
                      value: _selectedCategory,
                      dropdownColor: Colors.black,
                      style: TextStyle(color: Colors.amber),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                      ),
                      items: TriviaCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text("Difficulty", style: TextStyle(color: Colors.amber)),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<TriviaDifficulty>(
                      value: _selectedDifficulty,
                      dropdownColor: Colors.black,
                      style: TextStyle(color: Colors.amber),
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber),
                        ),
                      ),
                      items: TriviaDifficulty.values.map((difficulty) {
                        return DropdownMenuItem(
                          value: difficulty,
                          child: Text(difficulty.display),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showKickDialog(BuildContext context, GameProvider gameProvider, Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black,
        title: Text(
          'Kick Player',
          style: TextStyle(color: Colors.amber),
        ),
        content: Text(
          'Are you sure you want to kick ${player.name}?',
          style: TextStyle(color: Colors.amber),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.amber)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              gameProvider.kickPlayer(player.id);
            },
            child: Text('Kick', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final room = gameProvider.currentRoom;
        final isHost = room?.hostId == gameProvider.currentPlayer?.id;
        final activePlayers = room?.players.toList() ?? [];

        if (gameProvider.currentRoom?.status == GameStatus.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/game');
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.amber,
            title: Text('Waiting Room', style: TextStyle(color: Colors.black)),
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black),
            actions: isHost ? [
              IconButton(
                icon: Icon(Icons.settings),
                onPressed: () => _showSettingsModal(context),
              ),
            ] : null,
          ),
          body: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Room Code: ${room?.roomCode}',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.amber),
                        onPressed: () {
                          if (room?.roomCode != null) {
                            Clipboard.setData(ClipboardData(text: room!.roomCode));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Room code copied!')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Players (${activePlayers.length})',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: activePlayers.length,
                      itemBuilder: (context, index) {
                        final player = activePlayers[index];
                        final isCurrentPlayer = player.id == gameProvider.currentPlayer?.id;
                        final isHostPlayer = player.id == room?.hostId;

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrentPlayer
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.person, color: Colors.amber),
                            title: Text(
                              player.name,
                              style: TextStyle(
                                color: Colors.amber,
                                fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isHostPlayer)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Host',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                if (isHost && !isHostPlayer)
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () => _showKickDialog(context, gameProvider, player),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24),
                if (isHost)
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: activePlayers.length >= 2
                          ? () async {
                        final questionCount = int.tryParse(_questionCountController.text) ?? 5;
                        await gameProvider.startGame(
                          count: questionCount,
                          category: _selectedCategory,
                          difficulty: _selectedDifficulty,
                        );
                      }
                          : null,
                      child: Text(
                        activePlayers.length >= 2
                            ? 'Start Game'
                            : 'Waiting for more players...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}