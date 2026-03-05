import 'package:flutter/services.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/enterprises/job_comment.dart';
import 'package:stagess_common/models/enterprises/job_list.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/generic/photo.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/internship_contract.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart'
    as attitude;
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/internship_evaluation_visa.dart'
    as visa;
import 'package:stagess_common/models/internships/post_internship_enterprise_evaluation.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/sst_evaluation.dart';
import 'package:stagess_common/models/internships/task_appreciation.dart';
import 'package:stagess_common/models/internships/time_utils.dart';
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/itineraries/itinerary.dart';
import 'package:stagess_common/models/itineraries/visiting_priority.dart';
import 'package:stagess_common/models/itineraries/waypoint.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/services/job_data_file_service.dart';

void expectNear(double a, double b, {double epsilon = 1e-8}) {
  if ((a - b).abs() > epsilon) {
    throw Exception('Expected $a to be near $b within $epsilon');
  }
}

School dummySchool({String? id}) => School(
      id: id,
      name: 'Meine Schule',
      address: Address.empty,
      phone: PhoneNumber.empty,
    );

Teacher dummyTeacher({
  String id = 'teacherId',
  String schoolBoardId = 'school_board_id',
  String schoolId = 'school_id',
  List<String> groups = const ['101', '102'],
}) =>
    Teacher(
      id: id,
      firstName: 'Pierre',
      middleName: 'Jean',
      lastName: 'Jacques',
      schoolBoardId: schoolBoardId,
      schoolId: schoolId,
      hasRegisteredAccount: false,
      groups: groups,
      email: 'peter.john.jakob@test.com',
      phone: dummyPhoneNumber(),
      address: null,
      dateBirth: null,
      itineraries: [],
      visitingPriorities: {
        'element1': VisitingPriority.low,
        'element2': VisitingPriority.high,
      },
    );

Student dummyStudent({
  String firstName = 'Jeanne',
  String lastName = 'Doe',
  String id = 'studentId',
  Program program = Program.fpt,
  String group = '101',
}) {
  final tp = dummyPerson(firstName: firstName, lastName: lastName);
  return Student(
    id: id,
    schoolBoardId: 'schoolBoardId',
    schoolId: 'schoolId',
    firstName: tp.firstName,
    middleName: tp.middleName,
    lastName: tp.lastName,
    dateBirth: tp.dateBirth,
    email: tp.email,
    phone: tp.phone,
    address: tp.address,
    contact: Person(
      id: 'My mother id',
      firstName: 'Jeanne',
      middleName: null,
      lastName: 'Doe',
      dateBirth: null,
      phone: PhoneNumber.empty,
      address: Address.empty,
      email: null,
    ),
    photo: '0x00FF00',
    contactLink: 'Mère',
    group: group,
    program: program,
  );
}

Person dummyPerson({
  String id = 'personId',
  String firstName = 'Jeanne',
  String lastName = 'Doe',
}) =>
    Person(
      id: id,
      firstName: firstName,
      middleName: 'Kathlin',
      lastName: lastName,
      address: dummyAddress(),
      dateBirth: DateTime(2000, 1, 1),
      email: 'jeanne.k.doe@test.com',
      phone: dummyPhoneNumber(),
    );

PhoneNumber dummyPhoneNumber({int? extension}) => PhoneNumber.fromString(
      '800-555-5555${extension == null ? '' : ' poste $extension'}',
    );

Address dummyAddress({
  bool skipCivicNumber = false,
  bool skipStreet = false,
  bool skipApartment = false,
  bool skipCity = false,
  bool skipPostalCode = false,
}) =>
    Address(
      civicNumber: skipCivicNumber ? null : 100,
      street: skipStreet ? null : 'Wunderbar',
      apartment: skipApartment ? null : 'A',
      city: skipCity ? null : 'Wonderland',
      postalCode: skipPostalCode ? null : 'H0H 0H0',
    );

JobList dummyJobList() {
  return JobList()..add(dummyJob());
}

Uniforms dummyUniforms({String? id}) => Uniforms(
      id: id,
      status: UniformStatus.suppliedByEnterprise,
      uniforms: [
        'Un beau chapeu bleu',
        'Une belle chemise rouge',
        'Une cravate jaune peu désirable',
      ],
    );

Protections dummyProtections({String? id}) => Protections(
      id: id,
      status: ProtectionsStatus.suppliedByEnterprise,
      protections: [
        'Une veste de mithril',
        'Une cotte de maille',
        'Une drole de bague',
      ],
    );

Incidents dummyIncidents({String? id}) => Incidents(
      id: id,
      severeInjuries: [],
      minorInjuries: [
        Incident(
            teacherId: 'teacher1',
            date: DateTime.now(),
            'Un "petit" truc avec la scie sauteuse'),
        Incident(
            teacherId: 'teacher1',
            date: DateTime.now(),
            'Une "légère" entaille de la main au couteau'),
      ],
      verbalAbuses: [
        Incident(
            teacherId: 'teacher1',
            date: DateTime.now(),
            'Vaut mieux ne pas détailler...')
      ],
    );

SstEvaluation dummySstEvaluation({String? id}) => SstEvaluation(
      id: id,
      presentAtEvaluation: ['Responsable en milieu de stage'],
      questions: {
        'Q1': ['Oui'],
        'Q1+t': ['Peu souvent, à la discrétion des employés.'],
        'Q3': ['Un diable'],
        'Q5': ['Des ciseaux'],
        'Q9': ['Des solvants', 'Des produits de nettoyage'],
        'Q12': ['Bruyant'],
        'Q12+t': ['Bouchons a oreilles'],
        'Q15': ['Oui'],
      },
      date: DateTime(2000, 1, 1),
    );

PreInternshipRequests dummyPreInternshipRequests({String? id}) =>
    PreInternshipRequests(
      id: id,
      requests: [PreInternshipRequestTypes.judiciaryBackgroundCheck],
      other: 'Manger de la poutine',
      isApplicable: true,
    );

Photo dummyPhoto() => Photo(
      id: 'photoId',
      bytes: Uint8List.fromList(List.generate(100, (index) => index % 256)),
    );

JobComment dummyJobComment({
  String comment = 'This is a comment',
  String teacherId = 'teacherId',
  DateTime? date,
}) =>
    JobComment(
      id: 'jobCommentId',
      comment: 'newComment',
      teacherId: 'teacherId',
      date: DateTime(2023, 10, 1),
    );

Job dummyJob({
  String id = 'jobId',
  String? incidentsId,
  String? preInternshipId,
  String? uniformId,
  String? protectionsId,
}) =>
    Job(
      id: id,
      specialization:
          ActivitySectorsService.activitySectors[2].specializations[9],
      positionsOffered: {'school_id': 2},
      incidents: dummyIncidents(id: incidentsId ?? id),
      minimumAge: 12,
      preInternshipRequests:
          dummyPreInternshipRequests(id: preInternshipId ?? id),
      uniforms: dummyUniforms(id: uniformId ?? id),
      protections: dummyProtections(id: protectionsId ?? id),
      reservedForId: '',
    );

Enterprise dummyEnterprise({bool addJob = false}) {
  final jobs = JobList();
  if (addJob) {
    jobs.add(dummyJob());
  }
  return Enterprise(
    schoolBoardId: 'schoolBoardId',
    id: 'enterpriseId',
    name: 'Not named',
    status: EnterpriseStatus.active,
    activityTypes: {},
    recruiterId: 'Nobody',
    jobs: jobs,
    contact: dummyPerson(),
    address: dummyAddress(),
    headquartersAddress: dummyAddress(),
  );
}

PostInternshipEnterpriseEvaluation dummyPostInternshipEnterpriseEvaluation({
  String id = 'postInternshipEnterpriseEvaluationId',
  String internshipId = 'internshipId',
}) =>
    PostInternshipEnterpriseEvaluation(
        id: id,
        date: DateTime(2005, 11, 25),
        internshipId: internshipId,
        skillsRequired: [
          'Communiquer à l\'écrit',
          'Interagir avec des clients'
        ],
        taskVariety: 0,
        trainingPlanRespect: 1,
        autonomyExpected: 4,
        efficiencyExpected: 2,
        specialNeedsAccommodation: 3,
        supervisionStyle: 1,
        easeOfCommunication: 5,
        absenceAcceptance: 4,
        sstManagement: 1);

visa.InternshipEvaluationVisa dummyInternshipVisaEvaluation({
  String id = 'internshipVisaEvaluationId',
}) =>
    visa.InternshipEvaluationVisa(
      id: id,
      date: DateTime(1980, 5, 20),
      formVersion: visa.InternshipEvaluationVisa.currentVersion,
      form: visa.VisaEvaluation(
        id: 'visaEvaluationId',
        inattendance: visa.Inattendance.rarely,
        ponctuality: visa.Ponctuality.sometimeLate,
        sociability: visa.Sociability.veryLow,
        politeness: visa.Politeness.alwaysSuitable,
        motivation: visa.Motivation.low,
        dressCode: visa.DressCode.notAppropriate,
        qualityOfWork: visa.QualityOfWork.high,
        productivity: visa.Productivity.low,
        autonomy: visa.Autonomy.none,
        cautiousness: visa.Cautiousness.mostly,
        generalAppreciation: visa.GeneralAppreciation.passable,
      ),
    );

Internship dummyInternship({
  String id = 'internshipId',
  String schoolBoardId = 'schoolBoardId',
  String jobId = 'jobId',
  DateTime? versionDate,
  String studentId = 'studentId',
  String teacherId = 'teacherId',
  String enterpriseId = 'enterpriseId',
  bool hasEndDate = false,
  int achievedLength = 130,
}) {
  return Internship(
    id: id,
    schoolBoardId: schoolBoardId,
    studentId: studentId,
    signatoryTeacherId: teacherId,
    extraSupervisingTeacherIds: [],
    enterpriseId: enterpriseId,
    endDate: hasEndDate ? DateTime(2034, 10, 28) : DateTime(0),
    achievedDuration: achievedLength,
    contracts: [
      dummyInternshipContract(date: versionDate, jobId: jobId),
    ],
    enterpriseEvaluations: [
      dummyPostInternshipEnterpriseEvaluation(internshipId: id)
    ],
    sstEvaluations: [dummySstEvaluation(id: id)],
    skillEvaluations: [dummyInternshipEvaluationSkill()],
    attitudeEvaluations: [dummyInternshipEvaluationAttitude()],
    visaEvaluations: [dummyInternshipVisaEvaluation()],
    teacherNotes: '',
  );
}

DailySchedule dummyDailySchedule({String id = 'dailyScheduleId'}) {
  return DailySchedule(
    id: id,
    blocks: [
      TimeBlock(
        id: 'timeBlockId1',
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 12, minute: 0),
      ),
      TimeBlock(
        id: 'timeBlockId2',
        start: const TimeOfDay(hour: 13, minute: 0),
        end: const TimeOfDay(hour: 15, minute: 0),
      ),
    ],
  );
}

WeeklySchedule dummyWeeklySchedule({
  String id = 'weeklyScheduleId',
  DateTimeRange? period,
}) {
  return WeeklySchedule(
    id: id,
    schedule: {
      Day.monday: dummyDailySchedule(id: 'dailyScheduleId1'),
      Day.tuesday: dummyDailySchedule(id: 'dailyScheduleId2'),
      Day.wednesday: dummyDailySchedule(id: 'dailyScheduleId3'),
      Day.thursday: dummyDailySchedule(id: 'dailyScheduleId4'),
      Day.friday: dummyDailySchedule(id: 'dailyScheduleId5'),
    },
    period: period ??
        DateTimeRange(start: DateTime(2026, 1, 2), end: DateTime(2026, 1, 22)),
  );
}

Waypoint dummyWaypoint({
  String id = 'waypointId',
  double latitude = 40.0,
  double longitude = 50.0,
}) =>
    Waypoint(
      id: id,
      title: 'Waypoint',
      subtitle: 'Subtitle',
      address: Address(
        civicNumber: 123,
        street: 'rue de la rue',
        city: 'Ville',
        postalCode: 'H0H 0H0',
        latitude: latitude,
        longitude: longitude,
      ),
    );

Itinerary dummyItinerary({
  String id = 'itineraryId',
  String studentId = 'studentId',
  String teacherId = 'teacherId',
  String enterpriseId = 'enterpriseId',
  String jobId = 'jobId',
  DateTime? date,
}) =>
    Itinerary(id: id, date: date ?? DateTime(2000, 1, 1))
      ..add(dummyWaypoint())
      ..add(dummyWaypoint(id: 'waypointId2', latitude: 30.0, longitude: 30.5));

attitude.AttitudeEvaluation dummyAttitudeEvaluation({
  String id = 'attitudeEvaluationId',
}) =>
    attitude.AttitudeEvaluation(
      id: id,
      ponctuality: attitude.Ponctuality.high,
      inattendance: attitude.Inattendance.low,
      qualityOfWork: attitude.QualityOfWork.high,
      productivity: attitude.Productivity.low,
      teamCommunication: attitude.TeamCommunication.low,
      respectOfAuthority: attitude.RespectOfAuthority.veryHigh,
      communicationAboutSst: attitude.CommunicationAboutSst.insufficient,
      selfControl: attitude.SelfControl.high,
      takeInitiative: attitude.TakeInitiative.low,
      adaptability: attitude.Adaptability.veryHigh,
    );

attitude.InternshipEvaluationAttitude dummyInternshipEvaluationAttitude({
  String id = 'internshipEvaluationAttitudeId',
}) =>
    attitude.InternshipEvaluationAttitude(
      id: id,
      date: DateTime(1980, 5, 20),
      presentAtEvaluation: ['Me', 'You'],
      attitude: dummyAttitudeEvaluation(),
      formVersion: '1.0.0',
    );

TaskAppreciation dummyTaskAppreciation() => TaskAppreciation(
      id: 'taskAppreciationId',
      title: 'Task title',
      level: TaskAppreciationLevel.autonomous,
    );

SkillEvaluation dummySkillEvaluation({String id = 'skillEvaluationId'}) =>
    SkillEvaluation(
      id: id,
      specializationId: 'specializationId',
      skillName: 'skillName',
      tasks: [dummyTaskAppreciation()],
      appreciation: SkillAppreciation.failed,
      comments: 'comment',
    );

InternshipEvaluationSkill dummyInternshipEvaluationSkill({
  String id = 'internshipEvaluationSkillId',
}) =>
    InternshipEvaluationSkill(
      id: id,
      date: DateTime(1980, 5, 20),
      presentAtEvaluation: ['Me', 'You'],
      skillGranularity: SkillEvaluationGranularity.byTask,
      skills: [dummySkillEvaluation()],
      comments: 'No comment',
      formVersion: '1.0.0',
    );

InternshipContract dummyInternshipContract(
        {String id = 'internshipContractId',
        String jobId = 'jobId',
        DateTime? date}) =>
    InternshipContract(
      id: id,
      date: date ?? DateTime(1980, 5, 20),
      jobId: jobId,
      extraSpecializationIds: [
        ActivitySectorsService.activitySectors[2].specializations[1].id,
        ActivitySectorsService.activitySectors[1].specializations[0].id,
      ],
      supervisor: dummyPerson(),
      dates: DateTimeRange(
        start: DateTime(2000, 1, 1),
        end: DateTime(2000, 1, 31),
      ),
      weeklySchedules: [dummyWeeklySchedule()],
      transportations: [Transportation.none],
      visitFrequencies: 'Tous les jours',
      expectedDuration: 135,
      formVersion: InternshipContract.currentVersion,
    );
