import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';

final _logger = Logger('SstExpansionPanel');

class SstExpansionPanel extends ExpansionPanel {
  SstExpansionPanel({
    required super.isExpanded,
    required Enterprise enterprise,
    required String jobId,
  }) : super(
          canTapOnHeader: true,
          body: _SstBody(enterprise, jobId: jobId),
          headerBuilder: (context, isExpanded) => const ListTile(
            title: Text('Repérage des risques SST'),
          ),
        );
}

class _SstBody extends StatelessWidget {
  const _SstBody(this.enterprise, {required this.jobId});

  final Enterprise enterprise;
  final String jobId;

  @override
  Widget build(BuildContext context) {
    _logger
        .finer('Building SstExpansionPanel for enterprise: ${enterprise.name}');

    final internships = InternshipsProvider.of(context, listen: true).where(
        (e) =>
            e.sstEvaluation != null &&
            e.enterpriseId == enterprise.id &&
            e.jobId == jobId);
    final latestInternship = internships.isNotEmpty
        ? internships.reduce((a, b) =>
            a.sstEvaluation!.date.isAfter(b.sstEvaluation!.date) ? a : b)
        : null;

    return SizedBox(
      width: Size.infinite.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(internships.isNotEmpty
                ? 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» a '
                    'été rempli pour ce poste de travail.\n'
                    'Dernière modification le '
                    '${DateFormat.yMMMEd('fr_CA').format(latestInternship!.sstEvaluation!.date)}'
                : 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» n\'a '
                    'jamais été rempli pour ce poste de travail.'),
            const SizedBox(height: 12),
            _buildAnswers(context, internships),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswers(BuildContext context, Iterable<Internship> internships) {
    final evaluatedJobs =
        enterprise.jobs.where((j) => internships.any((i) => i.jobId == j.id));
    final questionIds = evaluatedJobs
        .map((e) => e.specialization.questions)
        .expand((x) => x)
        .toSet();

    final questions =
        questionIds.map((e) => QuestionFileService.fromId(e)).toList();
    questions.sort((a, b) => int.parse(a.idSummary) - int.parse(b.idSummary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.map((q) {
        if (q.questionSummary == null && q.followUpQuestionSummary == null) {
          return SizedBox.shrink();
        }

        final answers = internships
            .map((e) => e.sstEvaluation!.questions['Q${q.id}'] ?? [])
            .expand((x) => x)
            .toSet()
            .toList();
        final answerT = internships
            .map((e) => e.sstEvaluation!.questions['Q${q.id}+t'] ?? [])
            .expand((x) => x)
            .toSet()
            .toList();
        if (answers.isEmpty && answerT.isEmpty) return SizedBox.shrink();

        late Widget question;
        late Widget answerWidget;
        if (q.followUpQuestionSummary == null) {
          question = Text(
            q.questionSummary!,
            style: Theme.of(context).textTheme.titleSmall,
          );

          switch (q.type) {
            case QuestionType.radio:
              // TODO Confirm that all answers should be shown for radio
              answerWidget = ItemizedText(answers);
              break;
            case QuestionType.checkbox:
              final filteredAnswers = answers
                  .where((a) => a != CheckboxWithOther.notApplicableTag)
                  .toList();
              if (filteredAnswers.isEmpty) return SizedBox.shrink();

              answerWidget = ItemizedText(filteredAnswers);
              break;
            case QuestionType.text:
              answerWidget = ItemizedText(answerT);
              break;
          }
        } else {
          if (q.type == QuestionType.checkbox || q.type == QuestionType.text) {
            throw 'Showing follow up question for Checkbox or Text '
                'is not implemented yet';
          }

          // Check if no follow up question was needed (e.g. answer is "no")
          if (answers.every((e) => e == q.choices!.last)) {
            return SizedBox.shrink();
          }

          question = Text(
            q.followUpQuestionSummary!,
            style: Theme.of(context).textTheme.titleSmall,
          );
          answerWidget = answerT.isEmpty
              ? Text(
                  'Aucune réponse fournie',
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              : ItemizedText(answerT);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            question,
            answerWidget,
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}
