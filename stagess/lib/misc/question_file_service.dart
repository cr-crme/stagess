import 'dart:convert';

import 'package:enhanced_containers/enhanced_containers.dart';
import 'package:flutter/services.dart';

abstract class QuestionFileService {
  static Future<void> loadData() async {
    final file = await rootBundle.loadString('assets/questions.json');
    final json = jsonDecode(file) as List;

    _questions = List.from(
      json.map((e) => Question.fromSerialized(e)),
      growable: false,
    );
  }

  static Question fromId(String id) {
    return _questions.firstWhere((question) => question.id == id);
  }

  static List<Question> get questions => _questions;

  static List<Question> _questions = [];

  static List serializeList() {
    return _questions.map((e) => e.serialize()).toList();
  }
}

class Question extends ItemSerializable {
  final String idSummary;
  final String question;
  final String? questionSummary;
  final QuestionType type;
  final bool hasOther;
  final Set<String>? choices;
  final String? followUpQuestion;
  final String? followUpQuestionSummary;

  Question.fromSerialized(super.map)
    : idSummary = map?['idSummary'],
      question = map?['question'],
      questionSummary = map?['summary'],
      type = QuestionType.fromSerialized(map?['type']),
      hasOther = map?['hasOther'] == 'Oui',
      choices =
          map?['choices'] == null
              ? null
              : Set.from(
                (map?['choices'] as List).map((e) => (e as String).trim()),
              ),
      followUpQuestion = map?['followUp'],
      followUpQuestionSummary = map?['followUpSummary'],
      super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() => {
    'idSummary': idSummary,
    'question': question,
    'summary': questionSummary,
    'type': type.toString(),
    'hasOther': hasOther ? 'Oui' : 'Non',
    'choices': choices?.toList(),
    'followUp': followUpQuestion,
    'followUpSummary': followUpQuestionSummary,
  };
}

enum QuestionType {
  text,
  radio,
  checkbox;

  static QuestionType fromSerialized(data) {
    switch (data) {
      case 'Texte':
        return QuestionType.text;
      case 'Choix de réponse':
        return QuestionType.checkbox;
      case 'Vrai ou Faux':
        return QuestionType.radio;
      default:
        throw 'Wrong format';
    }
  }

  @override
  String toString() {
    switch (this) {
      case QuestionType.text:
        return 'Texte';
      case QuestionType.checkbox:
        return 'Choix de réponse';
      case QuestionType.radio:
        return 'Vrai ou Faux';
    }
  }
}
