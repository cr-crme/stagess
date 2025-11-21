import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';

final _logger = Logger('TaskAndAbilityStep');

enum _RequiredSkills {
  communicateInWriting,
  communicateInEnglish,
  driveTrolley,
  interactWithCustomers,
  handleMoney;

  @override
  String toString() {
    switch (this) {
      case _RequiredSkills.communicateInWriting:
        return 'Communiquer à l\'écrit';
      case _RequiredSkills.communicateInEnglish:
        return 'Communiquer en anglais';
      case _RequiredSkills.driveTrolley:
        return 'Conduire un chariot (élèves CFER)';
      case _RequiredSkills.interactWithCustomers:
        return 'Interagir avec des clients';
      case _RequiredSkills.handleMoney:
        return 'Manipuler de l\'argent';
    }
  }
}

enum _TaskVariety { none, low, high }

enum _TrainingPlan { none, notFilled, filled }

class TaskAndAbilityStep extends StatefulWidget {
  const TaskAndAbilityStep({super.key, required this.internship});

  final Internship internship;

  @override
  State<TaskAndAbilityStep> createState() => TaskAndAbilityStepState();
}

class TaskAndAbilityStepState extends State<TaskAndAbilityStep> {
  final _formKey = GlobalKey<FormState>();

  // Tasks
  late var _taskVariety = widget.internship.enterpriseEvaluation == null
      ? _TaskVariety.none
      : (widget.internship.enterpriseEvaluation?.taskVariety == 0
          ? _TaskVariety.low
          : _TaskVariety.high);
  double? get taskVariety => _taskVariety == _TaskVariety.none
      ? null
      : _taskVariety == _TaskVariety.low
          ? 0.0
          : 1.0;

  late var _trainingPlan = widget.internship.enterpriseEvaluation == null
      ? _TrainingPlan.none
      : (widget.internship.enterpriseEvaluation?.trainingPlanRespect == 0
          ? _TrainingPlan.notFilled
          : _TrainingPlan.filled);
  double? get trainingPlan => _trainingPlan == _TrainingPlan.none
      ? null
      : _trainingPlan == _TrainingPlan.notFilled
          ? 0.0
          : 1.0;

  late final _skillController = CheckboxWithOtherController(
      elements: _RequiredSkills.values,
      initialValues: [
        ...?widget.internship.enterpriseEvaluation?.skillsRequired
      ]);
  List<String> get requiredSkills => _skillController.values;

  Future<String?> validate() async {
    _logger.finer('Validating TaskAndAbilityStep');

    if (!_formKey.currentState!.validate() ||
        taskVariety == null ||
        trainingPlan == null) {
      return 'Remplir tous les champs avec un *.';
    }
    _formKey.currentState!.save();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building TaskAndAbilityStep for internship: ${widget.internship.id}',
    );

    final enterprise = EnterprisesProvider.of(
      context,
      listen: false,
    ).firstWhereOrNull((e) => e.id == widget.internship.enterpriseId);

    // Sometimes for some reason the build is called this with these
    // provider empty on the first call
    if (enterprise == null) return Container();
    final student = StudentsHelpers.studentsInMyGroups(
      context,
    ).firstWhereOrNull((e) => e.id == widget.internship.studentId);

    return student == null
        ? Container()
        : Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SubTitle('Informations générales', left: 0),
                  _buildEnterpriseName(enterprise),
                  _buildStudentName(student),
                  const SubTitle('Tâches', left: 0),
                  _buildVariety(context),
                  const SizedBox(height: 8),
                  _buildTrainingPlan(context),
                  const SubTitle('Habiletés', left: 0),
                  const SizedBox(height: 16),
                  _buildSkillsRequired(context),
                ],
              ),
            ),
          );
  }

  Widget _buildSkillsRequired(BuildContext context) {
    return CheckboxWithOther(
      controller: _skillController,
      title: '* Habiletés requises pour le stage\u00a0:',
      errorMessageOther: 'Préciser les autres habiletés requises.',
    );
  }

  TextField _buildEnterpriseName(Enterprise enterprise) {
    // ThemeData does not work anymore so we have to override the style manually
    const styleOverride = TextStyle(color: Colors.black);

    return TextField(
      decoration: const InputDecoration(
        labelText: 'Nom de l\'entreprise',
        border: InputBorder.none,
        labelStyle: styleOverride,
      ),
      style: styleOverride,
      controller: TextEditingController(text: enterprise.name),
      enabled: false,
    );
  }

  TextField _buildStudentName(Student student) {
    // ThemeData does not work anymore so we have to override the style manually
    const styleOverride = TextStyle(color: Colors.black);

    return TextField(
      decoration: const InputDecoration(
        labelText: 'Nom de l\'élève',
        border: InputBorder.none,
        labelStyle: styleOverride,
      ),
      style: styleOverride,
      controller: TextEditingController(text: student.fullName),
      enabled: false,
    );
  }

  Widget _buildVariety(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Tâches données à l\'élève',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        RadioGroup(
          groupValue: _taskVariety,
          onChanged: (value) => setState(() => _taskVariety = value!),
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<_TaskVariety>(
                  value: _TaskVariety.low,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'Peu variées',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Expanded(
                child: RadioListTile<_TaskVariety>(
                  value: _TaskVariety.high,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'Très variées',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrainingPlan(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '* Respect du plan de formation',
          style: Theme.of(context).textTheme.titleSmall!,
        ),
        Text(
          'Tâches et compétences prévues dans le plan de formation ont été '
          'faites par l\'élève\u00a0:',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        RadioGroup(
          groupValue: _trainingPlan,
          onChanged: (value) => setState(() => _trainingPlan = value!),
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<_TrainingPlan>(
                  value: _TrainingPlan.notFilled,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'En partie',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              Expanded(
                child: RadioListTile<_TrainingPlan>(
                  value: _TrainingPlan.filled,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: Text(
                    'En totalité',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
