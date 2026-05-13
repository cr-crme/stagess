import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/router.dart';
import 'package:stagess/screens/students_list/widgets/student_card.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/helpers/students_helpers.dart';
import 'package:stagess_common_flutter/widgets/search.dart';

final _logger = Logger('StudentsListScreen');

class StudentsListScreen extends StatefulWidget {
  const StudentsListScreen({super.key});

  static const route = '/students';

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  bool _showSearchBar = false;
  late final _searchController = TextEditingController()
    ..addListener(() => setState(() {}));

  List<Student> _filterSelectedStudents(List<Student> students) {
    final textToSearch = _searchController.text.toLowerCase().trim();
    _logger.finer('Filtering students with search text: "$textToSearch"');

    return students.where((student) {
      if (student.fullName.toLowerCase().contains(textToSearch) ||
          student.group.toLowerCase().contains(textToSearch)) {
        return true;
      }

      return false;
    }).sorted((a, b) => a.lastName.compareTo(b.lastName));
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building StudentsListScreen');
    final students =
        _filterSelectedStudents(StudentsHelpers.studentsInMyGroups(context));

    return ResponsiveService.scaffoldOf(
      context,
      appBar: ResponsiveService.appBarOf(
        context,
        title: const Text('Mes élèves'),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            icon: const Icon(Icons.search),
          )
        ],
        bottom: _showSearchBar ? Search(controller: _searchController) : null,
      ),
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: students.length,
              itemBuilder: (context, index) => Padding(
                padding: index == students.length - 1
                    ? EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * 0.5)
                    : const EdgeInsets.only(),
                child: StudentCard(
                  student: students.elementAt(index),
                  onTap: (student) {
                    FocusManager.instance.primaryFocus?.unfocus();
                    GoRouter.of(context).goNamed(
                      Screens.student,
                      pathParameters: Screens.params(student),
                      queryParameters: Screens.queryParams(pageIndex: '0'),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
