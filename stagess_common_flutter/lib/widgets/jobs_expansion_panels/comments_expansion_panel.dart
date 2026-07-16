import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/enterprises/job_comment.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/helpers/internships_helpers.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/dialogs/add_text_dialog.dart';
import 'package:stagess_common_flutter/widgets/itemized_text.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('CommentsExpansionPanel');

class CommentsExpansionPanel extends StatelessWidget {
  const CommentsExpansionPanel({
    super.key,
    required this.enterpriseId,
    required this.job,
  });

  final String? enterpriseId;
  final Job job;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building CommentsExpansionPanel for job: ${job.specialization.name}');

    final teachers = TeachersProvider.of(context);
    final admins = AdminsProvider.of(context);

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) =>
          const ListTile(title: Text('Commentaires')),
      child: SizedBox(
        width: Size.infinite.width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: job.comments.isEmpty
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              job.comments.isEmpty
                  ? const Text('Il n\'y a présentement aucun commentaire.')
                  : ItemizedText(
                      job.comments.map(
                        (e) {
                          final writer =
                              teachers.fromIdOrNull(e.userId)?.fullName ??
                                  admins.fromIdOrNull(e.userId)?.fullName ??
                                  'Un·e personne inconnue';
                          return '$writer (${DateFormat.yMMMEd('fr_CA').format(e.date)}) - '
                              '${e.comment}';
                        },
                      ).toList(),
                      interline: 8),
              Center(
                child: IconButton(
                  onPressed: enterpriseId == null
                      ? null
                      : () => _addComment(context, job),
                  icon: Icon(Icons.add_comment,
                      color: Theme.of(context).primaryColor, size: 36),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addComment(BuildContext context, Job job) async {
    final authProvider = AuthProvider.of(context, listen: false);

    _logger.finer('Adding comment to job: ${job.specialization.name}');
    final userId = authProvider.currentId;
    if (userId == null) {
      _logger.warning('No teacher ID found when adding comment to job.');
      showSnackBar(
        context,
        message: 'Vous devez être connecté pour ajouter un commentaire.',
      );
      return;
    }
    final enterprises = EnterprisesProvider.of(context, listen: false);
    final enterprise = enterprises.fromId(enterpriseId!);
    final internship = InternshipsProvider.of(context, listen: false).where(
      (internship) =>
          internship.enterpriseId == enterprise.id &&
          internship.hasAccessToPrivateFields(context),
    );
    if (authProvider.databaseAccessLevel < AccessLevel.schoolAdmin &&
        internship.isEmpty) {
      _logger.warning(
        'No internship found for teacher ID when adding comment to job: $userId',
      );
      showSnackBar(
        context,
        message:
            'Vous devez avoir supervisé au moins un stage dans cette entreprise pour y ajouter un commentaire.',
      );
      return;
    }

    final hasLock = await enterprises.getLockForItem(enterprise);
    if (!hasLock || !context.mounted) {
      if (context.mounted) {
        showSnackBar(
          context,
          message:
              'Impossible d\'ajouter un commentaire, car l\'entreprise est en cours de modification par un autre utilisateur.',
        );
      }
      return;
    }

    final newComment = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) =>
          const AddTextDialog(title: 'Ajouter un commentaire', maxLength: 2000),
    );

    if (newComment == null) {
      await enterprises.releaseLockForItem(enterprise);
      return;
    }
    job.comments.add(
      JobComment(comment: newComment, userId: userId, date: DateTime.now()),
    );
    await enterprises.replaceWithConfirmation(enterprise);
    await enterprises.releaseLockForItem(enterprise);
    if (context.mounted) {
      showSnackBar(context, message: 'Le commentaire a été ajouté');
    }
    _logger.finer('Comment added to job: ${job.specialization.name}');
  }
}
