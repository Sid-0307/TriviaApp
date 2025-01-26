import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_room.dart';
import '../services/game_provider.dart';

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {
        final room = gameProvider.currentRoom;
        final isHost = room?.hostId == gameProvider.currentPlayer?.id;

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
                Row(
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
                SizedBox(height: 20),
                Text(
                  'Players:',
                  style: TextStyle(color: Colors.amber),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: room?.players.length ?? 0,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          room!.players[index].name,
                          style: TextStyle(color: Colors.amber),
                        ),
                        tileColor: Colors.black,
                      );
                    },
                  ),
                ),
                if (isHost)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () async {
                      await gameProvider.startGame();
                    },
                    child: Text('Start Game'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}