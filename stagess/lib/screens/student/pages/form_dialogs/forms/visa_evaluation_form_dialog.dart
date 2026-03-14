import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/internships_helpers.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/numbered_text.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/student_visa.dart';
import 'package:stagess_common/services/job_data_file_service.dart'
    as job_service;
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/selectable_text_boxes.dart';

final _logger = Logger('VisaFormDialog');

Future<Student?> showVisaEvaluationFormDialog(
  BuildContext context, {
  required String studentId,
  String? evaluationId,
  required bool canModify,
}) async {
  final newEvaluation = await showDialog<StudentVisa>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: _VisaEvaluationScreen(
        studentId: studentId,
        evaluationId: evaluationId,
        canModify: canModify,
      ),
    ),
  );
  if (newEvaluation == null || !context.mounted) return null;

  final student = StudentsProvider.of(context, listen: false).fromId(studentId);

  return Student.fromSerialized(student.serialize())
    ..allVisa.add(newEvaluation);
}

class VisaFormController {
  static const _formVersion = '1.0.0';

  final Student _student;
  final List<Internship> _internships = [];
  final List<job_service.Specialization> _specializations = [];
  final Map<job_service.Specialization, List<SkillEvaluation>>
      _evaluatedSkills = {};
  final String? evaluationId;
  final bool canModify;

  final _experiencesAndAptitudesController = SelectableTextItemsController();
  final _attestationsAndMentionsController = SelectableTextItemsController();
  final _sstTrainingsController = SelectableTextItemsController();

  bool _isGatewayToFmsAvailable = false;
  final _sstCertificateController = SelectableTextItemsController();
  final _specificSkillsController = SelectableTextItemsController();
  final _referenceController = TextEditingController();

  final _forcesController = SelectableTextItemsController();
  final _challengesController = SelectableTextItemsController();

  final _successConditionsController = TextEditingController();

  VisaFormController(
    BuildContext context, {
    required String studentId,
    this.evaluationId,
    required this.canModify,
  }) : _student =
            StudentsProvider.of(context, listen: false).fromId(studentId) {
    _internships.addAll(
        InternshipsProvider.of(context, listen: false).byStudentId(studentId));
    for (final internship in _internships) {
      final enterprise = EnterprisesProvider.of(context, listen: false)
          .fromId(internship.enterpriseId);
      _specializations.add(enterprise.jobs
          .fromId(internship.currentContract!.jobId)
          .specialization);
    }
    _evaluatedSkills.addAll(
        InternshipsHelpers.getStudentSkills(context, studentId: studentId));

    clear();
    if (evaluationId != null) {
      _fillFromPreviousEvaluation(context, previousEvaluationId: evaluationId!);
    }
  }

  void dispose() {
    _experiencesAndAptitudesController.dispose();
    _attestationsAndMentionsController.dispose();
    _sstTrainingsController.dispose();
    _sstCertificateController.dispose();
    _specificSkillsController.dispose();
    _referenceController.dispose();
    _forcesController.dispose();
    _challengesController.dispose();
    _successConditionsController.dispose();
  }

  void clear() {
    _experiencesAndAptitudesController.clear();
    _attestationsAndMentionsController.clear();
    _sstTrainingsController.clear();

    for (final trainingId in SstTraining.availableTrainings.keys) {
      _sstTrainingsController.add(SstTraining(
          index: int.parse(trainingId),
          trainingId: trainingId,
          isSelected: false,
          isHidden: true));
    }

    _isGatewayToFmsAvailable = false;

    _sstCertificateController.clear();
    _sstCertificateController.add(Certificate(
        index: 0, certificateType: CertificateType.none, isSelected: false));
    _sstCertificateController.add(Certificate(
        index: 1, certificateType: CertificateType.fpt, isSelected: false));
    for (final entries in _specializations.asMap().entries) {
      final index = entries.key + 2; // because of the previous 2
      final specialization = entries.value;

      _sstCertificateController.add(
        Certificate(
          index: index,
          certificateType: CertificateType.fms,
          isSelected: false,
          specializationId: specialization.id,
        ),
      );
    }

    _specificSkillsController.clear();
    final acquiredSkills =
        InternshipsHelpers.filterAcquiredSkills(skills: _evaluatedSkills)
            .values
            .expand((e) => e)
            .toList();
    for (final entry in acquiredSkills.asMap().entries) {
      final index = entry.key;
      final skill = entry.value;

      _specificSkillsController.add(Skill(
          index: index,
          specializationId: skill.specializationId,
          isSelected: false));
    }
    _referenceController.text = '';

    _forcesController.clear();
    _challengesController.clear();
    for (final key in Attitude.availableItems.keys) {
      _forcesController.add(
          Attitude(index: int.parse(key), attitudeId: key, isSelected: false));
      _challengesController.add(
          Attitude(index: int.parse(key), attitudeId: key, isSelected: false));
    }

    _successConditionsController.text = '';
  }

  void _fillFromPreviousEvaluation(BuildContext context,
      {required String previousEvaluationId}) {
    // Clear previous responses before filling from previous evaluation
    clear();

    final visa =
        _student.allVisa.firstWhereOrNull((e) => e.id == previousEvaluationId);
    if (visa == null) {
      _logger.warning(
          'No previous evaluation found for student ${_student.id} with evaluationId $previousEvaluationId');
      return;
    }

    for (final entry in visa.form.experiencesAndAptitudes.asMap().entries) {
      final index = entry.key;
      final item = entry.value;

      _experiencesAndAptitudesController.add(
        ExperiencesAndAptitudes(
            index: index, text: item.text, isSelected: item.isSelected),
      );
    }
    for (final entry in visa.form.attestationsAndMentions.asMap().entries) {
      final index = entry.key;
      final item = entry.value;

      _attestationsAndMentionsController.add(
        AttestationsAndMentions(
            index: index, text: item.text, isSelected: item.isSelected),
      );
    }

    for (int i = 0; i < visa.form.sstTrainings.length; i++) {
      final previousSstTrainings = visa.form.sstTrainings[i];

      final index = _sstTrainingsController.options.indexWhere((e) =>
          (e as SstTraining).trainingId == previousSstTrainings.trainingId);
      if (index < 0) {
        throw Exception(
            'The training id "${previousSstTrainings.trainingId}" is not in the list of available trainings. '
            'Please update the list of available trainings in SstTraining.availableTrainings.');
      }
      _sstTrainingsController.updateOption(
        index,
        (_sstTrainingsController.options[index] as SstTraining).copyWith(
            isSelected: previousSstTrainings.isSelected,
            isHidden: previousSstTrainings.isHidden),
      );
    }

    _isGatewayToFmsAvailable = visa.form.isGatewayToFmsAvailable;
    for (final item in visa.form.certificates) {
      final index = _sstCertificateController.options.indexWhere((e) =>
          e.text == item.text &&
          (e as Certificate).specializationId == item.specializationId);
      if (index < 0) {
        // This should not happen, but if the student was drastically modified
        // it is possible the previous certificates includes job that were since removed
        // from the student internship list.
        _sstCertificateController.add(item);
      } else {
        _sstCertificateController.updateOption(
            index, item.copyWith(isSelected: item.isSelected));
      }
    }

    for (final item in visa.form.skills) {
      final index = _specificSkillsController.options
          .indexWhere((e) => e.text == item.text);
      if (index < 0) {
        _specificSkillsController.add(item);
      } else {
        _specificSkillsController.updateOption(
            index, item.copyWith(isSelected: item.isSelected));
      }
    }
    _referenceController.text = visa.form.reference;

    for (int i = 0; i < visa.form.forces.length; i++) {
      final previousForces = visa.form.forces[i];

      final index = _forcesController.options.indexWhere(
          (e) => (e as Attitude).attitudeId == previousForces.attitudeId);
      if (index < 0) {
        throw Exception(
            'The attitude id "${previousForces.attitudeId}" is not in the list of available items. '
            'Please update the list of available attitudes in Attitude.availableItems.');
      }
      _forcesController.updateOption(
        index,
        (_forcesController.options[index] as Attitude)
            .copyWith(isSelected: previousForces.isSelected),
      );
    }
    for (int i = 0; i < visa.form.challenges.length; i++) {
      final previousChallenges = visa.form.challenges[i];

      final index = _challengesController.options.indexWhere(
          (e) => (e as Attitude).attitudeId == previousChallenges.attitudeId);
      if (index < 0) {
        throw Exception(
            'The attitude id "${previousChallenges.attitudeId}" is not in the list of available items. '
            'Please update the list of available attitudes in Attitude.availableItems.');
      }
      _challengesController.updateOption(
        index,
        (_challengesController.options[index] as Attitude)
            .copyWith(isSelected: previousChallenges.isSelected),
      );
    }

    _successConditionsController.text = visa.form.successConditions;
  }

  StudentVisa toVisa() {
    return StudentVisa(
      date: DateTime.now(),
      form: VisaForm(
        experiencesAndAptitudes: _experiencesAndAptitudesController.options
            .cast<ExperiencesAndAptitudes>()
            .toList(),
        attestationsAndMentions: _attestationsAndMentionsController.options
            .cast<AttestationsAndMentions>()
            .toList(),
        sstTrainings:
            _sstTrainingsController.options.cast<SstTraining>().toList(),
        isGatewayToFmsAvailable: _isGatewayToFmsAvailable,
        certificates:
            _sstCertificateController.options.cast<Certificate>().toList(),
        skills: _specificSkillsController.options.cast<Skill>().toList(),
        reference: _referenceController.text,
        forces: _forcesController.options.cast<Attitude>().toList(),
        challenges: _challengesController.options.cast<Attitude>().toList(),
        successConditions: _successConditionsController.text,
      ),
      formVersion: _formVersion,
    );
  }
}

class _VisaEvaluationScreen extends StatefulWidget {
  const _VisaEvaluationScreen({
    required this.studentId,
    required this.evaluationId,
    required this.canModify,
  });

  final String studentId;
  final String? evaluationId;
  final bool canModify;

  @override
  State<_VisaEvaluationScreen> createState() => _VisaEvaluationScreenState();
}

class _VisaEvaluationScreenState extends State<_VisaEvaluationScreen> {
  late final _controller = VisaFormController(context,
      studentId: widget.studentId,
      evaluationId: widget.evaluationId,
      canModify: widget.canModify);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building AttitudeEvaluationScreen for student: ${widget.studentId}',
    );

    final student = StudentsHelpers.studentsInMyGroups(context)
        .firstWhereOrNull((e) => e.id == widget.studentId);

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            student == null
                ? 'En attente des informations'
                : 'Génération du visa pour ${student.firstName} ${student.lastName}',
          ),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: student == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ExpereinceAndAptitudeSection(
                                controller: _controller),
                            _EmployabilityProfileSection(
                                controller: _controller),
                            _ForcesAndChallengesSection(
                                controller: _controller),
                            SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.75),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _controlBuilder(),
                ],
              ),
      ),
    );
  }

  Future<void> _submit() async {
    _logger.info('Submitting attitude evaluation form');

    if (!_controller.canModify) {
      Navigator.of(context).pop();
      return;
    }

    _logger.fine('Visa evaluation form submitted successfully');
    Navigator.of(context).pop(_controller.toVisa());
  }

  void _cancel() async {
    _logger.info('Cancel called');

    if (_controller.canModify) {
      final answer = await ConfirmExitDialog.show(
        context,
        content: const Text('Toutes les modifications seront perdues.'),
      );
      if (!mounted || !answer) return;
    }

    _logger.fine('User confirmed exit, navigating back');
    Navigator.of(context).pop(null);
  }

  Widget _controlBuilder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_controller.canModify)
            OutlinedButton(
              onPressed: _cancel,
              child: const Text('Annuler'),
            ),
          const SizedBox(width: 20),
          TextButton(
            onPressed: () async => await _submit(),
            child: Text(_controller.canModify ? 'Enregistrer' : 'Fermer'),
          ),
        ],
      ),
    );
  }
}

class _ExpereinceAndAptitudeSection extends StatelessWidget {
  const _ExpereinceAndAptitudeSection({required this.controller});

  final VisaFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubTitle('Expériences et aptitudes', left: 0.0),
        _buildExperienceAndAptitude(context),
        SizedBox(height: 16.0),
        _buildAttestationsAndMentions(context),
        SizedBox(height: 16.0),
        _buildSstTrainings(context),
      ],
    );
  }

  Widget _buildExperienceAndAptitude(BuildContext context) {
    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Expériences et aptitudes personnelles et scolaires complémentaires au '
          'profil d\'employabilité',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.0),
            NumberedText([
              'Inscrire les activités scolaires, parascolaires et extrascolaires '
                  'pertinentes en employabilité en donnant des précisions, telles que '
                  'le nom de l\'organisme ou l\'entreprise concernée et l\'année.',
              'Cocher celles à afficher dans le VISA en PDF (maximum de 8 items).'
            ]),
            SizedBox(height: 8.0),
            SelectableTextBoxes(
              controller: controller._experiencesAndAptitudesController,
              enabled: controller.canModify,
              maxSelectedOptions: 8,
              newItemBuilder: (index) => ExperiencesAndAptitudes(
                  index: index, text: '', isSelected: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttestationsAndMentions(BuildContext context) {
    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Attestations et mentions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.0),
            NumberedText([
              'Inscrire les attestations et les mentions pertinentes reçues '
                  'par l\'élève ainsi que les années correspondantes.',
              'Cocher celles à afficher dans le VISA en PDF (maximum de 5 items).'
            ]),
            SizedBox(height: 8.0),
            SelectableTextBoxes(
              controller: controller._attestationsAndMentionsController,
              enabled: controller.canModify,
              maxSelectedOptions: 5,
              newItemBuilder: (index) => AttestationsAndMentions(
                  index: index, text: '', isSelected: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSstTrainings(BuildContext context) {
    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Formations relatives à la SST',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StatefulBuilder(
          builder: (context, setState) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.canModify)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Center(
                    child: TextButton(
                        onPressed: () async {
                          await _selectSstTrainingToShowDialog(context);
                          setState(() {});
                        },
                        child: Text(
                          'Sélectionner les formations à la SST obtenues',
                          textAlign: TextAlign.center,
                        )),
                  ),
                ),
              SizedBox(height: 8.0),
              ...controller._sstTrainingsController.options
                  .asMap()
                  .entries
                  .where((element) => !(element.value as SstTraining).isHidden)
                  .map((entry) {
                final index = entry.key;
                final item = entry.value as SstTraining;

                return CheckboxListTile(
                  key: ValueKey('sst_training_${item.id}'),
                  controlAffinity: ListTileControlAffinity.leading,
                  enabled: controller.canModify,
                  onChanged: (selected) {
                    controller._sstTrainingsController.updateOption(
                      index,
                      item.copyWith(isSelected: !item.isSelected),
                    );
                    setState(() {});
                  },
                  value: item.isSelected,
                  title: Text(
                      SstTraining.availableTrainings[item.trainingId] ??
                          'Entrainement non trouvé',
                      style: Theme.of(context).textTheme.bodyMedium),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectSstTrainingToShowDialog(BuildContext context) async =>
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StatefulBuilder(
              builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Liste des sujets pour lesquels l\'élève a pu recevoir une formation SST',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 16.0),
                  ...controller._sstTrainingsController.options.map((entry) {
                    final index = controller._sstTrainingsController.options
                        .indexWhere((element) =>
                            element.id == (entry as SstTraining).id);
                    final item = entry as SstTraining;

                    return CheckboxListTile(
                      enabled: controller.canModify,
                      onChanged: (selected) {
                        controller._sstTrainingsController.updateOption(
                          index,
                          item.copyWith(isHidden: !item.isHidden),
                        );
                        setState(() {});
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      value: !item.isHidden,
                      title: Text(
                          SstTraining.availableTrainings[item.trainingId] ??
                              'Entrainement non trouvé',
                          style: Theme.of(context).textTheme.bodyMedium),
                    );
                  }),
                  SizedBox(height: 16.0),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Fermer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _EmployabilityProfileSection extends StatelessWidget {
  const _EmployabilityProfileSection({required this.controller});

  final VisaFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubTitle('Profil d\'employabilité', left: 0.0),
        _buildCertification(context),
        SizedBox(height: 16.0),
        _buildSpecificSkills(context),
        SizedBox(height: 16.0),
        _buildReference(context),
      ],
    );
  }

  Widget _buildCertification(BuildContext context) {
    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Certification CFMS / CFPT',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8.0),
            _buildGatewayToFms(context),
            SizedBox(height: 16.0),
            _buildCertificatesToShow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayToFms(BuildContext context) {
    return controller._student.program == Program.fpt
        ? StatefulBuilder(
            builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pour les élèves de FPT-2 :',
                        style: Theme.of(context).textTheme.titleSmall),
                    CheckboxListTile(
                      value: controller._isGatewayToFmsAvailable,
                      enabled: controller.canModify,
                      onChanged: (value) {
                        controller._isGatewayToFmsAvailable = value ?? false;
                        setState(() {});
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text('Élève est candidat à la passerelle FMS',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  ],
                ))
        : SizedBox.shrink();
  }

  Widget _buildCertificatesToShow(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              'Pour les élèves de FMS et de FPT-3, cocher les certificats à afficher dans le VISA',
              style: Theme.of(context).textTheme.titleSmall),
          ...controller._sstCertificateController.options.map(
            (entry) {
              final index = controller._sstCertificateController.options
                  .indexWhere((element) =>
                      element.text == entry.text &&
                      (element as Certificate).specializationId ==
                          (entry as Certificate).specializationId);
              final item = entry as Certificate;
              final job = job_service.ActivitySectorsService.allSpecializations
                  .firstWhereOrNull((e) => e.id == item.specializationId);

              final name = switch (item.certificateType) {
                CertificateType.none => 'Aucun certificat',
                CertificateType.fpt =>
                  'Certificat de formation préparatoire au travail (CFPT)',
                CertificateType.fms =>
                  'Certificat de formation à un métier semi-spécialisé (CFMS) pour le métier : ${job?.name ?? 'Métier non trouvé'}',
              };
              final noneIsChecked = controller._sstCertificateController.options
                  .cast<Certificate>()
                  .any((e) =>
                      e.isSelected &&
                      e.certificateType == CertificateType.none);

              return CheckboxListTile(
                value: item.isSelected &&
                    (!noneIsChecked ||
                        item.certificateType == CertificateType.none),
                onChanged: (value) {
                  controller._sstCertificateController.updateOption(
                      index,
                      item.copyWith(
                          year: item.year ?? DateTime.now().year,
                          isSelected: value));
                  setState(() {});
                },
                enabled: controller.canModify &&
                    (item.certificateType == CertificateType.none ||
                        !controller._sstCertificateController.options
                            .cast<Certificate>()
                            .any((e) =>
                                e.isSelected &&
                                e.certificateType == CertificateType.none)),
                controlAffinity: ListTileControlAffinity.leading,
                title:
                    Text(name, style: Theme.of(context).textTheme.bodyMedium),
                subtitle: item.certificateType == CertificateType.none ||
                        !(item.isSelected && !noneIsChecked)
                    ? null
                    : Padding(
                        padding: const EdgeInsets.only(left: 36.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text('Année certification\u00a0: ${item.year}'),
                            IconButton(
                                onPressed: controller.canModify
                                    ? () async {
                                        final initialDate = DateTime(
                                            item.year ?? DateTime.now().year);
                                        final firstDate =
                                            DateTime(DateTime.now().year - 5);
                                        final lastDate =
                                            DateTime(DateTime.now().year + 5);
                                        final year = await showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text(
                                                'Sélectionnez l\'année de certification'),
                                            content: SizedBox(
                                              width: 300,
                                              height: 300,
                                              child: YearPicker(
                                                selectedDate: initialDate,
                                                onChanged: (selectedDate) {
                                                  Navigator.pop(context,
                                                      selectedDate.year);
                                                },
                                                firstDate: firstDate,
                                                lastDate: lastDate,
                                              ),
                                            ),
                                          ),
                                        );
                                        if (year == null) return;

                                        controller._sstCertificateController
                                            .updateOption(index,
                                                item.copyWith(year: year));
                                        setState(() {});
                                      }
                                    : null,
                                icon: Icon(Icons.calendar_month)),
                          ],
                        ),
                      ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificSkills(BuildContext context) {
    return AnimatedExpandingCard(
        elevation: 0.0,
        header: (context, isExpanded) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Compétences spécifiques',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: StatefulBuilder(
              builder: (context, setState) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Cocher les compétences à afficher dans le VISA en PDF dans la liste des compétences réussies.'),
                      ...controller._specificSkillsController.options.map(
                        (entry) {
                          final index = controller
                              ._specificSkillsController.options
                              .indexWhere((element) =>
                                  element.id == (entry as Skill).id);
                          final item = entry as Skill;

                          return CheckboxListTile(
                            value: item.isSelected,
                            enabled: controller.canModify,
                            onChanged: (value) {
                              controller._specificSkillsController.updateOption(
                                  index, item.copyWith(isSelected: value));
                              setState(() {});
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                                job_service.ActivitySectorsService
                                        .allSpecializations
                                        .firstWhereOrNull((e) =>
                                            e.id == item.specializationId)
                                        ?.idWithName ??
                                    'Compétence non trouvée',
                                style: Theme.of(context).textTheme.bodyMedium),
                          );
                        },
                      ),
                    ],
                  )),
        ));
  }

  Widget _buildReference(BuildContext context) {
    return AnimatedExpandingCard(
        elevation: 0.0,
        header: (context, isExpanded) => Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Référence',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Inscrire la référence, le nom de l\'entreprise si c\'est le milieu '
                  'de stage ou un employeur ainsi que le numéro de téléphone, à afficher dans le VISA en PDF.'),
              SizedBox(height: 8.0),
              TextFormField(
                controller: controller._referenceController,
                enabled: controller.canModify,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
                maxLength: 300,
                maxLines: 5,
              ),
            ],
          ),
        ));
  }
}

class _ForcesAndChallengesSection extends StatelessWidget {
  const _ForcesAndChallengesSection({required this.controller});

  final VisaFormController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubTitle('Forces et défis', left: 0.0),
        _buildElements(
          context,
          title: 'Forces',
          definition:
              'Cocher les cinq rubriques, correspondant aux cinq résultats '
              'les plus forts dans les évaluations, à afficher dans le VISA en PDF.',
          controller: controller._forcesController,
          enabled: controller.canModify,
          maxSelectedOptions: 5,
        ),
        SizedBox(height: 16.0),
        _buildElements(
          context,
          title: 'Défis à relever',
          definition:
              'Cocher le ou les deux rubriques, correspondant aux résultats les '
              'plus faibles dans les évaluations (maximum de 2 rubriques), à afficher '
              'dans le VISA en PDF.',
          controller: controller._challengesController,
          enabled: controller.canModify,
          maxSelectedOptions: 2,
        ),
        SizedBox(height: 16.0),
        _buildSuccessConditions(context),
      ],
    );
  }

  Widget _buildElements(
    BuildContext context, {
    required String title,
    required String definition,
    required bool enabled,
    required SelectableTextItemsController controller,
    required int maxSelectedOptions,
  }) {
    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: StatefulBuilder(
          builder: (context, setState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(definition),
                  ...controller.options.map((entry) {
                    final index = controller.options.indexWhere(
                        (element) => element.id == (entry as Attitude).id);
                    final item = entry as Attitude;

                    return CheckboxListTile(
                      value: item.isSelected,
                      onChanged: (value) {
                        controller.updateOption(
                            index, item.copyWith(isSelected: value));
                        setState(() {});
                      },
                      enabled: enabled &&
                          (item.isSelected ||
                              controller.selectedCount < maxSelectedOptions),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                          Attitude.availableItems[item.attitudeId] ??
                              'Attitude non trouvée',
                          style: Theme.of(context).textTheme.bodyMedium),
                    );
                  }),
                ],
              )),
    );
  }

  Widget _buildSuccessConditions(BuildContext context) {
    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Conditions de succès',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Lister toutes les adaptations, requises pour aider l\'élève à réussir, '
                'à afficher dans le VISA en PDF.'),
            SizedBox(height: 8.0),
            TextFormField(
              controller: controller._successConditionsController,
              enabled: controller.canModify,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
              ),
              maxLength: 300,
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }
}
