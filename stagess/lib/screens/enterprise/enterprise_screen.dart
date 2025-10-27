import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/screens/enterprise/pages/about_page.dart';
import 'package:stagess/screens/enterprise/pages/internships_page.dart';
import 'package:stagess/screens/enterprise/pages/jobs_page.dart';
import 'package:stagess/screens/internship_enrollment/internship_enrollment_screen.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('EnterpriseScreen');

class EnterpriseScreen extends StatelessWidget {
  const EnterpriseScreen({super.key, required this.id, this.pageIndex = 0});
  static const route = '/enterprise';

  final String id;
  final int pageIndex;

  Future<void> _fetchEnterprise(BuildContext context) async {
    final enterprises = EnterprisesProvider.of(context, listen: false);
    final internships = InternshipsProvider.of(context, listen: false);
    await Future.wait([
      enterprises.fetchData(id: id, fields: FetchableFields.all),
      ...internships
          .where((e) => e.enterpriseId == id)
          .map(
            (e) => internships.fetchData(id: e.id, fields: FetchableFields.all),
          ),
    ]);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchEnterprise(context),
      builder: (context, snapshot) {
        final enterprise = EnterprisesProvider.of(
          context,
          listen: false,
        ).fromIdOrNull(id);
        if (enterprise == null) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        final hasFullData = snapshot.connectionState == ConnectionState.done;
        return _EnterpriseScreenInternal(
          id: id,
          pageIndex: pageIndex,
          hasFullData: hasFullData,
        );
      },
    );
  }
}

class _EnterpriseScreenInternal extends StatefulWidget {
  const _EnterpriseScreenInternal({
    required this.id,
    required this.pageIndex,
    required this.hasFullData,
  });

  final String id;
  final int pageIndex;
  final bool hasFullData;

  @override
  State<_EnterpriseScreenInternal> createState() =>
      _EnterpriseScreenInternalState();
}

class _EnterpriseScreenInternalState extends State<_EnterpriseScreenInternal>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(
    initialIndex: widget.pageIndex,
    length: 3,
    vsync: this,
  );

  late IconButton _actionButton;

  final _aboutPageKey = GlobalKey<EnterpriseAboutPageState>();
  final _jobsPageKey = GlobalKey<JobsPageState>();
  final _stagePageKey = GlobalKey<InternshipsPageState>();

  bool get _editing =>
      (_aboutPageKey.currentState?.editing ?? false) ||
      (_jobsPageKey.currentState?.isEditing ?? false);

  void cancelEditing() {
    _logger.info('Canceling editing in EnterpriseScreen');
    if (_aboutPageKey.currentState?.editing != null) {
      _aboutPageKey.currentState!.toggleEdit(save: false);
    }
    if (_jobsPageKey.currentState?.isEditing != null) {
      _jobsPageKey.currentState!.cancelEditing();
    }
    _logger.fine('Editing cancelled in EnterpriseScreen');
    setState(() {});
  }

  void _updateActionButton() {
    _logger.finer('Updating action button in EnterpriseScreen');
    late Icon icon;

    if (_tabController.index == 0) {
      icon = const Icon(Icons.add);
    } else if (_tabController.index == 1) {
      icon =
          _aboutPageKey.currentState?.editing ?? false
              ? const Icon(Icons.save)
              : const Icon(Icons.edit);
    } else if (_tabController.index == 2) {
      icon = const Icon(Icons.add);
    }
    _actionButton = IconButton(
      icon: icon,
      onPressed: () async {
        if (_tabController.index == 0) {
          if (_jobsPageKey.currentState!.isEditing) {
            if (!await ConfirmExitDialog.show(
              context,
              content: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text:
                          '** Vous quittez la page sans avoir '
                          'cliqué sur Enregistrer ',
                    ),
                    WidgetSpan(
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: Icon(
                          Icons.save,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const TextSpan(
                      text: '. **\n\nToutes vos modifications seront perdues.',
                    ),
                  ],
                ),
              ),
            )) {
              return;
            }
            cancelEditing();
          }
          await _jobsPageKey.currentState?.addJob();
        } else if (_tabController.index == 1) {
          await _aboutPageKey.currentState?.toggleEdit();
        } else if (_tabController.index == 2) {
          await _stagePageKey.currentState?.addStage();
        }

        _updateActionButton();
      },
    );
    _logger.finer('Action button updated in EnterpriseScreen');

    if (!mounted) return;
    setState(() {});
  }

  Future<void> addInternship(
    Enterprise enterprise,
    Specialization? specialization,
  ) async {
    _logger.info('Adding internship for enterprise: ${enterprise.name}');

    final schoolId = Provider.of<AuthProvider>(context, listen: false).schoolId;
    if (schoolId == null) {
      showSnackBar(context, message: 'Vous n\'êtes pas connecté à une école');
      return;
    }

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (context) => Dialog(
            child: InternshipEnrollmentScreen(
              enterprise: enterprise,
              specifiedSpecialization: specialization,
            ),
          ),
    );
    _logger.fine('Internship added for enterprise: ${enterprise.name}');
  }

  @override
  void initState() {
    super.initState();
    _updateActionButton();
    _tabController.addListener(() => _updateActionButton());
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building EnterpriseScreen with id: ${widget.id}');
    final enterprise = EnterprisesProvider.of(
      context,
      listen: true,
    ).fromIdOrNull(widget.id);
    if (enterprise == null) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      );
    }

    return ResponsiveService.scaffoldOf(
      context,
      smallDrawer: null,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      appBar: ResponsiveService.appBarOf(
        context,
        title: Text(enterprise.name),
        actions: [_actionButton],
        leading:
            ResponsiveService.getScreenSize(context) == ScreenSize.small
                ? null
                : SizedBox.shrink(),
        bottom:
            widget.hasFullData
                ? TabBar(
                  onTap: (index) async {
                    if (!_editing || !_tabController.indexIsChanging) {
                      return;
                    }

                    _tabController.index = _tabController.previousIndex;
                    if (await ConfirmExitDialog.show(
                      context,
                      content: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text:
                                  '** Vous quittez la page sans avoir '
                                  'cliqué sur Enregistrer ',
                            ),
                            WidgetSpan(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: Icon(
                                  Icons.save,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const TextSpan(
                              text:
                                  '. **\n\nToutes vos modifications seront perdues.',
                            ),
                          ],
                        ),
                      ),
                    )) {
                      cancelEditing();
                      _tabController.animateTo(index);
                    }
                  },
                  controller: _tabController,
                  tabs: const [
                    Tab(icon: Icon(Icons.work), text: 'Métiers offerts'),
                    Tab(icon: Icon(Icons.info_outlined), text: 'À propos'),
                    Tab(icon: Icon(Icons.assignment), text: 'Stages'),
                  ],
                )
                : null,
      ),
      body:
          widget.hasFullData
              ? TabBarView(
                controller: _tabController,
                physics: _editing ? const NeverScrollableScrollPhysics() : null,
                children: [
                  JobsPage(
                    key: _jobsPageKey,
                    enterprise: enterprise,
                    onAddInternshipRequest: addInternship,
                  ),
                  EnterpriseAboutPage(
                    key: _aboutPageKey,
                    enterprise: enterprise,
                  ),
                  InternshipsPage(
                    key: _stagePageKey,
                    enterprise: enterprise,
                    onAddInternshipRequest: addInternship,
                  ),
                ],
              )
              : Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              ),
    );
  }
}
