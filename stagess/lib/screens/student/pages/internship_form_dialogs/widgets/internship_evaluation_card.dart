import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('InternshipEvaluationCard');

class InternshipEvaluationCard extends StatefulWidget {
  const InternshipEvaluationCard({
    super.key,
    required this.title,
    required this.internshipId,
    required this.evaluateButtonText,
    required this.reevaluateButtonText,
    required this.evaluations,
    required this.onClickedNewEvaluation,
    required this.onClickedShowEvaluation,
    required this.onClickedShowEvaluationPdf,
  });

  final String title;
  final String internshipId;
  final String evaluateButtonText;
  final String reevaluateButtonText;
  final List<InternshipEvaluation> evaluations;
  final Function() onClickedNewEvaluation;
  final Function(String evaluationId) onClickedShowEvaluation;
  final Function(String evaluationId) onClickedShowEvaluationPdf;

  @override
  State<InternshipEvaluationCard> createState() =>
      _InternshipEvaluationCardState();
}

class _InternshipEvaluationCardState extends State<InternshipEvaluationCard> {
  static const _interline = 12.0;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building EvaluationSkill for internship: ${widget.internshipId}',
    );

    final internship =
        InternshipsProvider.of(context).fromId(widget.internshipId);
    final teacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (ctx, isExpanded) => Text(
        widget.title,
        style: Theme.of(context)
            .textTheme
            .titleMedium!
            .copyWith(color: Colors.black),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 12.0, right: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.evaluations.isEmpty
                ? 'Aucune évaluation réalisée pour ce stage.'
                : 'Dernière évaluation réalisée le\u00a0: '
                    '${DateFormat.yMMMEd('fr_CA').format(widget.evaluations.last.date)}'),
            Visibility(
              visible: internship.supervisingTeacherIds.contains(teacherId),
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: TextButton(
                      onPressed: () => widget.onClickedNewEvaluation(),
                      child: Text(
                          widget.evaluations.isEmpty
                              ? widget.evaluateButtonText
                              : widget.reevaluateButtonText,
                          textAlign: TextAlign.center)),
                ),
              ),
            ),
            if (widget.evaluations.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: _buildSelectShowPreviousEvaluations(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectShowPreviousEvaluations() {
    final orderedEvaluations =
        widget.evaluations.reversed; // .sortedBy((e) => e.date);

    return Padding(
      padding: const EdgeInsets.only(bottom: _interline),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              widget.evaluations.length > 1
                  ? 'Afficher les évaluations du\u00a0: '
                  : 'Afficher l\'évaluation du\u00a0: ',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: orderedEvaluations.map(
              (evaluation) {
                // Reminder the list is reversed for display
                return Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: Text(
                        '\u2022 ${DateFormat('dd MMMM yyyy', 'fr_CA').format(evaluation.date)}',
                      ),
                    ),
                    IconButton(
                        onPressed: () =>
                            widget.onClickedShowEvaluation(evaluation.id),
                        color: Theme.of(context).primaryColor,
                        icon: const Icon(Icons.insert_drive_file)),
                    SizedBox(width: 4),
                    IconButton(
                        onPressed: () =>
                            widget.onClickedShowEvaluationPdf(evaluation.id),
                        color: Theme.of(context).primaryColor,
                        icon: const Icon(Icons.picture_as_pdf)),
                  ],
                );
              },
            ).toList(),
          )
        ],
      ),
    );
  }
}

Future<void> showInternshipEvaluationFormDialog(BuildContext context,
    {required String internshipId,
    String? evaluationId,
    required Future<Internship?> Function(BuildContext,
            {required String internshipId, String? evaluationId})
        showEvaluationDialog}) async {
  final editMode = evaluationId == null;
  _logger.info(
      'Showing InternshipEvaluationFormDialog for internship: $internshipId, editMode: $editMode');

  final internships = InternshipsProvider.of(context, listen: false);
  if (!context.mounted) return;

  final hasLock = await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => FutureBuilder(
      future: Future.wait([
        internships.getLockForItem(internships.fromId(internshipId)),
        internships.fetchData(id: internshipId, fields: FetchableFields.all),
      ]),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final hasLock = (snapshot.data as List).first as bool;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pop(hasLock);
          });
        }
        return Dialog(
          child: SizedBox(
            width: 100,
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        );
      },
    ),
  );

  if (!hasLock || !context.mounted) {
    _logger.warning('Could not get lock for internshipId: $internshipId');
    if (context.mounted) {
      showSnackBar(
        context,
        message:
            'Impossible de modifier le formulaire, car il est en cours de modification par un autre utilisateur.',
      );
    }
    return;
  }

  final newInternship = await showEvaluationDialog(context,
      internshipId: internshipId, evaluationId: evaluationId);
  if (!editMode) return;

  final internship = internships.fromId(internshipId);
  final isSuccess = newInternship != null &&
      await internships.replaceWithConfirmation(newInternship);
  await internships.releaseLockForItem(internship);

  if (isSuccess && context.mounted) {
    showSnackBar(context, message: 'L\'évaluation SST a bien été enregistrée.');
  }
  return;
}
