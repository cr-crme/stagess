import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/numbered_text.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/student_visa.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
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
}) async {
  final newEvaluation = await showDialog<StudentVisa>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      child: _VisaEvaluationScreen(
        studentId: studentId,
        evaluationId: evaluationId,
      ),
    ),
  );
  if (newEvaluation == null || !context.mounted) return null;

  final student = StudentsProvider.of(context, listen: false).fromId(studentId);

  // Erase the previous visa and replace it by the new one
  return Student.fromSerialized(student.serialize())
    ..allVisa.clear()
    ..allVisa.add(newEvaluation);
}

class VisaFormController {
  static const _formVersion = '1.0.0';

  final Student student;
  final List<Specialization> specializations = [];
  final String? evaluationId;
  final bool canModify;

  final _experiencesAndAptitudesController = SelectableTextBoxesController();
  final _attestationsAndMentionsController = SelectableTextBoxesController();
  final _sstTrainingsController = SelectableTextBoxesController();

  bool _isGatewayToFmsAvailable = false;
  final _sstCertificateController = SelectableTextBoxesController();

  VisaFormController(
    BuildContext context, {
    required String studentId,
    this.evaluationId,
    required this.canModify,
  }) : student = StudentsProvider.of(context, listen: false).fromId(studentId) {
    final internships =
        InternshipsProvider.of(context, listen: false).byStudentId(studentId);
    for (final internship in internships) {
      final enterprise = EnterprisesProvider.of(context, listen: false)
          .fromId(internship.enterpriseId);
      specializations.add(enterprise.jobs
          .fromId(internship.currentContract!.jobId)
          .specialization);
    }

    clear();
    if (evaluationId != null) {
      _fillFromPreviousEvaluation(context, previousEvaluationId: evaluationId!);
    }
  }

  void clear() {
    _experiencesAndAptitudesController.clear();
    _attestationsAndMentionsController.clear();
    _sstTrainingsController.clear();

    for (final training in SstTraining.availableTrainings) {
      _sstTrainingsController
          .add(SstTraining(text: training, isSelected: false, hide: true));
    }

    _isGatewayToFmsAvailable = false;

    _sstCertificateController.clear();
    _sstCertificateController.add(
        Certificate(certificateType: CertificateType.none, isSelected: false));
    _sstCertificateController.add(
        Certificate(certificateType: CertificateType.fpt, isSelected: false));
    for (final specialization in specializations) {
      _sstCertificateController.add(Certificate(
          certificateType: CertificateType.fms,
          isSelected: false,
          specializationId: specialization.id));
    }
  }

  void _fillFromPreviousEvaluation(BuildContext context,
      {required String previousEvaluationId}) {
    // Clear previous responses before filling from previous evaluation
    clear();

    final visa =
        student.allVisa.firstWhereOrNull((e) => e.id == previousEvaluationId);
    if (visa == null) {
      _logger.warning(
          'No previous evaluation found for student ${student.id} with evaluationId $previousEvaluationId');
      return;
    }

    for (final item in visa.form.experiencesAndAptitudes) {
      _experiencesAndAptitudesController.add(
        ExperiencesAndAptitudes(text: item.text, isSelected: item.isSelected),
      );
    }
    for (final item in visa.form.attestationsAndMentions) {
      _attestationsAndMentionsController.add(
        AttestationsAndMentions(text: item.text, isSelected: item.isSelected),
      );
    }

    for (int i = 0; i < visa.form.sstTrainings.length; i++) {
      final training = visa.form.sstTrainings[i];
      if (!SstTraining.availableTrainings.contains(training.text)) {
        throw Exception(
            'The training "${training.text}" is not in the list of available trainings. '
            'Please update the list of available trainings in SstTraining.availableTrainings.');
      }
      _sstTrainingsController.updateOption(
        i,
        training.copyWith(isSelected: training.isSelected, hide: training.hide),
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
  }

  StudentVisa toVisa() {
    return StudentVisa(
      form: VisaEvaluation(
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
      ),
      formVersion: _formVersion,
    );
  }
}

class _VisaEvaluationScreen extends StatefulWidget {
  const _VisaEvaluationScreen({
    required this.studentId,
    required this.evaluationId,
  });

  final String studentId;
  final String? evaluationId;

  @override
  State<_VisaEvaluationScreen> createState() => _VisaEvaluationScreenState();
}

class _VisaEvaluationScreenState extends State<_VisaEvaluationScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _controller = widget.evaluationId == null
      ? VisaFormController(context,
          studentId: widget.studentId,
          evaluationId: StudentsProvider.of(context, listen: false)
              .fromId(widget.studentId)
              .allVisa
              .lastOrNull
              ?.id,
          canModify: true)
      : (StudentsProvider.of(context, listen: false)
                  .fromId(widget.studentId)
                  .allVisa
                  .firstWhereOrNull((e) => e.id == widget.evaluationId) ==
              null
          ? VisaFormController(context,
              studentId: widget.studentId, canModify: false)
          : VisaFormController(context,
              studentId: widget.studentId,
              evaluationId: widget.evaluationId!,
              canModify: false));

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

    if (!(_formKey.currentState?.validate() ?? true)) {
      await showDialog(
        context: context,
        builder: (BuildContext context) => const AlertDialog(
          title: Text('Formulaire incomplet'),
          content: Text('Répondre à toutes les questions.'),
        ),
      );
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
            onPressed: _submit,
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
              maxSelectedOptions: 8,
              newItemBuilder: (_) => ExperiencesAndAptitudes(),
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
              maxSelectedOptions: 5,
              newItemBuilder: (_) => AttestationsAndMentions(),
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
              SizedBox(height: 8.0),
              Center(
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
              SizedBox(height: 8.0),
              ...controller._sstTrainingsController.options
                  .asMap()
                  .entries
                  .where((element) => !(element.value as SstTraining).hide)
                  .map((entry) {
                final index = entry.key;
                final item = entry.value as SstTraining;

                return CheckboxListTile(
                  key: ValueKey('sst_training_${item.id}'),
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (selected) {
                    controller._sstTrainingsController.updateOption(
                      index,
                      item.copyWith(isSelected: !item.isSelected),
                    );
                    setState(() {});
                  },
                  value: item.isSelected,
                  title: Text(item.text,
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
                  ...controller._sstTrainingsController.options
                      .asMap()
                      .entries
                      .map((entry) {
                    final index = entry.key;
                    final item = entry.value as SstTraining;

                    return CheckboxListTile(
                      onChanged: (selected) {
                        controller._sstTrainingsController.updateOption(
                          index,
                          item.copyWith(hide: !item.hide),
                        );
                        setState(() {});
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      value: !item.hide,
                      title: Text(item.text,
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
    return controller.student.program == Program.fpt
        ? StatefulBuilder(
            builder: (context, setState) => Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pour les élèves de FPT-2 :',
                        style: Theme.of(context).textTheme.titleSmall),
                    CheckboxListTile(
                      value: controller._isGatewayToFmsAvailable,
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
                  (e) {
                    final item = e as Certificate;
                    final job = ActivitySectorsService.allSpecializations
                        .firstWhereOrNull((e) => e.id == item.specializationId);

                    final name = switch (item.certificateType) {
                      CertificateType.none => 'Aucun certificat',
                      CertificateType.fpt =>
                        'Certificat de formation préparatoire au travail (CFPT)',
                      CertificateType.fms =>
                        'Certificat de formation à un métier semi-spécialisé (CFMS) pour le métier : ${job?.name ?? 'Métier non trouvé'}',
                    };
                    final noneIsChecked = controller
                        ._sstCertificateController.options
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
                            controller._sstCertificateController.options
                                .indexOf(item),
                            item.copyWith(
                                year: item.year < 0
                                    ? DateTime.now().year
                                    : item.year,
                                isSelected: value));
                        setState(() {});
                      },
                      enabled: item.certificateType == CertificateType.none ||
                          !controller._sstCertificateController.options
                              .cast<Certificate>()
                              .any((e) =>
                                  e.isSelected &&
                                  e.certificateType == CertificateType.none),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(name,
                          style: Theme.of(context).textTheme.bodyMedium),
                      subtitle: item.certificateType == CertificateType.none ||
                              !(item.isSelected && !noneIsChecked)
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(left: 36.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                      'Année certification\u00a0: ${item.year}'),
                                  IconButton(
                                      onPressed: () async {
                                        final initialDate = DateTime(
                                            item.year > 0
                                                ? item.year
                                                : DateTime.now().year);
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
                                            .updateOption(
                                                controller
                                                    ._sstCertificateController
                                                    .options
                                                    .indexOf(item),
                                                item.copyWith(year: year));
                                        setState(() {});
                                      },
                                      icon: Icon(Icons.calendar_month)),
                                ],
                              ),
                            ),
                    );
                  },
                ),
              ],
            ));
  }
}
