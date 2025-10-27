import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/students_extension.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/screens/student/pages/about_page.dart';
import 'package:stagess/screens/student/pages/internships_page.dart';
import 'package:stagess/screens/student/pages/skills_page.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';

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
      ...internships
          .where((e) => e.studentId == id)
          .map(
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
    ..index = widget.initialPage;

  final _aboutPageKey = GlobalKey<AboutPageState>();
  final _internshipPageKey = GlobalKey<InternshipsPageState>();
  final _skillsPageKey = GlobalKey<SkillsPageState>();

  Future<bool> _preventIfEditing(int tabIndex) async {
    if (tabIndex != 1) return false;
    if (_internshipPageKey.currentState?.activeKey.currentState == null) {
      return false;
    }

    // For each internships
    final keys =
        _internshipPageKey.currentState!.activeKey.currentState!.detailKeys;
    for (final key in keys.keys) {
      if (keys[key]!.currentState?.editMode ?? false) {
        if (keys[key]!.currentState?.editMode ?? false) {
          return await keys[key]!.currentState?.preventClosingIfEditing() ??
              false;
        }
      }
    }
    return false;
  }

  void _onTapBack() async {
    _logger.finer(
      'Back button tapped, current tab index: ${_tabController.index}',
    );
    if (await _preventIfEditing(_tabController.index)) return;

    _logger.finer('Navigating back from StudentScreen');
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
            bottom:
                widget.hasFullData
                    ? TabBar(
                      controller: _tabController,
                      onTap: (value) {
                        // Prevent from changing for now
                        int previousIndex = _tabController.previousIndex;
                        _tabController.index = previousIndex;
                        Future.microtask(() async {
                          if (!(await _preventIfEditing(previousIndex))) {
                            // If it is allowed to change, then do it
                            _tabController.index = value;
                          }
                        });
                      },
                      tabs: const [
                        Tab(icon: Icon(Icons.info_outlined), text: 'À propos'),
                        Tab(icon: Icon(Icons.assignment), text: 'Stages'),
                        Tab(
                          icon: Icon(Icons.card_membership),
                          text: 'Plan formation',
                        ),
                      ],
                    )
                    : null,
          ),
          smallDrawer: null,
          mediumDrawer: MainDrawer.medium,
          largeDrawer: MainDrawer.large,
          body:
              widget.hasFullData
                  ? TabBarView(
                    controller: _tabController,
                    children: [
                      AboutPage(key: _aboutPageKey, student: student),
                      InternshipsPage(
                        key: _internshipPageKey,
                        student: student,
                      ),
                      SkillsPage(key: _skillsPageKey, student: student),
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
