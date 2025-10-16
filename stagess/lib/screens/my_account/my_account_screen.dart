import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/screens/my_account/widgets/teacher_list_tile.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

final _logger = Logger('MyAccountScreen');

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  static const String route = '/my-account';

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
          currentTeacher == null
              ? Center(child: Text('Aucun enseignant trouvé'))
              : TeacherListTile(teacher: currentTeacher),
    );
  }
}
