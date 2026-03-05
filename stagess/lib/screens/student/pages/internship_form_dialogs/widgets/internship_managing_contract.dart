import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/forms/internship_managing_contract_form_dialog.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/pdf/internship_contract_pdf_template.dart';
import 'package:stagess/screens/student/pages/internship_form_dialogs/widgets/internship_evaluation_card.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

final _logger = Logger('InternshipManagingContract');

class InternshipManagingContract extends StatelessWidget {
  const InternshipManagingContract({super.key, required this.internshipId});

  final String internshipId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building InternshipManagingContract for job: $internshipId');

    final contracts =
        InternshipsProvider.of(context).fromId(internshipId).contracts;
    return InternshipEvaluationCard(
        title: 'Détails du stage',
        header: contracts.isEmpty
            ? 'Aucun stage enregistré.'
            : 'Un contrat de stage a été créé pour ce stage le\u00a0: '
                '${DateFormat.yMMMEd('fr_CA').format(contracts.first.date)}'
                '${contracts.length > 1 ? '\nDernière modification le\u00a0: ${DateFormat.yMMMEd('fr_CA').format(contracts.last.date)}' : ''}',
        internshipId: internshipId,
        evaluateButtonText: 'Évaluer l\'entreprise',
        reevaluateButtonText: 'Modifier le contrat',
        evaluations: contracts,
        onClickedNewEvaluation: () => showInternshipEvaluationFormDialog(context,
            internshipId: internshipId,
            showEvaluationDialog: (BuildContext context,
                    {required String internshipId, String? evaluationId}) =>
                showManagingContractFormDialog(context,
                    internship: InternshipsProvider.of(context, listen: false)
                        .fromId(internshipId),
                    isNewContract: false)),
        onClickedShowEvaluation: (contractId) => showInternshipEvaluationFormDialog(
            context,
            internshipId: internshipId,
            evaluationId: contractId,
            showEvaluationDialog: (BuildContext context,
                    {required String internshipId, String? evaluationId}) =>
                showManagingContractFormDialog(context,
                    internship: InternshipsProvider.of(context, listen: false).fromId(internshipId),
                    evaluationId: evaluationId,
                    isNewContract: false)),
        onClickedShowEvaluationPdf: (contractId) => showPdfDialog(
              context,
              pdfGeneratorCallback: (context, format) =>
                  generateInternshipContractPdf(context, format,
                      internshipId: internshipId, contractId: contractId),
            ));
  }
}
