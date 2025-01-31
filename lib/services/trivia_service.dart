import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/question.dart';

class TriviaService {
  static const String baseUrl = 'https://opentdb.com/api.php';

  Future<List<TriviaQuestion>> fetchQuestions() async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl?amount=10&type=multiple')
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['response_code'] != 0) {
          throw Exception('API returned error code: ${data['response_code']}');
        }

        final questions = (data['results'] as List).map((q) {
          // Decode HTML entities in the question and answers
          final question = _decodeHtml(q['question'] as String);
          final correctAnswer = _decodeHtml(q['correct_answer'] as String);
          final incorrectAnswers = (q['incorrect_answers'] as List)
              .map((a) => _decodeHtml(a as String))
              .toList();

          return TriviaQuestion(
            question: question,
            correctAnswer: correctAnswer,
            incorrectAnswers: incorrectAnswers.cast<String>(),
          );
        }).toList();

        return questions;
      } else {
        throw Exception('Failed to load questions. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching questions: $e'); // Debug print
      throw Exception('Error fetching questions: $e');
    }
  }

  String _decodeHtml(String input) {
    // Basic HTML entity decoding
    return input
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', "&")
        .replaceAll('&lt;', "<")
        .replaceAll('&gt;', ">")
        .replaceAll('&eacute;', "é")
        .replaceAll('&Eacute;', "É")
        .replaceAll('&ntilde;', "ñ")
        .replaceAll('&Ntilde;', "Ñ")
        .replaceAll('&uuml;', "ü")
        .replaceAll('&Uuml;', "Ü");
  }
}