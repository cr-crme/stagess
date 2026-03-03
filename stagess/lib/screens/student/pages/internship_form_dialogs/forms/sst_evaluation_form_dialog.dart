import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stagess/common/widgets/form_fields/text_with_form.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/sst_evaluation.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/radio_with_follow_up.dart';

final _logger = Logger('SstEvaluationFormScreen');

Future<Internship?> showSstEvaluationFormDialog(
  BuildContext context, {
  required String internshipId,
  String? evaluationId,
}) async {
  final newEvaluation = await showDialog<SstEvaluation>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Navigator(
      onGenerateRoute: (settings) => MaterialPageRoute(
        builder: (ctx) => Dialog(
          child: _SstEvaluationFormScreen(
            rootContext: context,
            internshipId: internshipId,
            evaluationId: evaluationId,
          ),
        ),
      ),
    ),
  );
  if (newEvaluation == null || !context.mounted) return null;

  final internship =
      InternshipsProvider.of(context, listen: false).fromId(internshipId);
  return Internship.fromSerialized(internship.serialize())
    ..sstEvaluations.add(newEvaluation);
}

class _SstEvaluationFormScreen extends StatefulWidget {
  const _SstEvaluationFormScreen({
    required this.rootContext,
    required this.internshipId,
    this.evaluationId,
  });

  final BuildContext rootContext;
  final String internshipId;
  final String? evaluationId;

  @override
  State<_SstEvaluationFormScreen> createState() =>
      _SstEvaluationFormScreenState();
}

class _SstEvaluationFormScreenState extends State<_SstEvaluationFormScreen> {
  bool get _editMode => widget.evaluationId == null;

  final _questionsKey = GlobalKey<_QuestionsStepState>();
  late final wereAtMeetingController = CheckboxWithOtherController<String>(
    elements: [
      'Stagiaire',
      'Responsable en milieu de stage',
    ],
    initialValues: widget.evaluationId == null
        ? InternshipsProvider.of(context, listen: false)
                .fromId(widget.internshipId)
                .sstEvaluations
                .lastOrNull
                ?.presentAtEvaluation ??
            []
        : InternshipsProvider.of(context, listen: false)
                .fromId(widget.internshipId)
                .sstEvaluations
                .firstWhereOrNull((e) => e.id == widget.evaluationId)
                ?.presentAtEvaluation ??
            [],
  );

  void _submit() {
    _logger.info(
        'Submitting SstEvaluationFormScreen for internshipId: ${widget.internshipId}');

    if (!FormService.validateForm(_questionsKey.currentState!.formKey)) {
      setState(() {});
      return;
    }

    _questionsKey.currentState!.formKey.currentState!.save();

    _logger.fine(
      'SstEvaluationFormScreen submitted successfully for internshipId: ${widget.internshipId}',
    );
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(SstEvaluation(
        presentAtEvaluation: wereAtMeetingController.values,
        questions: _questionsKey.currentState!.answer));
  }

  void _cancel() async {
    if (!_editMode) {
      Navigator.of(widget.rootContext).pop(null);
      return;
    }

    _logger.info(
        'Cancelling SstEvaluationFormScreen for internshipId: ${widget.internshipId}');
    final answer = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
    );
    // If the user cancelled the closing of the dialog, we do nothing
    if (!answer) return;

    // If the user confirmed, we close the dialog and return to the previous screen
    _logger.fine('User confirmed exit, navigating back');
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(null);
  }

  void _showHelp({required bool force}) async {
    _logger.info('Showing help for SstEvaluationFormScreen');

    bool shouldShowHelp = force;
    if (!shouldShowHelp) {
      final prefs = await SharedPreferences.getInstance();
      final wasShown = prefs.getBool('SstRiskFormHelpWasShown');
      if (wasShown == null || !wasShown) shouldShowHelp = true;
    }

    if (!shouldShowHelp) return;

    final scrollController = ScrollController();

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('REPÈRES', textAlign: TextAlign.center),
        content: RawScrollbar(
          controller: scrollController,
          thumbVisibility: true,
          thickness: 7,
          minThumbLength: 75,
          thumbColor: Theme.of(context).primaryColor,
          radius: const Radius.circular(20),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Container(
              margin: const EdgeInsets.only(right: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Objectifs du questionnaire',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ItemizedText(const [
                    'S\'informer sur les risques auxquels est exposé l\'élève à ce '
                        'poste de travail.',
                    'Susciter un dialogue avec l\'entreprise sur les mesures '
                        'de prévention.\n'
                        'Les différentes sous-questions visent spécifiquement à '
                        'favoriser les échanges.',
                  ], style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Avec qui le remplir\u00a0?',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'La personne qui est en charge de former l\'élève sur le plancher\u00a0:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  ItemizedText(const [
                    'C\'est elle qui connait le mieux le poste de travail de l\'élève',
                    'Il sera plus facile d\'aborder avec elle qu\'avec l\'employeur '
                        'les questions relatives aux dangers et aux accidents',
                  ], style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Quand',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ItemizedText(const [
                    'La première semaine de stage',
                    'Pendant (ou après) une visite du poste de travail de l\'élève',
                  ], style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 12),
                  Text(
                    'Durée',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    '15 minutes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('SstRiskFormHelpWasShown', true);
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building SstEvaluationFormScreen for internshipId: ${widget.internshipId}');

    _showHelp(force: false);

    final internship = InternshipsProvider.of(context, listen: false)
        .fromId(widget.internshipId);

    return SizedBox(
      width: ResponsiveService.maxBodyWidth,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Repérer les risques SST'),
          leading: IconButton(
            onPressed: _cancel,
            icon: const Icon(Icons.arrow_back),
          ),
          actions: [
            InkWell(
              onTap: () => _showHelp(force: true),
              borderRadius: BorderRadius.circular(25),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.info),
              ),
            ),
          ],
        ),
        body: PopScope(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: _QuestionsStep(
                        key: _questionsKey,
                        editMode: _editMode,
                        initialSstEvaluation:
                            internship.sstEvaluations.lastOrNull,
                        wereAtMeetingController: wereAtMeetingController,
                        enterpriseId: internship.enterpriseId,
                        jobId: internship.jobId),
                  ),
                ),
                _controlBuilder(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controlBuilder() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_editMode)
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: OutlinedButton(
                  onPressed: _cancel, child: const Text('Annuler')),
            ),
          TextButton(
              onPressed: _submit,
              child: Text(_editMode ? 'Enregistrer' : 'Fermer')),
        ],
      ),
    );
  }
}

class _QuestionsStep extends StatefulWidget {
  const _QuestionsStep({
    super.key,
    required this.editMode,
    required this.initialSstEvaluation,
    required this.wereAtMeetingController,
    required this.enterpriseId,
    required this.jobId,
  });

  final bool editMode;
  final SstEvaluation? initialSstEvaluation;
  final CheckboxWithOtherController<String> wereAtMeetingController;
  final String enterpriseId;
  final String jobId;

  @override
  State<_QuestionsStep> createState() => _QuestionsStepState();
}

class _QuestionsStepState extends State<_QuestionsStep> {
  final Map<String, TextEditingController> _followUpController = {};

  final formKey = GlobalKey<FormState>();

  bool isProfessor = true;

  Map<String, List<String>?> answer = {};

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
          children: [_buildHeader(), _buildWereAtMeeting(), _buildQuestions()]),
    );
  }

  Widget _buildQuestions() {
    final enterprise = EnterprisesProvider.of(context, listen: false)
        .fromId(widget.enterpriseId);
    final job = enterprise.jobs.fromId(widget.jobId);

    // Sort the question by "id"
    final questionIds = [...job.specialization.questions]
      ..sort((a, b) => int.parse(a) - int.parse(b));
    final questions =
        questionIds.map((e) => QuestionFileService.fromId(e)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Questions', left: 0),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];

            // Fill the initial answer
            answer['Q${question.id}'] =
                widget.initialSstEvaluation?.questions['Q${question.id}'];
            answer['Q${question.id}+t'] =
                widget.initialSstEvaluation?.questions['Q${question.id}+t'];

            switch (question.type) {
              case QuestionType.radio:
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: RadioWithFollowUp<String>(
                    title: '${index + 1}. ${question.question}',
                    enabled: widget.editMode,
                    initialValue: widget
                        .initialSstEvaluation?.questions['Q${question.id}']?[0],
                    elements: question.choices!.toList(),
                    elementsThatShowChild: [question.choices!.first],
                    onChanged: (value) {
                      answer['Q${question.id}'] = [value.toString()];
                      _followUpController['Q${question.id}+t']!.text = '';
                      if (question.choices!.first != value) {
                        answer['Q${question.id}+t'] = null;
                      }
                    },
                    followUpChild: question.followUpQuestion == null
                        ? null
                        : _buildFollowUpQuestion(question, context),
                  ),
                );

              case QuestionType.checkbox:
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: CheckboxWithOther(
                    title: '${index + 1}. ${question.question}',
                    enabled: widget.editMode,
                    controller: CheckboxWithOtherController(
                      elements: question.choices!.toList(),
                      hasNotApplicableOption: true,
                      initialValues: (widget.initialSstEvaluation
                              ?.questions['Q${question.id}'] as List?)
                          ?.map((e) => e as String)
                          .toList(),
                    ),
                    onOptionSelected: (values) {
                      answer['Q${question.id}'] = values;
                      if (!question.choices!.any((q) => values.contains(q))) {
                        answer['Q${question.id}+t'] = null;
                        _followUpController['Q${question.id}+t']!.text = '';
                      }
                    },
                    followUpChild: question.followUpQuestion == null
                        ? null
                        : _buildFollowUpQuestion(question, context),
                  ),
                );

              case QuestionType.text:
                return Padding(
                  padding: const EdgeInsets.only(bottom: 36.0),
                  child: TextWithForm(
                    title: '${index + 1}. ${question.question}',
                    enabled: widget.editMode,
                    initialValue: widget.initialSstEvaluation
                            ?.questions['Q${question.id}']?.first ??
                        '',
                    onChanged: (text) => answer['Q${question.id}'] =
                        text == null ? null : [text],
                  ),
                );
            }
          },
        ),
      ],
    );
  }

  Widget _buildWereAtMeeting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Personnes présentes lors de l\'évaluation'),
        Padding(
          padding: const EdgeInsets.only(left: 24.0),
          child: CheckboxWithOther(
            controller: widget.wereAtMeetingController,
            enabled: widget.editMode,
          ),
        ),
      ],
    );
  }

  Padding _buildFollowUpQuestion(Question question, BuildContext context) {
    _followUpController['Q${question.id}+t'] = TextEditingController(
      text:
          widget.initialSstEvaluation?.questions['Q${question.id}+t']?.first ??
              '',
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextWithForm(
        controller: _followUpController['Q${question.id}+t'],
        enabled: widget.editMode,
        title: question.followUpQuestion!,
        titleStyle: Theme.of(context).textTheme.bodyMedium,
        onChanged: (text) =>
            answer['Q${question.id}+t'] = text == null ? null : [text],
      ),
    );
  }

  Widget _buildHeader() {
    // ThemeData does not work anymore so we have to override the style manually
    const styleOverride = TextStyle(color: Colors.black);

    final enterprise = EnterprisesProvider.of(context, listen: false)
        .fromId(widget.enterpriseId);
    final job = enterprise.jobs.fromId(widget.jobId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Informations générales', top: 0, left: 0),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Nom de l\'entreprise',
            border: InputBorder.none,
            labelStyle: styleOverride,
          ),
          style: styleOverride,
          controller: TextEditingController(text: enterprise.name),
          maxLines: null,
          enabled: false,
        ),
        TextField(
          decoration: const InputDecoration(
            labelText: 'Métier semi-spécialisé',
            border: InputBorder.none,
            labelStyle: styleOverride,
          ),
          style: styleOverride,
          controller: TextEditingController(
            text: job.specialization.name,
          ),
          maxLines: null,
          enabled: false,
        ),
      ],
    );
  }
}
