import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:trivia_game/screen/create_room_screen.dart';
import 'package:trivia_game/screen/game_screen.dart';
import 'package:trivia_game/screen/home_screen.dart';
import 'package:trivia_game/screen/join_room_screen.dart';
import 'package:trivia_game/screen/waiting_room_screen.dart';
import 'package:trivia_game/services/game_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(),
      child: MaterialApp(
        title: 'Trivia Game',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/',
        routes: {
          '/': (context) => HomeScreen(),
          '/create-room': (context) => CreateRoomScreen(),
          '/join-room': (context) => JoinRoomScreen(),
          '/waiting-room': (context) => WaitingRoomScreen(),
          '/game': (context) => GameScreen(),
        },
      ),
    );
  }
}