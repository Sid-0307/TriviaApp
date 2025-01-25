import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_provider.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  _JoinRoomScreenState createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Join Room')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Room Code',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty && _codeController.text.isNotEmpty) {
                  try {
                    final gameProvider = context.read<GameProvider>();
                    await gameProvider.joinRoom(
                        _codeController.text.toUpperCase(),
                        _nameController.text
                    );
                    print("Room code: ${gameProvider.currentRoom?.roomCode}"); // Debug
                    Navigator.pushReplacementNamed(context, '/waiting-room');
                  } catch (e) {
                    print("Error: $e"); // Debug
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: Text('Join Room'),
            ),
          ],
        ),
      ),
    );
  }
}