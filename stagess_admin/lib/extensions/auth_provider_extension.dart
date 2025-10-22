import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stagess_admin/screens/router.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/confirm_exit_dialog.dart';

extension AuthProviderExtension on AuthProvider {
  static Future<void> disconnectAll(
    BuildContext context, {
    required bool showConfirmDialog,
  }) async {
    if (showConfirmDialog) {
      final answer = await ConfirmExitDialog.show(
        context,
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
      );
      if (!answer || !context.mounted) return;
    }

    await AuthProvider.of(context).signOut();
    if (!context.mounted) return;

    await SchoolBoardsProvider.of(context, listen: false).disconnect();
    if (!context.mounted) return;
    InternshipsProvider.of(context, listen: false).disconnect();
    if (!context.mounted) return;
    await Future.wait([
      SchoolBoardsProvider.of(context, listen: false).disconnect(),
      InternshipsProvider.of(context, listen: false).disconnect(),
      StudentsProvider.of(context, listen: false).disconnect(),
      EnterprisesProvider.of(context, listen: false).disconnect(),
      TeachersProvider.of(context, listen: false).disconnect(),
      AdminsProvider.of(context, listen: false).disconnect(),
    ]);
    if (!context.mounted) return;

    GoRouter.of(context).goNamed(Screens.login);
  }
}
