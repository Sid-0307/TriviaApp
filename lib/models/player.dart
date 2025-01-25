import 'package:flutter/material.dart';

class Player {
  final String id;
  final String name;
  int score;

  Player({
    required this.id,
    required this.name,
    this.score = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'score': score,
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'],
      name: json['name'],
      score: json['score'] ?? 0,
    );
  }
}
