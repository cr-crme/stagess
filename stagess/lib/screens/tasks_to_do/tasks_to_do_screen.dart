import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/enterprise_extension.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/router.dart';
import 'package:stagess/screens/internship_forms/enterprise_steps/enterprise_evaluation_screen.dart';
import 'package:stagess/screens/sst_evaluation_form/sst_evaluation_form_screen.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

final _logger = Logger('TasksToDoScreen');

int numberOfTasksToDo(BuildContext context) {
  final taskFunctions = [
    _sstToEvaluate,
    _internshipsToTerminate,
    _postInternshipEvaluationToDo,
  ];
  return taskFunctions.fold<int>(0, (prev, e) => prev + e(context).length);
}

List<_EnterpriseInternshipStudent> _sstToEvaluate(BuildContext context) {
  // We should evaluate a job of an enterprise for the sst if there for each
  // internship where one of our students is doing this job
  final teacherId =
      TeachersProvider.of(context, listen: false).currentTeacher?.id;
  if (teacherId == null) return [];
  final internships = InternshipsProvider.of(context, listen: false);
  final enterprises = EnterprisesProvider.of(context, listen: false);
  final students = StudentsProvider.of(context, listen: false);

  // This happens sometimes, so we need to wait a frame
  if (internships.isEmpty) return [];

  List<_EnterpriseInternshipStudent> out = [];
  for (final internship in internships) {
    final isSstFilled = internship.sstEvaluation?.isFilled ?? false;
    if (!isSstFilled && internship.supervisingTeacherIds.contains(teacherId)) {
      final enterprise =
          enterprises.firstWhereOrNull((e) => e.id == internship.enterpriseId);
      final student =
          students.firstWhereOrNull((e) => e.id == internship.studentId);
      out.add(_EnterpriseInternshipStudent(
          internship: internship, enterprise: enterprise, student: student));
    }
  }

  _logger.fine('Found ${out.length} enterprises to evaluate');
  return out;
}

List<_EnterpriseInternshipStudent> _internshipsToTerminate(
    BuildContext context) {
  // We should terminate an internship if the end date is passed for more that
  // one day
  final internships = InternshipsProvider.of(context);
  final students = StudentsHelpers.mySupervizedStudents(context);
  final enterprises = EnterprisesProviderExtension.availableEnterprisesOf(
    context,
  );

  // This happens sometimes, so we need to wait a frame
  if (internships.isEmpty || students.isEmpty || enterprises.isEmpty) return [];

  List<_EnterpriseInternshipStudent> out = [];

  for (final internship in internships) {
    if (internship.shouldTerminate) {
      final student = students.firstWhereOrNull(
        (e) => e.id == internship.studentId,
      );
      if (student == null) continue;

      final enterprise = enterprises.firstWhereOrNull(
        (e) => e.id == internship.enterpriseId,
      );
      if (enterprise == null) continue;

      out.add(
        _EnterpriseInternshipStudent(
          internship: internship,
          student: student,
          enterprise: enterprise,
        ),
      );
    }
  }

  _logger.fine('Found ${out.length} internships to terminate');
  return out;
}

List<_EnterpriseInternshipStudent> _postInternshipEvaluationToDo(
    BuildContext context) {
  // We should evaluate an internship as soon as it is terminated
  final internships = InternshipsProvider.of(context);
  final students = StudentsHelpers.mySupervizedStudents(context);
  final enterprises = EnterprisesProviderExtension.availableEnterprisesOf(
    context,
  );

  // This happens sometimes, so we need to wait a frame
  if (internships.isEmpty || students.isEmpty || enterprises.isEmpty) return [];

  List<_EnterpriseInternshipStudent> out = [];

  for (final internship in internships) {
    if (internship.isEnterpriseEvaluationPending) {
      final student = students.firstWhereOrNull(
        (e) => e.id == internship.studentId,
      );
      if (student == null) continue;

      final enterprise = enterprises.firstWhereOrNull(
        (e) => e.id == internship.enterpriseId,
      );
      if (enterprise == null) continue;

      out.add(
        _EnterpriseInternshipStudent(
          internship: internship,
          student: student,
          enterprise: enterprise,
        ),
      );
    }
  }

  _logger.fine('Found ${out.length} post-internship evaluations to do');
  return out;
}

class TasksToDoScreen extends StatelessWidget {
  const TasksToDoScreen({super.key});

  static const route = '/tasks-to-do';

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building TasksToDoScreen');

    int nbTasksToDo = numberOfTasksToDo(context);

    return ResponsiveService.scaffoldOf(
      context,
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      appBar: ResponsiveService.appBarOf(
        context,
        title: const Text('Tâches à réaliser'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nbTasksToDo == 0) const _AllTasksDoneTitle(),
            const _SstRisk(),
            const _EndingInternship(),
            const _PostInternshipEvaluation(),
          ],
        ),
      ),
    );
  }
}

class _AllTasksDoneTitle extends StatelessWidget {
  const _AllTasksDoneTitle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24.0),
        child: Text(
          'Bravo!\nToutes les tâches ont été réalisées!',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

class _SstRisk extends StatelessWidget {
  const _SstRisk();

  @override
  Widget build(BuildContext context) {
    final data = _sstToEvaluate(context);

    data.sort(
      (a, b) => a.internship!.dates.start.compareTo(b.internship!.dates.start),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Repérer les risques SST'),
        ...(data.isEmpty
            ? [const _AllTasksDone()]
            : data.map((e) {
                final internship = e.internship;
                final enterprise = e.enterprise;
                final job = enterprise?.jobs
                    .firstWhere((j) => j.id == internship?.jobId);
                final student = e.student;
                if (internship == null ||
                    enterprise == null ||
                    job == null ||
                    student == null) {
                  _logger.severe(
                      'Missing data for SST task tile: internship=${internship?.id}, '
                      'enterprise=${enterprise?.id}, job=${job?.id}, student=${student?.id}');
                  return const SizedBox.shrink();
                }

                return _TaskTile(
                  title: student.fullName,
                  subtitle: '${enterprise.name} (${job.specialization.name})',
                  icon: Icons.warning,
                  iconColor: Theme.of(context).colorScheme.secondary,
                  date: internship.dates.start,
                  buttonTitle: 'Remplir le\nquestionnaire SST',
                  onTap: () => showSstEvaluationFormDialog(context,
                      internshipId: internship.id),
                );
              })),
      ],
    );
  }
}

class _EndingInternship extends StatelessWidget {
  const _EndingInternship();

  @override
  Widget build(BuildContext context) {
    final internships = _internshipsToTerminate(context);

    internships.sort(
      (a, b) => a.internship!.dates.end.compareTo(b.internship!.dates.end),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Terminer les stages'),
        ...(internships.isEmpty
            ? [const _AllTasksDone()]
            : internships.map((e) {
                final internship = e.internship!;
                final student = e.student!;
                final enterprise = e.enterprise!;

                return _TaskTile(
                  title: student.fullName,
                  subtitle: enterprise.name,
                  icon: Icons.flag,
                  iconColor: Colors.yellow.shade700,
                  date: internship.dates.end,
                  buttonTitle: 'Aller au stage',
                  onTap: () => GoRouter.of(context).pushNamed(
                    Screens.student,
                    pathParameters: Screens.params(student),
                    queryParameters: Screens.queryParams(pageIndex: '1'),
                  ),
                );
              })),
      ],
    );
  }
}

class _PostInternshipEvaluation extends StatelessWidget {
  const _PostInternshipEvaluation();

  @override
  Widget build(BuildContext context) {
    final internships = _postInternshipEvaluationToDo(context);

    internships.sort(
      (a, b) => a.internship!.endDate.compareTo(b.internship!.endDate),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Faire les évaluations post-stage'),
        ...(internships.isEmpty
            ? [const _AllTasksDone()]
            : internships.map((e) {
                final internship = e.internship!;
                final student = e.student!;
                final enterprise = e.enterprise!;

                return _TaskTile(
                  title: student.fullName,
                  subtitle: enterprise.name,
                  icon: Icons.rate_review,
                  iconColor: Colors.blueGrey,
                  date: internship.endDate,
                  buttonTitle: 'Évaluer l\'entreprise',
                  onTap: () => showEnterpriseEvaluationDialog(
                    context,
                    internshipId: internship.id,
                  ),
                );
              })),
      ],
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.date,
    required this.buttonTitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final DateTime date;
  final String buttonTitle;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final screenSize = ResponsiveService.getScreenSize(context);

    final button = SizedBox(
      width: 400,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            DateFormat.yMMMEd('fr_CA').format(date),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          TextButton(
            onPressed: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(buttonTitle, textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
    return Card(
      elevation: 10,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              SizedBox(width: 60, child: Icon(icon, color: iconColor)),
              Expanded(
                //width: MediaQuery.of(context).size.width - 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              if (screenSize == ScreenSize.large) button,
            ],
          ),
          if (screenSize != ScreenSize.large) button,
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _EnterpriseInternshipStudent {
  final Enterprise? enterprise;
  final Internship? internship;
  final Student? student;

  _EnterpriseInternshipStudent({
    this.enterprise,
    this.internship,
    this.student,
  });
}

class _AllTasksDone extends StatelessWidget {
  const _AllTasksDone();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 24.0),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: Colors.green),
          SizedBox(width: 4),
          Text('Aucune tâche à faire'),
        ],
      ),
    );
  }
}
