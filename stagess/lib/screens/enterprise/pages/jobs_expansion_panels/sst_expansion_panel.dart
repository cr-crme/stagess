import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

final _logger = Logger('SstExpansionPanel');

class SstExpansionPanel extends ExpansionPanel {
  SstExpansionPanel({
    required super.isExpanded,
    required Enterprise enterprise,
  }) : super(
          canTapOnHeader: true,
          body: _SstBody(enterprise),
          headerBuilder: (context, isExpanded) => const ListTile(
            title: Text('Repérage des risques SST'),
          ),
        );
}

class _SstBody extends StatelessWidget {
  const _SstBody(this.enterprise);

  final Enterprise enterprise;

  @override
  Widget build(BuildContext context) {
    _logger
        .finer('Building SstExpansionPanel for enterprise: ${enterprise.name}');

    final internships = InternshipsProvider.of(context, listen: true);
    // TODO CHANGE THIS FOR COLLECTION OF RESULTS
    final internship =
        internships.firstWhereOrNull((e) => e.enterpriseId == enterprise.id);

    return SizedBox(
      width: Size.infinite.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(internship?.sstEvaluation?.isFilled ?? false
                ? 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» a '
                    'été rempli pour ce poste de travail.\n'
                    'Dernière modification le '
                    '${DateFormat.yMMMEd('fr_CA').format(internship!.sstEvaluation!.date)}'
                : 'Le questionnaire «\u00a0Repérer les risques SST\u00a0» n\'a '
                    'jamais été rempli pour ce poste de travail.'),
            const SizedBox(height: 12),
            _buildAnswers(context, enterprise, internship),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswers(
      BuildContext context, Enterprise enterprise, Internship? internship) {
    final job =
        enterprise.jobs.firstWhereOrNull((e) => e.id == internship?.jobId);
    if (job == null ||
        internship?.sstEvaluation == null ||
        !internship!.sstEvaluation!.isFilled) {
      return SizedBox.shrink();
    }

    final questionIds = [...job.specialization.questions.map((e) => e)];
    final questions =
        questionIds.map((e) => QuestionFileService.fromId(e)).toList();
    questions.sort((a, b) => int.parse(a.idSummary) - int.parse(b.idSummary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: questions.map((q) {
        final answer = internship.sstEvaluation!.questions['Q${q.id}'];
        final answerT = internship.sstEvaluation!.questions['Q${q.id}+t'];
        if ((q.questionSummary == null && q.followUpQuestionSummary == null) ||
            (answer == null && answerT == null)) {
          return Container();
        }

        late Widget question;
        late Widget answerWidget;
        if (q.followUpQuestionSummary == null) {
          question = Text(
            q.questionSummary!,
            style: Theme.of(context).textTheme.titleSmall,
          );

          switch (q.type) {
            case QuestionType.radio:
              answerWidget = Text(
                answer!.first,
                style: Theme.of(context).textTheme.bodyMedium,
              );
              break;
            case QuestionType.checkbox:
              if (answer!.isEmpty ||
                  answer[0] == '__NOT_APPLICABLE_INTERNAL__') {
                return Container();
              }
              answerWidget = ItemizedText(answer);
              break;
            case QuestionType.text:
              answerWidget = Text(answer!.first);
              break;
          }
        } else {
          if (q.type == QuestionType.checkbox || q.type == QuestionType.text) {
            throw 'Showing follow up question for Checkbox or Text '
                'is not implemented yet';
          }

          if (answer!.first == q.choices!.last) {
            // No follow up question was needed
            return Container();
          }

          question = question = Text(
            q.followUpQuestionSummary!,
            style: Theme.of(context).textTheme.titleSmall,
          );
          answerWidget = Text(
            answerT?.first ?? 'Aucune réponse fournie',
            style: Theme.of(context).textTheme.bodyMedium,
          );
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
