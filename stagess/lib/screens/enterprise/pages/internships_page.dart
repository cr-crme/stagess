import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/enterprise_extension.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/router.dart';
import 'package:stagess/screens/internship_forms/enterprise_steps/enterprise_evaluation_screen.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = Logger('InternshipsPage');

class InternshipsPage extends StatefulWidget {
  const InternshipsPage({
    super.key,
    required this.enterprise,
    required this.onAddInternshipRequest,
  });

  final Enterprise enterprise;
  final Function(Enterprise, Specialization?) onAddInternshipRequest;

  @override
  State<InternshipsPage> createState() => InternshipsPageState();
}

class InternshipsPageState extends State<InternshipsPage> {
  Future<void> addStage() async =>
      widget.onAddInternshipRequest(widget.enterprise, null);

  List<Internship> _getActiveInternships(List<Internship> internships) {
    _logger.finer(
      'Getting active internships for enterprise: ${widget.enterprise.id}',
    );

    final List<Internship> out = [];
    for (final internship in internships) {
      if (internship.isActive) out.add(internship);
    }

    return out;
  }

  List<Internship> _getClosedInternships(List<Internship> internships) {
    _logger.finer(
      'Getting closed internships for enterprise: ${widget.enterprise.id}',
    );

    final currentId = TeachersProvider.of(context).currentTeacher?.id;

    final List<Internship> out = [];
    for (final internship in internships) {
      if (internship.isClosed ||
          internship.isEnterpriseEvaluationPending &&
              !internship.supervisingTeacherIds.contains(currentId)) {
        out.add(internship);
      }
    }
    return out;
  }

  List<Internship> _getToEvaluateInternships(List<Internship> internships) {
    _logger.finer(
      'Getting internships to evaluate for enterprise: ${widget.enterprise.id}',
    );

    final currentId = TeachersProvider.of(context).currentTeacher?.id;
    if (currentId == null) return [];

    final List<Internship> out = [];
    for (final internship in internships) {
      if (internship.isEnterpriseEvaluationPending &&
          internship.supervisingTeacherIds.contains(currentId)) {
        out.add(internship);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building InternshipsPage for enterprise: ${widget.enterprise.id}',
    );

    final internships = widget.enterprise.internships(context, listen: true);

    final toEvaluate = _getToEvaluateInternships(internships);
    final active = _getActiveInternships(internships);
    final closed = _getClosedInternships(internships);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (toEvaluate.isNotEmpty)
            _InternshipList(
              title: 'Stages à évaluer',
              internships: toEvaluate,
              enterprise: widget.enterprise,
            ),
          if (active.isNotEmpty)
            _InternshipList(
              title: 'En cours',
              internships: active,
              enterprise: widget.enterprise,
            ),
          if (closed.isNotEmpty)
            _InternshipList(
              title: 'Historique des stages',
              internships: closed,
              enterprise: widget.enterprise,
            ),
        ],
      ),
    );
  }
}

class _InternshipList extends StatefulWidget {
  const _InternshipList({
    required this.title,
    required this.internships,
    required this.enterprise,
  });

  final String title;
  final List<Internship> internships;
  final Enterprise enterprise;

  @override
  State<_InternshipList> createState() => _InternshipListState();
}

class _InternshipListState extends State<_InternshipList> {
  final _expanded = <String, bool>{};

  void _prepareExpander(List<Internship> internships) {
    if (_expanded.length != widget.internships.length) {
      _expanded.clear();
      for (final internship in internships) {
        _expanded[internship.id] = false;
      }
    }
  }

  Widget _dateBuild(Internship internship) {
    final endDate =
        internship.isActive ? internship.dates.end : internship.endDate;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            const Text('Début\u00a0:'),
            Text(
              '${internship.dates.start.year.toString().padLeft(4, '0')}-'
              '${internship.dates.start.month.toString().padLeft(2, '0')}-'
              '${internship.dates.start.day.toString().padLeft(2, '0')}',
            ),
          ],
        ),
        Column(
          children: [
            Text('${internship.isActive ? 'Fin prévue' : 'Fin'}\u00a0:'),
            Text(
              '${endDate.year.toString().padLeft(4, '0')}-'
              '${endDate.month.toString().padLeft(2, '0')}-'
              '${endDate.day.toString().padLeft(2, '0')}',
            ),
          ],
        ),
      ],
    );
  }

  void _sendEmail(Teacher teacher) {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: teacher.email!);
    launchUrl(emailLaunchUri);
  }

  void _evaluateEnterprise(context, Internship internship) async {
    await showEnterpriseEvaluationDialog(context, internshipId: internship.id);
  }

  /// Returns if the current teacher can control the internship that has the
  /// id [internshipId].
  bool _canSeeDetails({required String internshipId}) {
    final internship = InternshipsProvider.of(context)[internshipId];
    final student = StudentsHelpers.studentsInMyGroups(
      context,
    ).firstWhereOrNull((e) => e.id == internship.studentId);

    return student != null;
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building InternshipList for enterprise: ${widget.enterprise.id}',
    );

    _prepareExpander(widget.internships);
    final teachers = TeachersProvider.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubTitle(widget.title),
        Column(
          children: [
            ...widget.internships.map((internship) {
              final specialization =
                  widget.enterprise.jobs[internship.jobId].specialization;
              final student = StudentsProvider.of(
                context,
              ).firstWhereOrNull((e) => e.id == internship.studentId);
              final signatoryTeacher = teachers.firstWhere(
                (e) => e.id == internship.signatoryTeacherId,
              );
              final canSeeDetails = _canSeeDetails(internshipId: internship.id);

              if (student == null) return Container();

              return AnimatedExpandingCard(
                initialExpandedState: _expanded[internship.id] ?? false,
                onTapHeader:
                    (newState) =>
                        setState(() => _expanded[internship.id] = newState),
                header:
                    (ctx, isExpanded) => Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 120,
                                  child: Text(
                                    '${internship.dates.start.year.toString()}'
                                    '${internship.dates.end.year == internship.dates.start.year ? '' : ' \u2014 ${internship.dates.end.year.toString()}'}',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Text(
                                  student.fullName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Stagiaire ${student.program}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Flexible(
                            child: Text(
                              specialization.idWithName,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: null,
                            ),
                          ),
                          if (!(_expanded[internship.id] ?? false))
                            SizedBox(height: 8.0),
                        ],
                      ),
                    ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            const Text(
                              'Enseignant\u00b7e\u00b7s superviseur\u00b7e\u00b7s de stage\u00a0: ',
                            ),
                            GestureDetector(
                              onTap:
                                  signatoryTeacher.email == null
                                      ? null
                                      : () => _sendEmail(signatoryTeacher),
                              child: Text(
                                signatoryTeacher.fullName,
                                style:
                                    signatoryTeacher.email == null
                                        ? null
                                        : Theme.of(
                                          context,
                                        ).textTheme.titleSmall!.copyWith(
                                          decoration: TextDecoration.underline,
                                          color: Colors.blue,
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Responsable en milieu de stage\u00a0: ${widget.internships.last.supervisor.fullName}',
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, bottom: 15),
                        child: _dateBuild(internship),
                      ),
                      if (canSeeDetails)
                        Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              bottom: 8.0,
                              right: 12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (internship.isEnterpriseEvaluationPending)
                                  Padding(
                                    padding: EdgeInsets.only(right: 16.0),
                                    child: TextButton(
                                      onPressed:
                                          () => _evaluateEnterprise(
                                            context,
                                            internship,
                                          ),
                                      child: const Text(
                                        'Évaluer l\'entreprise',
                                      ),
                                    ),
                                  ),
                                TextButton(
                                  onPressed:
                                      () => GoRouter.of(context).pushNamed(
                                        Screens.student,
                                        pathParameters: Screens.params(student),
                                        queryParameters: Screens.queryParams(
                                          pageIndex: '1',
                                        ),
                                      ),
                                  child: const Text(
                                    'Détails du stage',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
