import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/screens/student/pages/about_page.dart';
import 'package:stagess/screens/student/pages/internships_page.dart';
import 'package:stagess/screens/student/pages/progression_page.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/helpers/students_extension.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/helpers/students_helpers.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';

final _logger = Logger('StudentScreen');

class StudentScreen extends StatelessWidget {
  const StudentScreen({super.key, required this.id, this.initialPage = 0});
  static const route = '/student';

  final String id;
  final int initialPage;

  Future<void> _fetchStudent(BuildContext context) async {
    final students = StudentsProvider.of(context, listen: false);
    final internships = InternshipsProvider.of(context, listen: false);
    await Future.wait([
      students.fetchData(id: id, fields: FetchableFields.all),
      ...internships.where((e) => e.studentId == id).map(
            (e) => internships.fetchData(id: e.id, fields: FetchableFields.all),
          ),
    ]);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchStudent(context),
      builder: (context, snapshot) {
        final student = StudentsProvider.of(
          context,
          listen: false,
        ).fromIdOrNull(id);
        if (student == null) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        final hasFullData = snapshot.connectionState == ConnectionState.done;
        return _StudentScreenInternal(
          id: id,
          initialPage: initialPage,
          hasFullData: hasFullData,
        );
      },
    );
  }
}

class _StudentScreenInternal extends StatefulWidget {
  const _StudentScreenInternal({
    required this.id,
    this.initialPage = 0,
    required this.hasFullData,
  });

  final String id;
  final int initialPage;
  final bool hasFullData;

  @override
  State<_StudentScreenInternal> createState() => _StudentScreenInternalState();
}

class _StudentScreenInternalState extends State<_StudentScreenInternal>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 3, vsync: this)
    ..index = widget.initialPage
    ..addListener(_onTabChanged);

  final _aboutPageKey = GlobalKey<AboutPageState>();

  void _onTabChanged() {
    setState(() {});
  }

  void _onTapBack() async {
    _logger.finer(
      'Back button tapped, current tab index: ${_tabController.index}',
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building StudentScreen for ID: ${widget.id}');

    final student = StudentsHelpers.studentsInMyGroups(
      context,
    ).firstWhereOrNull((e) => e.id == widget.id);

    return student == null
        ? Container()
        : ResponsiveService.scaffoldOf(
            context,
            appBar: ResponsiveService.appBarOf(
              context,
              title: Row(
                children: [
                  student.avatar,
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.fullName),
                      Text(
                        '${student.program} - groupe ${student.group}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              leading: IconButton(
                onPressed: _onTapBack,
                icon: const Icon(Icons.arrow_back),
              ),
              actions: _buildActionButton(),
              bottom: widget.hasFullData
                  ? TabBar(
                      controller: _tabController,
                      onTap: _onTapTab,
                      tabs: const [
                        Tab(icon: Icon(Icons.info_outlined), text: 'À propos'),
                        Tab(icon: Icon(Icons.assignment), text: 'Stages'),
                        Tab(icon: Icon(Icons.trending_up), text: 'Progression'),
                      ],
                    )
                  : null,
            ),
            smallDrawer: null,
            mediumDrawer: MainDrawer.medium,
            largeDrawer: MainDrawer.large,
            body: widget.hasFullData
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      AboutPage(key: _aboutPageKey, student: student),
                      InternshipsPage(student: student),
                      SkillsPage(studentId: student.id),
                    ],
                  )
                : Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
          );
  }

  bool get _isEditingAboutPage =>
      _aboutPageKey.currentState?.isEditing ?? false;

  void _onTapTab(int value) async {
    if (_isEditingAboutPage) {
      // Prevent the switching for now
      final targetTab = _tabController.index;
      _tabController.index = _tabController.previousIndex;
      final confirm = await ConfirmExitDialog.show(
        context,
        content: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                  text:
                      '** Vous quittez la page sans avoir cliqué sur Enregistrer '),
              WidgetSpan(
                  child: SizedBox(
                height: 22,
                width: 22,
                child: Icon(Icons.save, color: Theme.of(context).primaryColor),
              )),
              const TextSpan(
                text: '. **\n\nToutes vos modifications seront perdues.',
              ),
            ],
          ),
        ),
      );
      if (!confirm) return;
      // Confirm the exit and proceed to switch the tab
      _tabController.index = targetTab;
      await _aboutPageKey.currentState?.toggleEdit(save: false);
      setState(() {});
      return;
    }
  }

  List<Widget> _buildActionButton() {
    if (_tabController.index != 0) return [];

    final student = StudentsHelpers.studentsInMyGroups(context)
        .firstWhereOrNull((e) => e.id == widget.id);
    final user = AuthProvider.of(context, listen: false);
    if (student == null || user.currentId == null) return [];

    if (user.databaseAccessLevel < AccessLevel.schoolBoardAdmin &&
        student.teacherInChargeId != user.currentId) {
      return [];
    }

    return [
      IconButton(
        onPressed: _onClickedActionAbout,
        tooltip: _isEditingAboutPage
            ? 'Enregistrer les modifications'
            : 'Modifier les informations de l\'étudiant',
        icon: _isEditingAboutPage
            ? const Icon(Icons.save)
            : const Icon(Icons.edit),
      ),
    ];
  }

  Future<void> _onClickedActionAbout() async {
    if (_tabController.index != 0) return;

    // If we start editing, simply set the editing state to true and return early.
    if (!_isEditingAboutPage) {
      await _aboutPageKey.currentState?.toggleEdit();
      setState(() {});
      return;
    }

    final state = _aboutPageKey.currentState;
    if (state == null) {
      _logger.warning(
        'AboutPage state is null when trying to save changes. Aborting save operation.',
      );
      await _aboutPageKey.currentState?.toggleEdit(save: false);
      setState(() {});
      return;
    }

    await _aboutPageKey.currentState?.toggleEdit(save: true);
    setState(() {});
  }
}
