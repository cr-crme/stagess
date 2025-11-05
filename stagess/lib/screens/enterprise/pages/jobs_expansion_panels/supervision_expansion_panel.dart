import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/job_extension.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/form_fields/low_high_slider_form_field.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/screens/internship_forms/enterprise_steps/supervision_step.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('SupervisionExpansionPanel');

double _meanOf(
    List list, double Function(PostInternshipEnterpriseEvaluation) value) {
  var runningSum = 0.0;
  var nElements = 0;
  for (final e in list) {
    final valueTp = value(e);
    if (valueTp < 0) continue;
    runningSum += valueTp;
    nElements++;
  }
  return nElements == 0 ? -1 : runningSum / nElements;
}

class SupervisionExpansionPanel extends ExpansionPanel {
  SupervisionExpansionPanel({
    required super.isExpanded,
    required Job job,
  }) : super(
          canTapOnHeader: true,
          body: _SupervisionBody(job: job),
          headerBuilder: (context, isExpanded) => ListTile(
            title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Encadrement des stagiaires'),
                  if (isExpanded) _buildInfoButton(context),
                ]),
          ),
        );

  static Widget _buildInfoButton(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: () => showSnackBar(context,
              message: 'Les résultats sont le cumul des '
                  'évaluations des personnes ayant '
                  'supervisé des stagiaires dans cette entreprise. '
                  '\nIls sont différenciés entre stages '
                  'FMS et FPT.'),
          child: Icon(
            Icons.info,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}

Widget _printCountedList<T>(Iterable<T> iterable, String Function(T) toString) {
  var out = iterable.map<String>((e) => toString(e)).toList();

  out = out
      .toSet()
      .map((e) =>
          '$e (${out.fold<int>(0, (prev, e2) => prev + (e == e2 ? 1 : 0))})')
      .toList();
  return ItemizedText(out);
}

class _SupervisionBody extends StatefulWidget {
  const _SupervisionBody({required this.job});

  final Job job;

  @override
  State<_SupervisionBody> createState() => _SupervisionBodyState();
}

class _SupervisionBodyState extends State<_SupervisionBody> {
  var _currentProgramToShow = Program.fms;

  List<PostInternshipEnterpriseEvaluation> _getFilteredEvaluations() {
    final internships = InternshipsProvider.of(context);
    final students = StudentsHelpers.studentsInMyGroups(context);
    var evaluations = widget.job.postInternshipEnterpriseEvaluations(context);

    // Only keep evaluations from the requested students
    return evaluations.where((eval) {
      final internship = internships.fromIdOrNull(eval.internshipId);
      if (internship == null) return false;
      final student = students
          .firstWhereOrNull((student) => student.id == internship.studentId);
      return student?.program == _currentProgramToShow;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building SupervisionExpansionPanel for job: ${widget.job.specialization.name}');

    final evaluations = _getFilteredEvaluations();

    return Column(
      children: [
        _buildStudentSelector(),
        Padding(
          padding: const EdgeInsets.only(left: 24.0, right: 24, top: 8),
          child: evaluations.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 12.0),
                    child: Text(
                        'L\'entreprise n\'a pas encore été évaluée pour des '
                        'élèves de $_currentProgramToShow.'),
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTaskVariety(evaluations),
                    const SizedBox(height: 12),
                    _buildTrainingPlanRespect(evaluations),
                    const SizedBox(height: 12),
                    _buildSkillsRequired(evaluations),
                    const SizedBox(height: 12),
                    _buildAutonomy(evaluations),
                    const SizedBox(height: 12),
                    _buildEfficiency(evaluations),
                    const SizedBox(height: 12),
                    _buildSupervisionStyle(evaluations),
                    const SizedBox(height: 12),
                    _buildEaseOfCommunication(evaluations),
                    const SizedBox(height: 12),
                    _buildAbsenceAcceptance(evaluations),
                    const SizedBox(height: 12),
                    Visibility(
                      visible: evaluations.any((e) => e.hasDisorder),
                      child: Text(
                        'Évaluation de l\'accueil de stagiaires avec',
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _buildAcceptanceTsa(evaluations),
                    _buildAcceptanceLanguageDeficiency(evaluations),
                    _buildAcceptanceMentalDeficiency(evaluations),
                    _buildAcceptancePhysicalDeficiency(evaluations),
                    _buildAcceptanceMentalHealtyIssue(evaluations),
                    _buildAcceptanceBehaviorIssue(evaluations),
                    _buildComments(context, evaluations),
                    const SizedBox(height: 12),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStudentSelector() {
    return Row(
      children: [
        Expanded(
          child: _FilterTile(
            title: 'Élèves FMS',
            onTap: () => setState(() => _currentProgramToShow = Program.fms),
            isSelected: _currentProgramToShow == Program.fms,
          ),
        ),
        Expanded(
          child: _FilterTile(
            title: 'Élèves FPT',
            onTap: () => setState(() => _currentProgramToShow = Program.fpt),
            isSelected: _currentProgramToShow == Program.fpt,
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptanceTsa(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _RatingBar(
      title: 'Un trouble du spectre de l\'autisme (TSA)',
      rating: _meanOf(evaluations, (e) => e.acceptanceTsa),
    );
  }

  Widget _buildAcceptanceLanguageDeficiency(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _RatingBar(
      title: 'Un trouble du langage',
      rating: _meanOf(evaluations, (e) => e.acceptanceLanguageDisorder),
    );
  }

  Widget _buildAcceptanceMentalDeficiency(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _RatingBar(
      title: 'Une déficience intellectuelle',
      rating: _meanOf(evaluations, (e) => e.acceptanceIntellectualDisability),
    );
  }

  Widget _buildAcceptancePhysicalDeficiency(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _RatingBar(
      title: 'Une déficience physique',
      rating: _meanOf(evaluations, (e) => e.acceptancePhysicalDisability),
    );
  }

  Widget _buildAcceptanceMentalHealtyIssue(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _RatingBar(
      title: 'Un trouble de santé mentale',
      rating: _meanOf(evaluations, (e) => e.acceptanceMentalHealthDisorder),
    );
  }

  Widget _buildAcceptanceBehaviorIssue(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _RatingBar(
      title: 'Des difficultés comportementales',
      rating: _meanOf(evaluations, (e) => e.acceptanceBehaviorDifficulties),
    );
  }

  Widget _buildComments(BuildContext context,
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    final comments = evaluations
        .map((e) => e.supervisionComments)
        .where((e) => e != '')
        .toList();
    return comments.isEmpty
        ? Container()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Autres commentaires sur l\'encadrement',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ItemizedText(comments),
            ],
          );
  }

  Widget _buildTaskVariety(
      Iterable<PostInternshipEnterpriseEvaluation> evaluations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tâches données à l\'élève',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        _printCountedList<PostInternshipEnterpriseEvaluation>(evaluations,
            (e) => e.taskVariety == 0 ? 'Peu variées' : 'Très variées'),
      ],
    );
  }

  Widget _buildTrainingPlanRespect(
      Iterable<PostInternshipEnterpriseEvaluation> evaluations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Plan de formation\n'
          'Tâches et compétences prévues dans le plan ont été faites par l\'élève',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        _printCountedList<PostInternshipEnterpriseEvaluation>(evaluations,
            (e) => e.trainingPlanRespect == 0 ? 'En partie' : 'En totalité'),
      ],
    );
  }

  Widget _buildSkillsRequired(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    final List<String> allSkills =
        evaluations.expand((eval) => eval.skillsRequired).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Habiletés requises pour le stage',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        _printCountedList<String>(allSkills, (e) => e),
      ],
    );
  }

  Widget _buildAutonomy(List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      title: 'Niveau d\'autonomie souhaité',
      value: _meanOf(evaluations, (e) => e.autonomyExpected),
      lowLabel: labelAutonomyExpected[0],
      highLabel: labelAutonomyExpected[1],
    );
  }

  Widget _buildEfficiency(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      title: 'Rendement de l\'élève attendu',
      value: _meanOf(evaluations, (e) => e.efficiencyExpected),
      lowLabel: labelEfficiencyExpected[0],
      highLabel: labelEfficiencyExpected[1],
    );
  }

  Widget _buildSupervisionStyle(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      title: 'Type d\'encadrement',
      value: _meanOf(evaluations, (e) => e.supervisionStyle),
      lowLabel: labelSupervisionStyle[0],
      highLabel: labelSupervisionStyle[1],
    );
  }

  Widget _buildEaseOfCommunication(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      title: 'Communication avec l\'entreprise',
      value: _meanOf(evaluations, (e) => e.easeOfCommunication),
      lowLabel: labelEaseOfCommunication[0],
      highLabel: labelEaseOfCommunication[1],
    );
  }

  Widget _buildAbsenceAcceptance(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      title:
          'Tolérance du milieu à l\'égard des retards et absences de l\'élève',
      value: _meanOf(evaluations, (e) => e.absenceAcceptance),
      lowLabel: labelAbsenceAcceptance[0],
      highLabel: labelAbsenceAcceptance[1],
    );
  }
}

class _TitledFixSlider extends StatelessWidget {
  const _TitledFixSlider({
    required this.title,
    required this.value,
    required this.lowLabel,
    required this.highLabel,
  });

  final String title;
  final double value;
  final String lowLabel;
  final String highLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        LowHighSliderFormField(
          initialValue: value,
          decimal: 1,
          fixed: true,
          lowLabel: lowLabel,
          highLabel: highLabel,
        ),
      ],
    );
  }
}

class _RatingBar extends StatelessWidget {
  const _RatingBar({
    required this.title,
    required this.rating,
  });

  final String title;
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: rating >= 0 && rating <= 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          RatingBar(
            initialRating: rating,
            onRatingUpdate: (value) {},
            allowHalfRating: true,
            ignoreGestures: true,
            ratingWidget: RatingWidget(
              full: Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.secondary,
              ),
              half: Icon(
                Icons.star_half,
                color: Theme.of(context).colorScheme.secondary,
              ),
              empty: Icon(
                Icons.star_border,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        color:
            isSelected ? Theme.of(context).primaryColor.withAlpha(150) : null,
        child: Row(
          children: [
            const SizedBox(height: 48, width: 12),
            Text(
              title,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: isSelected ? Colors.white : null),
            ),
          ],
        ),
      ),
    );
  }
}
