import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common_flutter/helpers/program_helpers.dart';
import 'package:stagess_common_flutter/services/question_file_service.dart';

void main() {
  group('QuestionFileService', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    ProgramInitializer.initialize(
      useQuestionFileService: true,
    );

    test('questions are loaded properly', () async {
      await QuestionFileService.loadData();
      expect(QuestionFileService.questions, isNotEmpty);
    });

    test('can get a question by id', () async {
      await QuestionFileService.loadData();

      final question = QuestionFileService.questions[0];
      expect(QuestionFileService.fromId(question.id), question);

      // Throw if not found
      expect(() => QuestionFileService.fromId('not found'), throwsStateError);
    });

    test('can serialize and deserialize a question', () async {
      await QuestionFileService.loadData();

      final serialized = QuestionFileService.serializeList();
      final question = Question.fromSerialized(serialized[0]);

      expect(question.id, QuestionFileService.questions[0].id);
      expect(question.idSummary, QuestionFileService.questions[0].idSummary);
      expect(question.question, QuestionFileService.questions[0].question);
      expect(question.questionSummary,
          QuestionFileService.questions[0].questionSummary);
      expect(question.type, QuestionFileService.questions[0].type);
      expect(question.hasOther, QuestionFileService.questions[0].hasOther);
      expect(question.choices, QuestionFileService.questions[0].choices);
      expect(question.followUpQuestion,
          QuestionFileService.questions[0].followUpQuestion);
      expect(question.followUpQuestionSummary,
          QuestionFileService.questions[0].followUpQuestionSummary);
    });
  });
}
