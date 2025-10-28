import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/students_extension.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/router.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/schedule_selector.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = Logger('SupervisionStudentDetailsScreen');

Internship? _getInternship(BuildContext context, {required String studentId}) {
  final internships = InternshipsProvider.of(context, listen: false);
  final internship = internships.byStudentId(studentId).lastOrNull;
  return (internship?.isActive ?? false) ? internship : null;
}

Enterprise? _getEnterprise(BuildContext context, {required String studentId}) {
  final internship = _getInternship(context, studentId: studentId);
  if (internship == null) return null;
  final enterprises = EnterprisesProvider.of(context, listen: false);
  return enterprises.fromIdOrNull(internship.enterpriseId);
}

Job? _getJob(BuildContext context, {required String studentId}) {
  final internship = _getInternship(context, studentId: studentId);
  final enterprise = _getEnterprise(context, studentId: studentId);
  if (internship == null || enterprise == null) return null;
  return enterprise.jobs[internship.jobId];
}

Student? _getStudent(BuildContext context, {required String studentId}) {
  final students = StudentsHelpers.studentsInMyGroups(context);
  return students.firstWhereOrNull((e) => e.id == studentId);
}

class SupervisionStudentDetailsScreen extends StatelessWidget {
  const SupervisionStudentDetailsScreen({super.key, required this.studentId});
  static const route = '/student-details';

  final String studentId;

  Future<void> _fetchInfo(BuildContext context) async {
    final students = StudentsProvider.of(context, listen: false);
    final enterprises = EnterprisesProvider.of(context, listen: false);
    final internships = InternshipsProvider.of(context, listen: false);

    Student? student;
    Enterprise? enterprise;
    Internship? internship;

    final endTime = DateTime.now().add(Duration(seconds: 5));
    while ((student == null || enterprise == null || internship == null) &&
        DateTime.now().isBefore(endTime)) {
      student = _getStudent(context, studentId: studentId);
      enterprise = _getEnterprise(context, studentId: studentId);
      internship = _getInternship(context, studentId: studentId);
    }
    await Future.wait([
      if (student == null)
        students.fetchData(id: studentId, fields: FetchableFields.all),
      enterprises.fetchData(
        id: enterprise?.id ?? '-1',
        fields: FetchableFields({
          'jobs': FetchableFields.all,
          'contact': FetchableFields.all,
        }),
      ),
      internships.fetchData(
        id: internship?.id ?? '-1',
        fields: FetchableFields({
          'mutables': FetchableFields.all,
          'teacher_notes': FetchableFields.all,
        }),
      ),
    ]);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchInfo(context),
      builder: (context, snapshot) {
        return _SupervisionStudentDetailsScreenInternal(
          studentId: studentId,
          hasFullData: snapshot.connectionState == ConnectionState.done,
        );
      },
    );
  }
}

class _SupervisionStudentDetailsScreenInternal extends StatelessWidget {
  const _SupervisionStudentDetailsScreenInternal({
    required this.studentId,
    required this.hasFullData,
  });

  final String studentId;
  final bool hasFullData;

  void _navigateToStudentInternship(BuildContext context) {
    GoRouter.of(context).pushNamed(
      Screens.student,
      pathParameters: Screens.params(studentId),
      queryParameters: Screens.queryParams(pageIndex: '1'),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building SupervisionStudentDetailsScreen for student: $studentId',
    );
    final internship = _getInternship(context, studentId: studentId);
    final enterprise = _getEnterprise(context, studentId: studentId);
    final job = _getJob(context, studentId: studentId);
    final student = _getStudent(context, studentId: studentId);

    return ResponsiveService.scaffoldOf(
      context,
      appBar: ResponsiveService.appBarOf(
        context,
        title:
            student == null || !hasFullData
                ? Text(
                  hasFullData
                      ? 'Aucun élève trouvé'
                      : 'Chargement des informations',
                )
                : Row(
                  children: [
                    student.avatar,
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(student.fullName),
                        Text(
                          enterprise?.name ?? 'Aucun stage',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
      ),
      smallDrawer: null,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body:
          hasFullData
              ? SingleChildScrollView(
                child: Builder(
                  builder: (context) {
                    if (student == null) {
                      return const Center(child: Text('Aucun élève trouvé'));
                    }
                    if (internship == null) {
                      return const Center(child: Text('Aucun stage trouvé'));
                    }
                    if (enterprise == null) {
                      return const Center(
                        child: Text('Aucune entreprise trouvée'),
                      );
                    }
                    if (job == null) {
                      return const Center(child: Text('Aucun emploi trouvé'));
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _IsOver(
                          studentId: studentId,
                          onTapGoToInternship:
                              () => _navigateToStudentInternship(context),
                        ),
                        _Contact(
                          student: student,
                          enterprise: enterprise,
                          internship: internship,
                        ),
                        _PersonalNotes(internship: internship),
                        _Schedule(internship: internship),
                        _buildUniformAndEpi(context, job),
                        _MoreInfoButton(
                          studentId: studentId,
                          onTap: () => _navigateToStudentInternship(context),
                        ),
                      ],
                    );
                  },
                ),
              )
              : Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              ),
    );
  }

  Widget _buildUniformAndEpi(BuildContext context, Job job) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Exigences de l\'entreprise'),
        Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUniform(context, job),
              const SizedBox(height: 24),
              _buildProtections(context, job),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUniform(BuildContext context, Job job) {
    // Workaround for job.uniforms
    final uniforms = job.uniforms;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tenue de travail', style: Theme.of(context).textTheme.titleSmall),
        uniforms.status == UniformStatus.none
            ? const Text('Aucune consigne de l\'entreprise')
            : ItemizedText(uniforms.uniforms),
      ],
    );
  }
}

Widget _buildProtections(BuildContext context, Job job) {
  final protections = job.protections;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Équipements de protection individuelle',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      protections.status == ProtectionsStatus.none
          ? const Text('Aucun équipement requis')
          : ItemizedText(protections.protections),
    ],
  );
}

class _IsOver extends StatelessWidget {
  const _IsOver({required this.studentId, required this.onTapGoToInternship});

  final String studentId;
  final Function() onTapGoToInternship;

  @override
  Widget build(BuildContext context) {
    final internships = InternshipsProvider.of(context).byStudentId(studentId);
    if (internships.isEmpty) return Container();

    final internship = internships.last;
    final isOver = internship.dates.end.compareTo(DateTime.now()) < 1;

    return isOver
        ? Center(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.priority_high,
                    color: Theme.of(context).primaryColor,
                    size: 35,
                  ),
                  Text(
                    'La date de fin du stage est dépassée.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onTapGoToInternship,
                child: Text(
                  'Aller au stage',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(color: Colors.white),
                ),
              ),
            ],
          ),
        )
        : SizedBox.shrink();
  }
}

class _PersonalNotes extends StatefulWidget {
  const _PersonalNotes({required this.internship});

  final Internship internship;

  @override
  State<_PersonalNotes> createState() => _PersonalNotesState();
}

class _PersonalNotesState extends State<_PersonalNotes> {
  late final _textController =
      TextEditingController()..text = widget.internship.teacherNotes;

  void _sendComments() {
    final internships = InternshipsProvider.of(context, listen: false);
    if (_textController.text == widget.internship.teacherNotes) return;
    internships.updateTeacherNote(
      widget.internship.studentId,
      _textController.text,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool _editMode = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Particularités du stage à connaitre'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 32.0, bottom: 8),
              child: Text(
                '(ex. entrer par la porte 5 réservée au personnel, ...)',
              ),
            ),
            IconButton(
              onPressed:
                  () => setState(() {
                    _editMode = !_editMode;
                    if (!_editMode) _sendComments();
                  }),
              icon: Icon(
                _editMode ? Icons.save : Icons.edit,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: Container(
            width: MediaQuery.of(context).size.width * 5 / 6,
            decoration:
                _editMode
                    ? BoxDecoration(border: Border.all(color: Colors.grey))
                    : null,
            child:
                _editMode
                    ? TextField(
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      keyboardType: TextInputType.multiline,
                      minLines: 4,
                      maxLines: null,
                      controller: _textController,
                    )
                    : Text(
                      _textController.text.isEmpty
                          ? 'Aucun commentaire'
                          : _textController.text,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
          ),
        ),
      ],
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact({
    required this.student,
    required this.enterprise,
    required this.internship,
  });

  final Student student;
  final Enterprise enterprise;
  final Internship internship;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Contacts'),
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 8.0),
          child: Row(
            children: [
              InkWell(
                onTap: () => launchUrl(Uri.parse('tel:${student.phone}')),
                child: Icon(Icons.phone, color: Theme.of(context).primaryColor),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Élève',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${student.fullName}\n'
                      '${student.phone.toString() == '' ? 'Aucun téléphone enregistré' : student.phone}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 8.0),
          child: Row(
            children: [
              const Icon(Icons.home, color: Colors.black),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adresse de l\'entreprise',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        enterprise.address == null
                            ? 'Aucune adresse'
                            : '${enterprise.address!.civicNumber} ${enterprise.address!.street}\n'
                                '${enterprise.address!.city}\n'
                                '${enterprise.address!.postalCode}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 32.0, top: 8.0),
          child: Row(
            children: [
              InkWell(
                onTap:
                    () => launchUrl(
                      Uri.parse('tel:${internship.supervisor.phone}'),
                    ),
                child: Icon(Icons.phone, color: Theme.of(context).primaryColor),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Responsable en milieu de stage',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${internship.supervisor.fullName}\n'
                      '${internship.supervisor.phone.toString() == '' ? 'Aucun téléphone enregistré' : internship.supervisor.phone}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Schedule extends StatelessWidget {
  const _Schedule({required this.internship});

  final Internship internship;

  Widget _scheduleBuilder(
    BuildContext context,
    List<WeeklySchedule> schedules,
  ) {
    return ScheduleSelector(
      editMode: false,
      scheduleController: WeeklySchedulesController(
        weeklySchedules: internship.weeklySchedules,
        dateRange: internship.dates,
      ),
      leftPadding: 0,
      periodTextSize: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Horaire de stage'),
        Padding(
          padding: const EdgeInsets.only(left: 32),
          child: _scheduleBuilder(context, internship.weeklySchedules),
        ),
      ],
    );
  }
}

class _MoreInfoButton extends StatelessWidget {
  const _MoreInfoButton({required this.studentId, required this.onTap});

  final String studentId;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50.0, bottom: 40),
      child: Center(
        child: ElevatedButton(
          onPressed: onTap,
          child: const Text(
            'Plus de détails\nsur le stage',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
