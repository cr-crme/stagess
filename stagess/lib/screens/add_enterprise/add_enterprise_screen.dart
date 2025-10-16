import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:stagess/common/widgets/scrollable_stepper.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/screens/add_enterprise/pages/about_page.dart';
import 'package:stagess/screens/add_enterprise/pages/jobs_page.dart';
import 'package:stagess/screens/add_enterprise/pages/validation_page.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('AddEnterpriseScreen');

class AddEnterpriseScreen extends StatefulWidget {
  const AddEnterpriseScreen({super.key});

  static const route = '/add-enterprise';

  @override
  State<AddEnterpriseScreen> createState() => _AddEnterpriseScreenState();
}

class _AddEnterpriseScreenState extends State<AddEnterpriseScreen> {
  final _scrollController = ScrollController();

  final _aboutKey = GlobalKey<AboutPageState>();
  final _jobsKey = GlobalKey<JobsPageState>();

  int _currentStep = 0;
  final List<StepState> _stepStatus = [
    StepState.indexed,
    StepState.indexed,
    StepState.indexed,
  ];

  void _showInvalidFieldsSnakBar([String? message]) {
    ScaffoldMessenger.of(context).clearSnackBars();
    showSnackBar(
      context,
      message: message ?? 'Remplir tous les champs avec un *.',
    );
  }

  void _previousStep() {
    _logger.finer('Previous step in AddEnterpriseScreen: $_currentStep');

    if (_currentStep == 0) return;
    _currentStep -= 1;
    _scrollController.jumpTo(0);
    setState(() {});
  }

  void _nextStep() async {
    _logger.finer('Next step in AddEnterpriseScreen: $_currentStep');

    bool valid = false;
    String? message;
    _updateEnterprise();
    if (_currentStep >= 0) {
      message = await _aboutKey.currentState!.validate();
      valid = message == null;
      _stepStatus[0] = valid ? StepState.complete : StepState.error;
    }
    if (_currentStep >= 1) {
      valid = _jobsKey.currentState!.validate();
      _stepStatus[1] = valid ? StepState.complete : StepState.error;
    }
    setState(() {});

    if (!valid) {
      _showInvalidFieldsSnakBar(message);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    if (_currentStep == 2) {
      return await _submit();
    } else {
      setState(() {
        _currentStep += 1;
        _scrollController.jumpTo(0);
      });
      return;
    }
  }

  late Enterprise _currentEnterprise = Enterprise.empty.copyWith(
    schoolBoardId:
        TeachersProvider.of(
          context,
          listen: false,
        ).currentTeacher?.schoolBoardId,
    recruiterId: TeachersProvider.of(context, listen: false).currentTeacher?.id,
  );

  void _updateEnterprise() {
    final about = _aboutKey.currentState;

    _currentEnterprise = _currentEnterprise.copyWith(
      name: about?.name,
      neq: about?.neq,
      activityTypes: about?.activityTypesController.activityTypes,
      jobs: _jobsKey.currentState!.jobs,
      contact: _currentEnterprise.contact.copyWith(
        firstName: about?.contactFirstName,
        middleName: null,
        lastName: about?.contactLastName,
        dateBirth: null,
        phone: PhoneNumber.fromString(about?.contactPhone ?? ''),
        address: Address.empty,
        email: about?.contactEmail,
      ),
      contactFunction: about?.contactFunction,
      address: about?.addressController.address,
      phone: PhoneNumber.fromString(about?.phoneController.text ?? ''),
    );
    setState(() {});
  }

  Future<void> _submit() async {
    _logger.info('Submitting enterprise form');
    final teachers = TeachersProvider.of(context, listen: false);
    final enterprises = EnterprisesProvider.of(context, listen: false);
    if (teachers.currentTeacher == null) {
      showSnackBar(
        context,
        message: 'Erreur, votre compte n\'est pas configuré.',
      );
      return;
    }

    if (_aboutKey.currentState == null) return;
    _updateEnterprise();
    enterprises.add(_currentEnterprise);

    await showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const SubTitle('Entreprise ajoutée', left: 0, bottom: 0),
            content: RichText(
              text: TextSpan(
                children: [
                  const TextSpan(text: 'L\'entreprise '),
                  TextSpan(
                    text: _currentEnterprise.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(
                    text:
                        ' a bien été ajoutée à la liste des entreprises.\n\n'
                        'Vous pouvez maintenant y inscrire des stagiaires.',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Ok'),
              ),
            ],
          ),
    );

    _logger.fine('Entreprise added: ${_currentEnterprise.name}');
    if (mounted) Navigator.pop(context);
  }

  void _cancel() async {
    _logger.info('Canceling enterprise form');
    final navigator = Navigator.of(context);
    final result = await ConfirmExitDialog.show(
      context,
      content: const Text('Toutes les modifications seront perdues.'),
    );
    if (!mounted || !result) return;

    _logger.fine('AddEnterpriseScreen cancelled by user.');
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building AddEnterpriseScreen');

    return PopScope(
      child: SizedBox(
        width: ResponsiveService.maxBodyWidth,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Ajouter une entreprise'),
            leading: IconButton(
              onPressed: _cancel,
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: ScrollableStepper(
            type: StepperType.horizontal,
            scrollController: _scrollController,
            currentStep: _currentStep,
            onTapContinue: _nextStep,
            onStepTapped:
                (int tapped) => setState(() {
                  _updateEnterprise();
                  _scrollController.jumpTo(0);
                  _currentStep = tapped;
                }),
            onTapCancel: _cancel,
            steps: [
              Step(
                state: _stepStatus[0],
                isActive: _currentStep == 0,
                title: const Text('À propos'),
                content: AboutPage(key: _aboutKey),
              ),
              Step(
                state: _stepStatus[1],
                isActive: _currentStep == 1,
                title: const Text('Métiers\nofferts'),
                content: JobsPage(key: _jobsKey),
              ),
              Step(
                state: _stepStatus[2],
                isActive: _currentStep == 2,
                title: const Text('Validation des\ninformations'),
                content: ValidationPage(
                  enterprise: _currentEnterprise,
                  activityTypeController:
                      _aboutKey.currentState?.activityTypesController,
                  jobControllers: _jobsKey.currentState?.jobsControllers,
                ),
              ),
            ],
            controlsBuilder: _controlBuilder,
          ),
        ),
      ),
    );
  }

  Widget _controlBuilder(BuildContext context, ControlsDetails details) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Expanded(child: SizedBox()),
              if (_currentStep != 0)
                OutlinedButton(
                  onPressed: _previousStep,
                  child: const Text('Précédent'),
                ),
              const SizedBox(width: 20),
              TextButton(
                onPressed: details.onStepContinue,
                child: Text(
                  _currentStep == 2
                      ? 'Valider'
                      : _currentStep == 1
                      ? 'Enregistrer'
                      : 'Suivant',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
