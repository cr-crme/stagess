import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/screens/my_account/widgets/teacher_list_tile.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

final _logger = Logger('MyAccountScreen');

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});
  static const String route = '/my-account';
  Future<void> _fetchTeacher(BuildContext context) async {
    final teachers = TeachersProvider.of(context, listen: false);
    await Future.wait([
      teachers.fetchData(
        id: teachers.currentTeacher?.id ?? '-1',
        fields: FetchableFields.all,
      ),
    ]);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchTeacher(context),
      builder: (context, snapshot) {
        final teacher =
            TeachersProvider.of(context, listen: false).currentTeacher;
        if (teacher == null) {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }

        final hasFullData = snapshot.connectionState == ConnectionState.done;
        return _MyAccountScreenInternal(hasFullData: hasFullData);
      },
    );
  }
}

class _MyAccountScreenInternal extends StatelessWidget {
  const _MyAccountScreenInternal({required this.hasFullData});

  final bool hasFullData;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building MyAccountScreen');

    final currentTeacher =
        TeachersProvider.of(context, listen: true).currentTeacher;

    return ResponsiveService.scaffoldOf(
      context,
      appBar: ResponsiveService.appBarOf(
        context,
        title: const Text('Mon compte'),
      ),
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body:
          hasFullData
              ? (currentTeacher == null
                  ? Center(child: Text('Aucun enseignant trouvé'))
                  : TeacherListTile(teacher: currentTeacher))
              : Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              ),
    );
  }
}
