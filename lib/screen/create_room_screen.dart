import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_provider.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  _CreateRoomScreenState createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Room')),
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
            ElevatedButton(
              onPressed: () async {
                if (_nameController.text.isNotEmpty) {
                  final gameProvider = context.read<GameProvider>();
                  await gameProvider.createRoom(_nameController.text);
                  Navigator.pushReplacementNamed(context, '/waiting-room');
                }
              },
              child: Text('Create Room'),
            ),
          ],
        ),
      ),
    );
  }
}