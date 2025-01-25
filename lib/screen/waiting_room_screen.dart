import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_room.dart';
import '../services/game_provider.dart';

class WaitingRoomScreen extends StatelessWidget {
  const WaitingRoomScreen({super.key});



  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, gameProvider, _) {

        if (gameProvider.currentRoom?.status == GameStatus.playing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacementNamed(context, '/game');
          });
        }

        final room = gameProvider.currentRoom;
        final isHost = room?.hostId == gameProvider.currentPlayer?.id;

        return Scaffold(
          appBar: AppBar(
            title: Text('Waiting Room'),
            automaticallyImplyLeading: false,
          ),
          body: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Room Code: ${room?.roomCode}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                SizedBox(height: 20),
                Text('Players:'),
                Expanded(
                  child: ListView.builder(
                    itemCount: room?.players.length ?? 0,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(room!.players[index].name),
                      );
                    },
                  ),
                ),
                if (isHost)
                  ElevatedButton(
                    onPressed: () async {
                      await gameProvider.startGame();
                      // Navigator.pushReplacementNamed(context, '/game');
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