import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('CommentsExpansionPanel');

class CommentsExpansionPanel extends StatelessWidget {
  const CommentsExpansionPanel({
    super.key,
    required this.job,
    required this.addComment,
  });

  final Job job;
  final void Function(Job job) addComment;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building CommentsExpansionPanel for job: ${job.specialization.name}');

    final teachers = TeachersProvider.of(context);

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
                      job.comments
                          .map(
                            (e) =>
                                '${teachers.fromId(e.teacherId).fullName} (${DateFormat.yMMMEd('fr_CA').format(e.date)}) - '
                                '${e.comment}',
                          )
                          .toList(),
                      interline: 8),
              Center(
                child: IconButton(
                  onPressed: () => addComment(job),
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
}
