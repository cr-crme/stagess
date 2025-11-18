import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/finalize_internship_dialog.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/router.dart';
import 'package:stagess/screens/internship_forms/enterprise_steps/enterprise_evaluation_screen.dart';
import 'package:stagess/screens/student/pages/widgets/internship_details.dart';
import 'package:stagess/screens/student/pages/widgets/internship_documents.dart';
import 'package:stagess/screens/student/pages/widgets/internship_evaluations.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('InternshipsPage');

class InternshipsPage extends StatefulWidget {
  const InternshipsPage({super.key, required this.student});

  final Student student;

  @override
  State<InternshipsPage> createState() => InternshipsPageState();
}

class InternshipsPageState extends State<InternshipsPage> {
  final activeKey = GlobalKey<_StudentInternshipListViewState>();
  final closedKey = GlobalKey<_StudentInternshipListViewState>();
  final toEvaluateKey = GlobalKey<_StudentInternshipListViewState>();

  List<Internship> _getActiveInternships(List<Internship> internships) {
    _logger.finer(
      'Fetching active internships for student: ${widget.student.id}',
    );

    final List<Internship> out = [];
    for (final internship in internships) {
      if (internship.isActive) out.add(internship);
    }
    _sortByDate(out);
    return out;
  }

  List<Internship> _getClosedInternships(List<Internship> internships) {
    _logger.finer(
      'Fetching closed internships for student: ${widget.student.id}',
    );

    final List<Internship> out = [];
    for (final internship in internships) {
      if (internship.isClosed) out.add(internship);
    }
    _sortByDate(out);
    return out;
  }

  List<Internship> _getToEvaluateInternships(List<Internship> internships) {
    _logger.finer(
      'Fetching internships to evaluate for student: ${widget.student.id}',
    );

    final List<Internship> out = [];
    for (final internship in internships) {
      if (internship.isEnterpriseEvaluationPending) out.add(internship);
    }
    _sortByDate(out);
    return out;
  }

  void _sortByDate(List<Internship> internships) {
    _logger.finer(
      'Sorting internships by start date for student: ${widget.student.id}',
    );
    internships.sort((a, b) => a.dates.start.compareTo(b.dates.start));
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building InternshipsPage for student: ${widget.student.id}');

    final internships = InternshipsProvider.of(
      context,
    ).byStudentId(widget.student.id);
    final toEvaluateInternships = _getToEvaluateInternships(internships);
    final activeInternships = _getActiveInternships(internships);
    final closedInternships = _getClosedInternships(internships);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (activeInternships.isNotEmpty)
            _StudentInternshipListView(
              key: activeKey,
              title: 'En cours',
              internships: activeInternships,
            ),
          if (activeInternships.isNotEmpty && toEvaluateInternships.isNotEmpty)
            const SizedBox(height: 12),
          if (toEvaluateInternships.isNotEmpty)
            _StudentInternshipListView(
              key: toEvaluateKey,
              title: 'Entreprises à évaluer',
              internships: toEvaluateInternships,
            ),
          if (toEvaluateInternships.isNotEmpty && closedInternships.isNotEmpty)
            const SizedBox(height: 12),
          if (closedInternships.isNotEmpty)
            _StudentInternshipListView(
              key: closedKey,
              title: 'Historique des stages',
              internships: closedInternships,
            ),
        ],
      ),
    );
  }
}

class _StudentInternshipListView extends StatefulWidget {
  const _StudentInternshipListView({
    super.key,
    required this.title,
    required this.internships,
  });

  final String title;
  final List<Internship> internships;

  @override
  State<_StudentInternshipListView> createState() =>
      _StudentInternshipListViewState();
}

class _StudentInternshipListViewState
    extends State<_StudentInternshipListView> {
  final Map<String, bool> _expanded = {};
  final Map<String, GlobalKey<InternshipDetailsState>> detailKeys = {};

  void _prepareExpander(List<Internship> internships) {
    if (_expanded.length != internships.length) {
      for (final internship in internships) {
        _expanded[internship.id] =
            internship.isActive || internship.isEnterpriseEvaluationPending;
      }
    }

    if (detailKeys.length != internships.length) {
      detailKeys.clear();
      for (final internship in internships) {
        detailKeys[internship.id] = GlobalKey<InternshipDetailsState>();
      }
    }
  }

  Widget _buildEnterpriseName(BuildContext context,
      {required Enterprise enterprise}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          enterprise.name,
          style: Theme.of(
            context,
          ).textTheme.titleLarge!.copyWith(color: Colors.black),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: InkWell(
            onTap: () => GoRouter.of(context).pushNamed(
              Screens.enterprise,
              pathParameters: Screens.params(enterprise),
              queryParameters: Screens.queryParams(pageIndex: '3'),
            ),
            borderRadius: BorderRadius.circular(25),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(
                Icons.open_in_new,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _evaluateEnterprise(BuildContext context, Internship internship) async {
    await showEnterpriseEvaluationDialog(context, internshipId: internship.id);
  }

  @override
  Widget build(BuildContext context) {
    _prepareExpander(widget.internships);

    final teacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;
    if (teacherId == null) {
      return const Center(child: Text('Vous n\'êtes pas connecté.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SubTitle(widget.title),
        Column(
          children: [
            ...widget.internships.asMap().keys.map((index) {
              final internship = widget.internships[index];
              final enterprise =
                  EnterprisesProvider.of(context)[internship.enterpriseId];

              final endDate = internship.isActive
                  ? DateFormat.yMMMd('fr_CA').format(internship.dates.end)
                  : DateFormat.yMMMd('fr_CA').format(internship.endDate);

              final String specializationIdWithName =
                  EnterprisesProvider.of(context)
                          .fromIdOrNull(internship.enterpriseId)
                          ?.jobs
                          .fromIdOrNull(internship.jobId)
                          ?.specialization
                          .idWithName ??
                      '';

              return AnimatedExpandingCard(
                initialExpandedState: _expanded[internship.id]!,
                header: (ctx, isExpanded) => ListTile(
                  title: _buildEnterpriseName(
                    context,
                    enterprise: enterprise,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(left: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            specializationIdWithName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(enterprise.address?.toString() ?? ''),
                        Text(
                          '${DateFormat.yMMMd('fr_CA').format(internship.dates.start)} - $endDate',
                        ),
                        if (internship.isActive &&
                            internship.supervisingTeacherIds.contains(
                              teacherId,
                            ))
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => showFinalizeInternshipDialog(
                                context,
                                internshipId: internship.id,
                              ),
                              child: const Text('Terminer le stage'),
                            ),
                          ),
                        if (internship.isEnterpriseEvaluationPending &&
                            internship.supervisingTeacherIds.contains(
                              teacherId,
                            ))
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => _evaluateEnterprise(
                                context,
                                internship,
                              ),
                              child: const Text('Évaluer l\'entreprise'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InternshipDetails(
                      key: detailKeys[internship.id],
                      internshipId: internship.id,
                    ),
                    InternshipSkills(internshipId: internship.id),
                    if (internship.supervisingTeacherIds.contains(teacherId))
                      InternshipDocuments(internship: internship),
                  ],
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}
