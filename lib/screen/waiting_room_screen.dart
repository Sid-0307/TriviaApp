import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_room.dart';
import '../models/player.dart';
import '../services/game_provider.dart';

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final room = gameProvider.currentRoom;
        final isHost = room?.hostId == gameProvider.currentPlayer?.id;

        // Filter active players
        final activePlayers = room?.players.toList() ?? [];

        // final players = room?.players.toList();
        //
        // final players = List<Player>.from(room!.players);

        if (gameProvider.currentRoom?.status == GameStatus.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/game');
          });
        }

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.amber,
            title: Text(
              'Waiting Room',
              style: TextStyle(color: Colors.black),
            ),
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          body: Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Room Code Section
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

                // Players Count
                Text(
                  'Players (${activePlayers.length})',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // Players List
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: activePlayers.length,
                      // In WaitingRoomScreen.dart, modify the ListView.builder:
                      itemBuilder: (context, index) {
                        final player = activePlayers[index];
                        final isCurrentPlayer = player.id == gameProvider.currentPlayer?.id;
                        final isHostPlayer = player.id == room?.hostId;
                        final isHost = room?.hostId == gameProvider.currentPlayer?.id;

                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrentPlayer
                                ? Colors.amber.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.person,
                              color: Colors.amber,
                            ),
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
                                if (isHost && !isHostPlayer) // Show kick button only for host and non-host players
                                  IconButton(
                                    icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                                    onPressed: () {
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
                                    },
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

                // Start Game Button for Host
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
                        await gameProvider.startGame();
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