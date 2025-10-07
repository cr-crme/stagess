import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stagess/common/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:stagess/common/widgets/form_fields/text_with_form.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/misc/question_file_service.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/radio_with_follow_up.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('JobSstFormScreen');

Future<Enterprise?> showJobSstFormDialog(
  BuildContext context, {
  required String enterpriseId,
  required String jobId,
}) async {
  _logger.info('Showing JobSstFormDialog for jobId: $jobId');
  final enterprises = EnterprisesProvider.of(context, listen: false);
  final hasLock = await enterprises.getLockForItem(enterprises[enterpriseId]);
  if (!hasLock || !context.mounted) {
    _logger.warning('Could not get lock for enterpriseId: $enterpriseId');
    if (context.mounted) {
      showSnackBar(
        context,
        message:
            'Impossible de modifier le formulaire, car il est en cours de modification par un autre utilisateur.',
      );
    }
    return null;
  }

  final editedEnterprise = await showDialog<Enterprise?>(
    context: context,
    barrierDismissible: false,
    builder:
        (context) => Navigator(
          onGenerateRoute:
              (settings) => MaterialPageRoute(
                builder:
                    (ctx) => Dialog(
                      child: JobSstFormScreen(
                        rootContext: context,
                        enterpriseId: enterpriseId,
                        jobId: jobId,
                      ),
                    ),
              ),
        ),
  );
  if (editedEnterprise != null) {
    await enterprises.replaceWithConfirmation(editedEnterprise);
  }

  await enterprises.releaseLockForItem(enterprises[enterpriseId]);
  return editedEnterprise;
}

class JobSstFormScreen extends StatefulWidget {
  const JobSstFormScreen({
    super.key,
    required this.rootContext,
    required this.enterpriseId,
    required this.jobId,
  });

  static const route = '/job-sst-form';

  final BuildContext rootContext;
  final String enterpriseId;
  final String jobId;

  @override
  State<JobSstFormScreen> createState() => _JobSstFormScreenState();
}

class _JobSstFormScreenState extends State<JobSstFormScreen> {
  final _questionsKey = GlobalKey<_QuestionsStepState>();

  void _submit() {
    _logger.info('Submitting JobSstFormScreen for jobId: ${widget.jobId}');

    if (!FormService.validateForm(_questionsKey.currentState!.formKey)) {
      setState(() {});
      return;
    }

    _questionsKey.currentState!.formKey.currentState!.save();

    final enterprises = EnterprisesProvider.of(context, listen: false);
    final enterprise = enterprises.fromId(widget.enterpriseId);
    enterprise.jobs[widget.jobId].sstEvaluation.update(
      questions: _questionsKey.currentState!.answer,
    );

    enterprise.jobs.replace(enterprise.jobs[widget.jobId]);

    _logger.fine(
      'JobSstFormScreen submitted successfully for jobId: ${widget.jobId}',
    );
    if (!widget.rootContext.mounted) return;
    Navigator.of(widget.rootContext).pop(enterprise);
  }

  void _cancel() async {
    _logger.info('Cancelling JobSstFormScreen for jobId: ${widget.jobId}');
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
    _logger.info('Showing help for JobSstFormScreen');

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
      builder:
          (context) => AlertDialog(
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
                      const SizedBox(height: 12),
                      Text(
                        'Cibles',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      ItemizedText(const [
                        'Nouvelle entreprise : remplissage initial',
                        'Milieu de stage récurrent : validation et mise à jour des '
                            'réponses des années précédentes',
                      ], style: Theme.of(context).textTheme.bodyMedium),
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
    _logger.finer('Building JobSstFormScreen for jobId: ${widget.jobId}');

    _showHelp(force: false);

    final enterprise = EnterprisesProvider.of(
      context,
    ).fromId(widget.enterpriseId);

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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _QuestionsStep(
                    key: _questionsKey,
                    enterprise: enterprise,
                    job: enterprise.jobs[widget.jobId],
                  ),
                  _controlBuilder(),
                ],
              ),
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
          OutlinedButton(onPressed: _cancel, child: const Text('Annuler')),
          const SizedBox(width: 20),
          TextButton(onPressed: _submit, child: const Text('Confirmer')),
        ],
      ),
    );
  }
}

class _QuestionsStep extends StatefulWidget {
  const _QuestionsStep({
    super.key,
    required this.enterprise,
    required this.job,
  });

  final Enterprise enterprise;
  final Job job;

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
      child: Column(children: [_buildHeader(), _buildQuestions()]),
    );
  }

  Widget _buildQuestions() {
    // Sort the question by "id"
    final questionIds = [...widget.job.specialization.questions];
    questionIds.sort((a, b) => int.parse(a) - int.parse(b));
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
                widget.job.sstEvaluation.questions['Q${question.id}'];
            answer['Q${question.id}+t'] =
                widget.job.sstEvaluation.questions['Q${question.id}+t'];

            switch (question.type) {
              case QuestionType.radio:
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: RadioWithFollowUp(
                    title: '${index + 1}. ${question.question}',
                    initialValue:
                        widget.job.sstEvaluation.questions['Q${question.id}'],
                    elements: question.choices!.toList(),
                    elementsThatShowChild: [question.choices!.first],
                    onChanged: (value) {
                      answer['Q${question.id}'] = [value.toString()];
                      _followUpController['Q${question.id}+t']!.text = '';
                      if (question.choices!.first != value) {
                        answer['Q${question.id}+t'] = null;
                      }
                    },
                    followUpChild:
                        question.followUpQuestion == null
                            ? null
                            : _buildFollowUpQuestion(question, context),
                  ),
                );

              case QuestionType.checkbox:
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: CheckboxWithOther(
                    title: '${index + 1}. ${question.question}',
                    elements: question.choices!.toList(),
                    hasNotApplicableOption: true,
                    initialValues:
                        (widget.job.sstEvaluation.questions['Q${question.id}']
                                as List?)
                            ?.map((e) => e as String)
                            .toList(),
                    onOptionSelected: (values) {
                      answer['Q${question.id}'] = values;
                      if (!question.choices!.any((q) => values.contains(q))) {
                        answer['Q${question.id}+t'] = null;
                        _followUpController['Q${question.id}+t']!.text = '';
                      }
                    },
                    followUpChild:
                        question.followUpQuestion == null
                            ? null
                            : _buildFollowUpQuestion(question, context),
                  ),
                );

              case QuestionType.text:
                return Padding(
                  padding: const EdgeInsets.only(bottom: 36.0),
                  child: TextWithForm(
                    title: '${index + 1}. ${question.question}',
                    initialValue:
                        widget
                            .job
                            .sstEvaluation
                            .questions['Q${question.id}']
                            ?.first ??
                        '',
                    onChanged:
                        (text) =>
                            answer['Q${question.id}'] =
                                text == null ? null : [text],
                  ),
                );
            }
          },
        ),
      ],
    );
  }

  Padding _buildFollowUpQuestion(Question question, BuildContext context) {
    _followUpController['Q${question.id}+t'] = TextEditingController(
      text:
          widget.job.sstEvaluation.questions['Q${question.id}+t']?.first ?? '',
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextWithForm(
        controller: _followUpController['Q${question.id}+t'],
        title: question.followUpQuestion!,
        titleStyle: Theme.of(context).textTheme.bodyMedium,
        onChanged:
            (text) =>
                answer['Q${question.id}+t'] = text == null ? null : [text],
      ),
    );
  }

  Widget _buildHeader() {
    // ThemeData does not work anymore so we have to override the style manually
    const styleOverride = TextStyle(color: Colors.black);

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
          controller: TextEditingController(text: widget.enterprise.name),
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
            text: widget.job.specialization.name,
          ),
          maxLines: null,
          enabled: false,
        ),
      ],
    );
  }
}
