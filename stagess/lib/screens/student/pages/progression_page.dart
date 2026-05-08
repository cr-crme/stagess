import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/form_dialogs/widgets/student_visa_form.dart';
import 'package:stagess_common_flutter/widgets/skill_progression_tile.dart';

final _logger = Logger('SkillsPage');

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key, required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building SkillsPage for student: $studentId');
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkillProgressionCard(studentId: studentId),
          StudentVisaForm(studentId: studentId),
        ],
      ),
    );
  }
}

class _SkillProgressionCard extends StatelessWidget {
  const _SkillProgressionCard({required this.studentId});

  final String studentId;

  @override
  Widget build(BuildContext context) {
    return AnimatedExpandingCard(
        header: (context, isExpanded) => ListTile(
              title: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Text(
                  'Plan de formation',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Colors.black),
                ),
              ),
            ),
        child: SkillProgressionTile(studentId: studentId));
  }
}
