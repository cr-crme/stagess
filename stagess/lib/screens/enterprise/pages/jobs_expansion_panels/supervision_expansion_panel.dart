import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/job_extension.dart';
import 'package:stagess/common/widgets/form_fields/low_high_slider_form_field.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/screens/student/pages/form_dialogs/forms/enterprise_evaluation_form_enums.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/internships/post_internship_enterprise_evaluation.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('SupervisionExpansionPanel');

class SupervisionExpansionPanel extends StatefulWidget {
  const SupervisionExpansionPanel({super.key, required this.job});

  final Job job;

  @override
  State<SupervisionExpansionPanel> createState() =>
      _SupervisionExpansionPanelState();
}

class _SupervisionExpansionPanelState extends State<SupervisionExpansionPanel> {
  var _currentProgramToShow = Program.fms;

  List<PostInternshipEnterpriseEvaluation> _getFilteredEvaluations() {
    final evaluations =
        widget.job.mostRecentPostInternshipEnterpriseEvaluations(context);

    // Only keep evaluations from the requested students
    return evaluations
        .where((eval) => eval.program == _currentProgramToShow)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building SupervisionExpansionPanel for job: ${widget.job.specialization.name}');

    final evaluations = _getFilteredEvaluations();

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) => ListTile(
        title:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Encadrement des stagiaires'),
          _buildInfoButton(context, isExpanded: isExpanded),
        ]),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
        child: Column(
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
                        _buildSpecialNeedsAccomodation(evaluations),
                        const SizedBox(height: 12),
                        _buildSupervisionStyle(evaluations),
                        const SizedBox(height: 12),
                        _buildEaseOfCommunication(evaluations),
                        const SizedBox(height: 12),
                        _buildAbsenceAcceptance(evaluations),
                        const SizedBox(height: 12),
                        _buildSstManagement(evaluations),
                        const SizedBox(height: 12),
                      ],
                    ),
            ),
          ],
        ),
      ),
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
          'Respect du plan de formation',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        ItemizedText([
          'L\'élève a pu exercer toutes les tâches de toutes les compétences spécifiques obligatoires d\'un métier semi-spécialisé ('
              '${evaluations.fold<int>(0, (prev, e) => prev + e.trainingPlanRespect.toInt()).toString()} / ${evaluations.length}'
              ')'
        ]),
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
      sliderKey: ValueKey('autonomy_$_currentProgramToShow'),
      title: 'Niveau d\'autonomie souhaité',
      value: _meanOf(evaluations, (e) => e.autonomyExpected),
      lowLabel: AutonomyExpected.low.label,
      highLabel: AutonomyExpected.high.label,
    );
  }

  Widget _buildEfficiency(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      sliderKey: ValueKey('efficiency_$_currentProgramToShow'),
      title: 'Rendement de l\'élève attendu',
      value: _meanOf(evaluations, (e) => e.efficiencyExpected),
      lowLabel: EfficiencyExpected.low.label,
      highLabel: EfficiencyExpected.high.label,
    );
  }

  Widget _buildSpecialNeedsAccomodation(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      sliderKey: ValueKey('special_needs_accomodation_$_currentProgramToShow'),
      title:
          'Ouverture de l\'entreprise à accueillir des élèves ayant des besoins particuliers',
      value: _meanOf(evaluations, (e) => e.specialNeedsAccommodation),
      lowLabel: SpecialNeedsAccommodation.low.label,
      highLabel: SpecialNeedsAccommodation.high.label,
    );
  }

  Widget _buildSupervisionStyle(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      sliderKey: ValueKey('supervision_style_$_currentProgramToShow'),
      title: 'Type d\'encadrement',
      value: _meanOf(evaluations, (e) => e.supervisionStyle),
      lowLabel: SupervisionStyle.low.label,
      highLabel: SupervisionStyle.high.label,
    );
  }

  Widget _buildEaseOfCommunication(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      sliderKey: ValueKey('ease_of_communication_$_currentProgramToShow'),
      title: 'Communication avec l\'entreprise',
      value: _meanOf(evaluations, (e) => e.easeOfCommunication),
      lowLabel: EaseOfCommunication.low.label,
      highLabel: EaseOfCommunication.high.label,
    );
  }

  Widget _buildAbsenceAcceptance(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      sliderKey: ValueKey('absence_acceptance_$_currentProgramToShow'),
      title:
          'Tolérance du milieu à l\'égard des retards et absences de l\'élève',
      value: _meanOf(evaluations, (e) => e.absenceAcceptance),
      lowLabel: AbsenceAcceptance.low.label,
      highLabel: AbsenceAcceptance.high.label,
    );
  }

  Widget _buildSstManagement(
      List<PostInternshipEnterpriseEvaluation> evaluations) {
    return _TitledFixSlider(
      sliderKey: ValueKey('sst_management_$_currentProgramToShow'),
      title: 'Encadrement par rapport à la SST',
      value: _meanOf(evaluations, (e) => e.sstManagement),
      lowLabel: SstManagement.low.label,
      highLabel: SstManagement.high.label,
    );
  }
}

class _TitledFixSlider extends StatelessWidget {
  const _TitledFixSlider({
    required this.sliderKey,
    required this.title,
    required this.value,
    required this.lowLabel,
    required this.highLabel,
  });

  final Key sliderKey;
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
          key: sliderKey,
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

Widget _buildInfoButton(BuildContext context, {required bool isExpanded}) {
  return Visibility(
    visible: isExpanded,
    maintainSize: true,
    maintainAnimation: true,
    maintainState: true,
    child: Align(
      alignment: Alignment.topRight,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => showSnackBar(context,
            message: 'Les résultats sont le cumul des '
                'évaluations des personnes ayant '
                'supervisé des stagiaires dans cette entreprise. '
                '\nIls sont différenciés entre stages '
                'FMS et FPT.'),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.info,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    ),
  );
}

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

Widget _printCountedList<T>(Iterable<T> iterable, String Function(T) toString) {
  var out = iterable.map<String>((e) => toString(e)).toList();

  out = out
      .toSet()
      .map((e) =>
          '$e (${out.fold<int>(0, (prev, e2) => prev + (e == e2 ? 1 : 0))})')
      .toList();
  return ItemizedText(out);
}
