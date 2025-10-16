// coverage:ignore-file
import 'dart:developer' as dev;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/enterprises/job_list.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/internships/schedule.dart';
import 'package:stagess_common/models/internships/time_utils.dart'
    as time_utils;
import 'package:stagess_common/models/internships/transportation.dart';
import 'package:stagess_common/models/itineraries/visiting_priority.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/backend_list_provided.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';

String _mySchoolBoardName = 'Mon premier centre de services scolaire';
String _mySchoolName = 'Ma deuxième école';
String _adminEmail = 'bb@bb.bb';
String _myEmail = 'cc@cc.cc';
String _myParternerEmail = 'romeo.montaigu@shakespeare.qc';

Future<void> resetDummyData(BuildContext context) async {
  final schoolBoards = SchoolBoardsProvider.of(context, listen: false);
  final admins = AdminsProvider.of(context, listen: false);
  final teachers = TeachersProvider.of(context, listen: false);
  final students = StudentsProvider.of(context, listen: false);
  final enterprises = EnterprisesProvider.of(context, listen: false);
  final internships = InternshipsProvider.of(context, listen: false);

  while (schoolBoards.isNotConnected ||
      admins.isNotConnected ||
      teachers.isNotConnected ||
      students.isNotConnected ||
      enterprises.isNotConnected ||
      internships.isNotConnected) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  await _removeAll(
    internships,
    enterprises,
    students,
    teachers,
    admins,
    schoolBoards,
  );

  await _addDummySchoolBoards(schoolBoards);
  await _addDummyAdmins(admins, schoolBoards: schoolBoards);
  await _addDummyTeachers(teachers, schoolBoards: schoolBoards);
  await _addDummyStudents(students, schoolBoards: schoolBoards);
  await _addDummyEnterprises(
    enterprises,
    schoolBoards: schoolBoards,
    teachers: teachers,
  );
  await _addDummyInternships(
    internships,
    schoolBoards: schoolBoards,
    enterprises: enterprises,
    students: students,
    teachers: teachers,
  );

  dev.log('Dummy reset data done');
}

Future<void> _removeAll(
  InternshipsProvider internships,
  EnterprisesProvider enterprises,
  StudentsProvider students,
  TeachersProvider teachers,
  AdminsProvider admins,
  SchoolBoardsProvider schoolBoards,
) async {
  dev.log('Removing dummy data');

  internships.clear(confirm: true);
  await _waitForDatabaseUpdate(internships, 0, strictlyEqualToExpected: true);

  enterprises.clear(confirm: true);
  await _waitForDatabaseUpdate(enterprises, 0, strictlyEqualToExpected: true);

  students.clear(confirm: true);
  await _waitForDatabaseUpdate(students, 0, strictlyEqualToExpected: true);

  // There is supposed to have one remaining admin (the dev one)
  final hasSuperAdmin = admins.any(
    (admin) => admin.accessLevel == AccessLevel.superAdmin,
  );
  admins.clear(confirm: true);
  await _waitForDatabaseUpdate(
    admins,
    hasSuperAdmin ? 1 : 0,
    strictlyEqualToExpected: true,
  );

  teachers.clear(confirm: true);
  await _waitForDatabaseUpdate(teachers, 0, strictlyEqualToExpected: true);

  schoolBoards.clear(confirm: true);
  await _waitForDatabaseUpdate(schoolBoards, 0, strictlyEqualToExpected: true);
}

Future<void> _addDummySchoolBoards(SchoolBoardsProvider schoolBoards) async {
  dev.log('Adding dummy schools');

  // Test the add function
  final schools = [
    School(
      name: 'Ma première école',
      address: Address(
        civicNumber: 9105,
        street: 'Rue Verville',
        city: 'Montréal',
        postalCode: 'H2N 1Y5',
      ),
      phone: PhoneNumber.fromString('555 123 4567'),
    ),
    School(
      name: _mySchoolName,
      address: Address(
        civicNumber: 9105,
        street: 'Rue Verville',
        city: 'Montréal',
        postalCode: 'H2N 1Y5',
      ),
      phone: PhoneNumber.fromString('555 123 7654'),
    ),
  ];
  schoolBoards.add(
    SchoolBoard(
      name: _mySchoolBoardName,
      logo: null,
      schools: schools.toList(),
      cnesstNumber: '1234567890',
    ),
  );

  schools.clear();
  schools.add(
    School(
      name: 'École de la Montagne',
      address: Address(
        civicNumber: 1234,
        street: 'Rue de la Montagne',
        city: 'Montréal',
        postalCode: 'H3G 1Z2',
      ),
      phone: PhoneNumber.fromString('555 987 6543'),
    ),
  );
  schools.add(
    School(
      name: 'École du Parc',
      address: Address(
        civicNumber: 5678,
        street: 'Avenue du Parc',
        city: 'Montréal',
        postalCode: 'H2V 4W5',
      ),
      phone: PhoneNumber.fromString('555 456 7890'),
    ),
  );
  schools.add(
    School(
      id: 'dummy_school_id_1_of_2',
      name: 'École des Arts',
      address: Address(
        civicNumber: 9101,
        street: 'Boulevard des Arts',
        city: 'Montréal',
        postalCode: 'H2X 3Y7',
      ),
      phone: PhoneNumber.fromString('555 321 4321'),
    ),
  );
  schoolBoards.add(
    SchoolBoard(
      id: 'dummy_school_board_id_2',
      name: 'Centre de services scolaire de l\'Île-de-Montréal',
      logo: null,
      schools: schools.toList(),
      cnesstNumber: '0987654321',
    ),
  );

  await _waitForDatabaseUpdate(schoolBoards, 2);
}

Future<void> _addDummyAdmins(
  AdminsProvider admins, {
  required SchoolBoardsProvider schoolBoards,
}) async {
  dev.log('Adding dummy admins');

  final mySchoolBoardId =
      schoolBoards
          .firstWhere((schoolBoard) => schoolBoard.name == _mySchoolBoardName)
          .id;

  admins.add(
    Admin(
      firstName: 'Jean',
      middleName: null,
      lastName: 'Dupont',
      schoolBoardId: mySchoolBoardId,
      hasRegisteredAccount: false,
      email: _adminEmail,
      accessLevel: AccessLevel.admin,
    ),
  );
  admins.add(
    Admin(
      firstName: 'Marie',
      middleName: null,
      lastName: 'Lefebvre',
      schoolBoardId: 'dummy_school_board_id_2',
      hasRegisteredAccount: false,
      email: 'marie.lefebvre@monecole.qc',
      accessLevel: AccessLevel.admin,
    ),
  );

  await _waitForDatabaseUpdate(admins, 2);
}

Future<void> _addDummyTeachers(
  TeachersProvider teachers, {
  required SchoolBoardsProvider schoolBoards,
}) async {
  dev.log('Adding dummy teachers');

  final mySchoolBoard = schoolBoards.firstWhere(
    (schoolBoard) => schoolBoard.name == _mySchoolBoardName,
  );
  final mySchoolBoardId = mySchoolBoard.id;
  final mySchoolId =
      mySchoolBoard.schools
          .firstWhere((school) => school.name == _mySchoolName)
          .id;

  teachers.add(
    Teacher.empty.copyWith(
      firstName: 'Roméo',
      lastName: 'Montaigu',
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      groups: ['550', '551'],
      email: 'romeo.montaigu@shakespeare.qc',
    ),
  );

  teachers.add(
    Teacher.empty.copyWith(
      firstName: 'Juliette',
      lastName: 'Capulet',
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      groups: ['550', '551'],
      email: _myEmail,
    ),
  );

  teachers.add(
    Teacher.empty.copyWith(
      id: 'dummy_teacher_id_1',
      firstName: 'Tybalt',
      lastName: 'Capulet',
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      groups: ['550', '551'],
      email: 'tybalt.capulet@shakespeare.qc',
    ),
  );

  teachers.add(
    Teacher.empty.copyWith(
      id: 'dummy_teacher_id_2',
      firstName: 'Benvolio',
      lastName: 'Montaigu',
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      groups: ['552'],
      email: 'benvolio.montaigu@shakespeare.qc',
    ),
  );
  await _waitForDatabaseUpdate(teachers, 1);
}

Future<void> _addDummyStudents(
  StudentsProvider students, {
  required SchoolBoardsProvider schoolBoards,
}) async {
  dev.log('Adding dummy students');

  final mySchoolBoard = schoolBoards.firstWhere(
    (schoolBoard) => schoolBoard.name == _mySchoolBoardName,
  );
  final mySchoolBoardId = mySchoolBoard.id;
  final mySchoolId =
      mySchoolBoard.schools
          .firstWhere((school) => school.name == _mySchoolName)
          .id;

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Cedric',
      lastName: 'Masson',
      dateBirth: DateTime(2005, 5, 20),
      email: 'c.masson@email.com',
      program: Program.fpt,
      group: '550',
      address: Address(
        civicNumber: 7248,
        street: 'Rue D\'Iberville',
        city: 'Montréal',
        postalCode: 'H2E 2Y6',
      ),
      phone: PhoneNumber.fromString('514 321 8888'),
      contact: Person(
        firstName: 'Paul',
        middleName: null,
        lastName: 'Masson',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
        email: 'p.masson@email.com',
      ),
      contactLink: 'Père',
    ),
  );

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Thomas',
      lastName: 'Caron',
      dateBirth: null,
      email: 't.caron@email.com',
      program: Program.fpt,
      group: '550',
      contact: Person(
        firstName: 'Jean-Pierre',
        middleName: null,
        lastName: 'Caron Mathieu',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
        email: 'j.caron@email.com',
      ),
      contactLink: 'Père',
      address: Address(
        civicNumber: 202,
        street: 'Boulevard Saint-Joseph Est',
        city: 'Montréal',
        postalCode: 'H1X 2T2',
      ),
      phone: PhoneNumber.fromString('514 222 3344'),
    ),
  );

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Mikael',
      lastName: 'Boucher',
      dateBirth: null,
      email: 'm.boucher@email.com',
      program: Program.fpt,
      group: '550',
      contact: Person(
        firstName: 'Nicole',
        middleName: null,
        lastName: 'Lefranc',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
        email: 'n.lefranc@email.com',
      ),
      contactLink: 'Mère',
      address: Address(
        civicNumber: 6723,
        street: '25e Ave',
        city: 'Montréal',
        postalCode: 'H1T 3M1',
      ),
      phone: PhoneNumber.fromString('514 333 4455'),
    ),
  );

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Kevin',
      lastName: 'Leblanc',
      dateBirth: null,
      email: 'k.leblanc@email.com',
      program: Program.fpt,
      group: '550',
      contact: Person(
        firstName: 'Martine',
        middleName: null,
        lastName: 'Gagnon',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
        email: 'm.gagnon@email.com',
      ),
      contactLink: 'Mère',
      address: Address(
        civicNumber: 9277,
        street: 'Rue Meunier',
        city: 'Montréal',
        postalCode: 'H2N 1W4',
      ),
      phone: PhoneNumber.fromString('514 999 8877'),
    ),
  );

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Simon',
      lastName: 'Gingras',
      dateBirth: null,
      email: 's.gingras@email.com',
      program: Program.fms,
      group: '552',
      contact: Person(
        firstName: 'Raoul',
        middleName: null,
        lastName: 'Gingras',
        email: 'r.gingras@email.com',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
      ),
      contactLink: 'Père',
      address: Address(
        civicNumber: 4517,
        street: 'Rue d\'Assise',
        city: 'Saint-Léonard',
        postalCode: 'H1R 1W2',
      ),
      phone: PhoneNumber.fromString('514 888 7766'),
    ),
  );

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Diego',
      lastName: 'Vargas',
      dateBirth: null,
      email: 'd.vargas@email.com',
      program: Program.fpt,
      group: '550',
      contact: Person(
        firstName: 'Laura',
        middleName: null,
        lastName: 'Vargas',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
        email: 'l.vargas@email.com',
      ),
      contactLink: 'Mère',
      address: Address(
        civicNumber: 8204,
        street: 'Rue de Blois',
        city: 'Saint-Léonard',
        postalCode: 'H1R 2X1',
      ),
      phone: PhoneNumber.fromString('514 444 5566'),
    ),
  );

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Jeanne',
      lastName: 'Tremblay',
      dateBirth: null,
      email: 'g.tremblay@email.com',
      program: Program.fpt,
      group: '550',
      contact: Person(
        firstName: 'Vincent',
        middleName: null,
        lastName: 'Tremblay',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
        email: 'v.tremblay@email.com',
      ),
      contactLink: 'Père',
      address: Address(
        civicNumber: 8358,
        street: 'Rue Jean-Nicolet',
        city: 'Saint-Léonard',
        postalCode: 'H1R 2R2',
      ),
      phone: PhoneNumber.fromString('514 555 9988'),
    ),
  );

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Vincent',
      lastName: 'Picard',
      dateBirth: null,
      email: 'v.picard@email.com',
      program: Program.fms,
      group: '550',
      contact: Person(
        firstName: 'Jean-François',
        middleName: null,
        lastName: 'Picard',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
        email: 'jp.picard@email.com',
      ),
      contactLink: 'Père',
      address: Address(
        civicNumber: 8382,
        street: 'Rue du Laus',
        city: 'Saint-Léonard',
        postalCode: 'H1R 2P4',
      ),
      phone: PhoneNumber.fromString('514 778 8899'),
    ),
  );

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Vanessa',
      lastName: 'Monette',
      dateBirth: null,
      email: 'v.monette@email.com',
      program: Program.fms,
      group: '551',
      contact: Person(
        firstName: 'Stéphane',
        middleName: null,
        lastName: 'Monette',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
        email: 's.monette@email.com',
      ),
      contactLink: 'Père',
      address: Address(
        civicNumber: 6865,
        street: 'Rue Chaillot',
        city: 'Saint-Léonard',
        postalCode: 'H1T 3R5',
      ),
      phone: PhoneNumber.fromString('514 321 6655'),
    ),
  );

  students.add(
    Student(
      schoolBoardId: mySchoolBoardId,
      schoolId: mySchoolId,
      firstName: 'Melissa',
      lastName: 'Poulain',
      dateBirth: null,
      email: 'm.poulain@email.com',
      program: Program.fms,
      group: '550',
      contact: Person(
        firstName: 'Mathieu',
        middleName: null,
        lastName: 'Poulain',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 321 9876'),
        address: null,
        email: 'm.poulain@email.com',
      ),
      contactLink: 'Père',
      address: Address(
        civicNumber: 6585,
        street: 'Rue Lemay',
        city: 'Montréal',
        postalCode: 'H1T 2L8',
      ),
      phone: PhoneNumber.fromString('514 567 9999'),
    ),
  );

  await _waitForDatabaseUpdate(students, 10);
}

Future<void> _addDummyEnterprises(
  EnterprisesProvider enterprises, {
  required SchoolBoardsProvider schoolBoards,
  required TeachersProvider teachers,
}) async {
  dev.log('Adding dummy enterprises');

  final mySchoolBoard = schoolBoards.firstWhere(
    (schoolBoard) => schoolBoard.name == _mySchoolBoardName,
  );
  final mySchoolBoardId = mySchoolBoard.id;
  final mySchoolId =
      mySchoolBoard.schools
          .firstWhere((school) => school.name == _mySchoolName)
          .id;
  final otherSchoolId =
      mySchoolBoard.schools
          .firstWhere((school) => school.name != _mySchoolName)
          .id;

  final myTeacherId =
      teachers.firstWhere((teacher) => teacher.email == _myEmail).id;
  final myPartnerTeacherId =
      teachers.firstWhere((teacher) => teacher.email == _myParternerEmail).id;

  JobList jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[2].specializations[9],
      positionsOffered: {mySchoolId: 2, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation.empty,
      incidents: Incidents(
        severeInjuries: [Incident('Vaut mieux ne pas détailler...')],
      ),
      minimumAge: 12,
      preInternshipRequests: PreInternshipRequests.fromStrings([
        'Manger de la poutine',
        PreInternshipRequestTypes.soloInterview.index.toString(),
      ]),
      uniforms: Uniforms(
        status: UniformStatus.suppliedByEnterprise,
        uniforms: ['Un beau chapeu bleu'],
      ),
      protections: Protections(
        status: ProtectionsStatus.suppliedByEnterprise,
        protections: [
          'Une veste de mithril',
          'Une cotte de maille',
          'Une drole de bague',
        ],
      ),
      reservedForId: '',
    ),
  );
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[0].specializations[7],
      positionsOffered: {mySchoolId: 3, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation.empty,
      incidents: Incidents(
        minorInjuries: [
          Incident('Juste un petit couteau de 5cm dans la main'),
          Incident('Une deuxième fois, mais seulement 5 points de suture'),
        ],
      ),
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([
        'Manger de la tarte',
      ]),
      uniforms: Uniforms(
        status: UniformStatus.suppliedByEnterprise,
        uniforms: ['Deux dents en or'],
      ),
      protections: Protections(
        status: ProtectionsStatus.suppliedByEnterprise,
        protections: [
          'Une veste de mithril',
          'Une cotte de maille',
          'Une drole de bague',
        ],
      ),
      reservedForId: '',
    ),
  );

  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Metro Gagnon',
      status: EnterpriseStatus.active,
      activityTypes: {
        ActivityTypes.boucherie,
        ActivityTypes.commerce,
        ActivityTypes.epicerie,
      },
      recruiterId: myPartnerTeacherId,
      jobs: jobs,
      contact: Person(
        firstName: 'Marc',
        middleName: null,
        lastName: 'Arcand',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 999 6655'),
        address: null,
        email: 'm.arcand@email.com',
      ),
      contactFunction: 'Directeur',
      address: Address(
        civicNumber: 1853,
        street: 'Chemin Rockland',
        city: 'Mont-Royal',
        postalCode: 'H3P 2Y7',
      ),
      phone: PhoneNumber.fromString('514 999 6655'),
      fax: PhoneNumber.fromString('514 999 6600'),
      website: 'fausse.ca',
      headquartersAddress: Address(
        civicNumber: 1853,
        street: 'Chemin Rockland',
        city: 'Mont-Royal',
        postalCode: 'H3P 2Y7',
      ),
      neq: '4567900954',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[0].specializations[7],
      positionsOffered: {mySchoolId: 3, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation.empty,
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId: myPartnerTeacherId,
    ),
  );
  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Jean Coutu',
      status: EnterpriseStatus.active,
      activityTypes: {ActivityTypes.commerce, ActivityTypes.pharmacie},
      recruiterId: myTeacherId,
      jobs: jobs,
      contact: Person(
        firstName: 'Caroline',
        middleName: null,
        lastName: 'Mercier',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 123 4567 poste 123'),
        address: null,
        email: 'c.mercier@email.com',
      ),
      contactFunction: 'Assistante-gérante',
      address: Address(
        civicNumber: 1665,
        street: 'Poncet',
        city: 'Montréal',
        postalCode: 'H3M 1T8',
      ),
      phone: PhoneNumber.fromString('514 123 4567'),
      fax: PhoneNumber.fromString('514 123 4560'),
      website: 'example.com',
      headquartersAddress: Address(
        civicNumber: 1665,
        street: 'Poncet',
        city: 'Montréal',
        postalCode: 'H3M 1T8',
      ),
      neq: '1234567891',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[9].specializations[3],
      positionsOffered: {mySchoolId: 3, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation(
        questions: {
          'Q1': ['Oui'],
          'Q1+t': ['Peu souvent, à la discrétion des employés.'],
          'Q3': ['Un diable'],
          'Q5': ['Des ciseaux'],
          'Q9': ['Des solvants', 'Des produits de nettoyage'],
          'Q12': ['Bruyant'],
          'Q12+t': ['Bouchons a oreilles'],
          'Q15': ['Oui'],
          'Q18': ['Non'],
        },
        date: DateTime.now(),
      ),
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([
        PreInternshipRequestTypes.soloInterview.toString(),
        'Faire le ménage',
      ]),
      uniforms: Uniforms(
        status: UniformStatus.suppliedByEnterprise,
        uniforms: ['Un beau chapeau bleu'],
      ),
      protections: Protections(
        status: ProtectionsStatus.suppliedBySchool,
        protections: ['Masque', 'Un masque de protection'],
      ),
      reservedForId: myTeacherId,
    ),
  );

  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Auto Care',
      status: EnterpriseStatus.active,
      activityTypes: {ActivityTypes.garage},
      recruiterId: myPartnerTeacherId,
      jobs: jobs,
      contact: Person(
        firstName: 'Denis',
        middleName: null,
        lastName: 'Rondeau',
        dateBirth: null,
        phone: PhoneNumber.fromString('438 987 6543'),
        address: null,
        email: 'd.rondeau@email.com',
      ),
      contactFunction: 'Propriétaire',
      address: Address(
        civicNumber: 8490,
        street: 'Rue Saint-Dominique',
        city: 'Montréal',
        postalCode: 'H2P 2L5',
      ),
      phone: PhoneNumber.fromString('438 987 6543'),
      website: '',
      headquartersAddress: Address(
        civicNumber: 8490,
        street: 'Rue Saint-Dominique',
        city: 'Montréal',
        postalCode: 'H2P 2L5',
      ),
      neq: '5679011975',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[9].specializations[3],
      positionsOffered: {mySchoolId: 2, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation.empty,
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId: mySchoolId,
    ),
  );
  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Auto Repair',
      status: EnterpriseStatus.active,
      activityTypes: {ActivityTypes.garage, ActivityTypes.mecanique},
      recruiterId: 'dummy_teacher_id_1',
      jobs: jobs,
      contact: Person(
        firstName: 'Claudio',
        middleName: null,
        lastName: 'Brodeur',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 235 6789'),
        address: null,
        email: 'c.brodeur@email.com',
      ),
      contactFunction: 'Propriétaire',
      address: Address(
        civicNumber: 10142,
        street: 'Boul. Saint-Laurent',
        city: 'Montréal',
        postalCode: 'H3L 2N7',
      ),
      phone: PhoneNumber.fromString('514 235 6789'),
      fax: PhoneNumber.fromString('514 321 9870'),
      website: 'fausse.ca',
      headquartersAddress: Address(
        civicNumber: 10142,
        street: 'Boul. Saint-Laurent',
        city: 'Montréal',
        postalCode: 'H3L 2N7',
      ),
      neq: '2345678912',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[2].specializations[9],
      positionsOffered: {mySchoolId: 2, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation.empty,
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId:
          mySchoolBoard.schools.firstWhere((e) => e.id != mySchoolId).id,
    ),
  );

  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Boucherie Marien',
      status: EnterpriseStatus.active,
      activityTypes: {ActivityTypes.boucherie, ActivityTypes.commerce},
      recruiterId: myPartnerTeacherId,
      jobs: jobs,
      contact: Person(
        firstName: 'Brigitte',
        middleName: null,
        lastName: 'Samson',
        dateBirth: null,
        phone: PhoneNumber.fromString('438 888 2222'),
        address: null,
        email: 'b.samson@email.com',
      ),
      contactFunction: 'Gérante',
      address: Address(
        civicNumber: 8921,
        street: 'Rue Lajeunesse',
        city: 'Montréal',
        postalCode: 'H2M 1S1',
      ),
      phone: PhoneNumber.fromString('514 321 9876'),
      fax: PhoneNumber.fromString('514 321 9870'),
      website: 'fausse.ca',
      headquartersAddress: Address(
        civicNumber: 8921,
        street: 'Rue Lajeunesse',
        city: 'Montréal',
        postalCode: 'H2M 1S1',
      ),
      neq: '1234567080',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[2].specializations[7],
      positionsOffered: {mySchoolId: 1, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation.empty,
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId: '',
    ),
  );

  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'IGA',
      status: EnterpriseStatus.active,
      activityTypes: {ActivityTypes.epicerie, ActivityTypes.supermarche},
      recruiterId: myPartnerTeacherId,
      jobs: jobs,
      contact: Person(
        firstName: 'Gabrielle',
        middleName: null,
        lastName: 'Fortin',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 111 2222'),
        address: null,
        email: 'g.fortin@email.com',
      ),
      contactFunction: 'Gérante',
      address: Address(
        civicNumber: 1415,
        street: 'Rue Jarry Est',
        city: 'Montréal',
        postalCode: 'H2E 1A7',
      ),
      phone: PhoneNumber.fromString('514 111 2222'),
      fax: PhoneNumber.fromString('514 111 2200'),
      website: 'fausse.ca',
      headquartersAddress: Address(
        civicNumber: 7885,
        street: 'Rue Lajeunesse',
        city: 'Montréal',
        postalCode: 'H2M 1S1',
      ),
      neq: '1234560522',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[0].specializations[7],
      positionsOffered: {mySchoolId: 2, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation.empty,
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId: '',
    ),
  );

  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Pharmaprix',
      status: EnterpriseStatus.noLongerAcceptingInternships,
      activityTypes: {ActivityTypes.commerce, ActivityTypes.pharmacie},
      recruiterId: 'dummy_teacher_id_2',
      jobs: jobs,
      contact: Person(
        firstName: 'Jessica',
        middleName: null,
        lastName: 'Marcotte',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 111 2222'),
        address: null,
        email: 'g.fortin@email.com',
      ),
      contactFunction: 'Pharmacienne',
      address: Address(
        civicNumber: 3611,
        street: 'Rue Jarry Est',
        city: 'Montréal',
        postalCode: 'H1Z 2G1',
      ),
      phone: PhoneNumber.fromString('514 654 5444'),
      fax: PhoneNumber.fromString('514 654 5445'),
      website: 'fausse.ca',
      headquartersAddress: Address(
        civicNumber: 3611,
        street: 'Rue Jarry Est',
        city: 'Montréal',
        postalCode: 'H1Z 2G1',
      ),
      neq: '3456789933',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[2].specializations[14],
      positionsOffered: {mySchoolId: 1, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation.empty,
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId: '',
    ),
  );

  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Subway',
      status: EnterpriseStatus.active,
      activityTypes: {
        ActivityTypes.restaurationRapide,
        ActivityTypes.sandwicherie,
      },
      recruiterId: 'dummy_teacher_id_2',
      jobs: jobs,
      contact: Person(
        firstName: 'Carlos',
        middleName: null,
        lastName: 'Rodriguez',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 555 3333'),
        address: null,
        email: 'c.rodriguez@email.com',
      ),
      contactFunction: 'Gérant',
      address: Address(
        civicNumber: 775,
        street: 'Rue Chabanel O',
        city: 'Montréal',
        postalCode: 'H4N 3J7',
      ),
      phone: PhoneNumber.fromString('514 555 7891'),
      website: 'fausse.ca',
      headquartersAddress: null,
      neq: '6790122996',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[0].specializations[7],
      positionsOffered: {mySchoolId: 3, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation.empty,
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId: '',
    ),
  );

  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Walmart',
      status: EnterpriseStatus.bannedFromAcceptingInternships,
      activityTypes: {
        ActivityTypes.commerce,
        ActivityTypes.magasin,
        ActivityTypes.supermarche,
      },
      recruiterId: myPartnerTeacherId,
      jobs: jobs,
      contact: Person(
        firstName: 'France',
        middleName: null,
        lastName: 'Boissonneau',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 879 8654 poste 1112'),
        address: null,
        email: 'f.boissonneau@email.com',
      ),
      contactFunction: 'Directrice des Ressources Humaines',
      address: Address(
        civicNumber: 10345,
        street: 'Ave Christophe-Colomb',
        city: 'Montréal',
        postalCode: 'H2C 2V1',
      ),
      phone: PhoneNumber.fromString('514 879 8654'),
      fax: PhoneNumber.fromString('514 879 8000'),
      website: 'fausse.ca',
      headquartersAddress: Address(
        civicNumber: 10345,
        street: 'Ave Christophe-Colomb',
        city: 'Montréal',
        postalCode: 'H2C 2V1',
      ),
      neq: '9012345038',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[1].specializations[2],
      positionsOffered: {mySchoolId: 1, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation(
        questions: {
          'Q1': ['Oui'],
          'Q1+t': ['Plusieurs fois par jour, surtout des pots de fleurs.'],
          'Q3': ['Un diable'],
          'Q5': ['Un couteau', 'Des ciseaux', 'Un sécateur'],
          'Q7': ['Des pesticides', 'Engrais'],
          'Q12': ['Bruyant'],
          'Q15': ['Non'],
          'Q18': ['Oui'],
          'Q18+t': [
            'L\'élève ne portait pas ses gants malgré plusieurs avertissements, '
                'et il s\'est ouvert profondément la paume en voulant couper une tige.',
          ],
        },
      ),
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId: '',
    ),
  );
  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Le jardin de Joanie',
      status: EnterpriseStatus.active,
      activityTypes: {ActivityTypes.commerce, ActivityTypes.fleuriste},
      recruiterId: myPartnerTeacherId,
      jobs: jobs,
      contact: Person(
        firstName: 'Joanie',
        middleName: null,
        lastName: 'Lemieux',
        dateBirth: null,
        phone: PhoneNumber.fromString('438 789 6543'),
        address: null,
        email: 'j.lemieux@email.com',
      ),
      contactFunction: 'Propriétaire',
      address: Address(
        civicNumber: 8629,
        street: 'Rue de Gaspé',
        city: 'Montréal',
        postalCode: 'H2P 2K3',
      ),
      phone: PhoneNumber.fromString('438 789 6543'),
      website: '',
      headquartersAddress: Address(
        civicNumber: 8629,
        street: 'Rue de Gaspé',
        city: 'Montréal',
        postalCode: 'H2P 2K3',
      ),
      neq: '5679011966',
    ),
  );

  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[1].specializations[2],
      positionsOffered: {mySchoolId: 1, otherSchoolId: 5},
      sstEvaluation: JobSstEvaluation(
        questions: {
          'Q1': ['Oui'],
          'Q1+t': [
            'En début et en fin de journée, surtout des pots de fleurs.',
          ],
          'Q3': ['Un diable'],
          'Q5': ['Un couteau', 'Des ciseaux'],
          'Q7': ['Des pesticides', 'Engrais'],
          'Q12': ['__NOT_APPLICABLE_INTERNAL__'],
          'Q15': ['Oui'],
          'Q15+t': ['Mais pourquoi donc??'],
          'Q16': ['Beurk'],
          'Q18': ['Non'],
        },
      ),
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId: '',
    ),
  );
  enterprises.add(
    Enterprise(
      schoolBoardId: mySchoolBoardId,
      name: 'Fleuriste Joli',
      status: EnterpriseStatus.active,
      activityTypes: {ActivityTypes.fleuriste, ActivityTypes.magasin},
      recruiterId: myPartnerTeacherId,
      jobs: jobs,
      contact: Person(
        firstName: 'Gaëtan',
        middleName: null,
        lastName: 'Munger',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 987 6543'),
        address: null,
        email: 'g.munger@email.com',
      ),
      contactFunction: 'Gérant',
      address: Address(
        civicNumber: 70,
        street: 'Rue Chabanel Ouest',
        city: 'Montréal',
        postalCode: 'H2N 1E7',
      ),
      phone: PhoneNumber.fromString('514 987 6543'),
      website: '',
      headquartersAddress: Address(
        civicNumber: 70,
        street: 'Rue Chabanel Ouest',
        city: 'Montréal',
        postalCode: 'H2N 1E7',
      ),
      neq: '5679055590',
    ),
  );

  final randomSchoolId =
      schoolBoards
          .firstWhere((schoolBoard) => schoolBoard.name != _mySchoolBoardName)
          .schools
          .firstWhere((school) => school.name != 'dummy_school_id_1_of_2')
          .id;
  jobs = JobList();
  jobs.add(
    Job(
      specialization:
          ActivitySectorsService.activitySectors[1].specializations[2],
      positionsOffered: {'dummy_school_id_1_of_2': 3, randomSchoolId: 5},
      sstEvaluation: JobSstEvaluation(
        questions: {
          'Q1': ['Oui'],
          'Q1+t': [
            'En début et en fin de journée, surtout des pots de fleurs.',
          ],
          'Q3': ['Un diable'],
          'Q5': ['Un couteau', 'Des ciseaux'],
          'Q7': ['Des pesticides', 'Engrais'],
          'Q12': ['__NOT_APPLICABLE_INTERNAL__'],
          'Q15': ['Oui'],
          'Q15+t': ['Mais pourquoi donc??'],
          'Q16': ['Beurk'],
          'Q18': ['Non'],
        },
      ),
      incidents: Incidents.empty,
      minimumAge: 15,
      preInternshipRequests: PreInternshipRequests.fromStrings([]),
      uniforms: Uniforms(status: UniformStatus.none),
      protections: Protections(status: ProtectionsStatus.none),
      reservedForId: '',
    ),
  );
  enterprises.add(
    Enterprise(
      schoolBoardId: 'dummy_school_board_id_2',
      name: 'Fleuriste Pasjoli',
      status: EnterpriseStatus.active,
      activityTypes: {ActivityTypes.fleuriste, ActivityTypes.magasin},
      recruiterId: myPartnerTeacherId,
      jobs: jobs,
      contact: Person(
        firstName: 'Gaëtan',
        middleName: null,
        lastName: 'Munger',
        dateBirth: null,
        phone: PhoneNumber.fromString('514 987 6543'),
        address: null,
        email: 'g.munger@email.com',
      ),
      contactFunction: 'Gérant',
      address: Address(
        civicNumber: 70,
        street: 'Rue Chabanel Ouest',
        city: 'Montréal',
        postalCode: 'H2N 1E7',
      ),
      phone: PhoneNumber.fromString('514 987 6543'),
      website: '',
      headquartersAddress: Address(
        civicNumber: 70,
        street: 'Rue Chabanel Ouest',
        city: 'Montréal',
        postalCode: 'H2N 1E7',
      ),
      neq: '5679055590',
    ),
  );

  // There are 12, but one is for another school board
  await _waitForDatabaseUpdate(enterprises, 11);
}

Future<void> _addDummyInternships(
  InternshipsProvider internships, {
  required SchoolBoardsProvider schoolBoards,
  required TeachersProvider teachers,
  required StudentsProvider students,
  required EnterprisesProvider enterprises,
}) async {
  dev.log('Adding dummy internships');

  final mySchoolBoard = schoolBoards.firstWhere(
    (schoolBoard) => schoolBoard.name == _mySchoolBoardName,
  );
  final mySchoolBoardId = mySchoolBoard.id;

  final myTeacherId =
      teachers.firstWhere((teacher) => teacher.email == _myEmail).id;
  final myPartnerTeacherId =
      teachers.firstWhere((teacher) => teacher.email == _myParternerEmail).id;

  final rng = Random();

  var period = time_utils.DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(Duration(days: rng.nextInt(90))),
  );
  internships.add(
    Internship(
      schoolBoardId: mySchoolBoardId,
      creationDate: DateTime.now(),
      studentId: students.firstWhere((e) => e.fullName == 'Cedric Masson').id,
      signatoryTeacherId: myTeacherId,
      extraSupervisingTeacherIds: [],
      enterpriseId: enterprises.firstWhere((e) => e.name == 'Auto Care').id,
      jobId: enterprises.firstWhere((e) => e.name == 'Auto Care').jobs[0].id,
      extraSpecializationIds: [
        ActivitySectorsService.activitySectors[2].specializations[1].id,
        ActivitySectorsService.activitySectors[1].specializations[0].id,
      ],
      supervisor: Person(
        firstName: 'Nobody',
        middleName: null,
        lastName: 'Forever',
        dateBirth: null,
        phone: PhoneNumber.fromString('514-555-1234'),
        address: null,
        email: '',
      ),
      dates: period,
      expectedDuration: 135,
      achievedDuration: -1,
      endDate: DateTime(0),
      teacherNotes: 'Un stage de rêve, mais pas pour l\'élève.',
      weeklySchedules: [
        WeeklySchedule(
          schedule: {
            Day.monday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.tuesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.wednesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.thursday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.friday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
          },
          period: period,
        ),
      ],
      transportations: [Transportation.yes, Transportation.pass],
      visitFrequencies: 'Une visite par semaine',
    ),
  );

  var startingPeriod = DateTime.now().subtract(
    Duration(days: rng.nextInt(50) + 60),
  );
  period = time_utils.DateTimeRange(
    start: startingPeriod,
    end: startingPeriod.add(Duration(days: rng.nextInt(50))),
  );
  internships.add(
    Internship(
      schoolBoardId: mySchoolBoardId,
      creationDate: DateTime.now(),
      studentId: students.firstWhere((e) => e.fullName == 'Thomas Caron').id,
      signatoryTeacherId: myTeacherId,
      extraSupervisingTeacherIds: [],
      enterpriseId:
          enterprises.firstWhere((e) => e.name == 'Boucherie Marien').id,
      jobId:
          enterprises
              .firstWhere((e) => e.name == 'Boucherie Marien')
              .jobs[0]
              .id,
      extraSpecializationIds: [],
      supervisor: Person(
        firstName: 'Nobody',
        middleName: null,
        lastName: 'Forever',
        dateBirth: null,
        phone: null,
        address: null,
        email: '',
      ),
      dates: period,
      expectedDuration: 135,
      achievedDuration: -1,
      endDate: DateTime(0),
      weeklySchedules: [
        WeeklySchedule(
          schedule: {
            Day.monday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.tuesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.wednesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.thursday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.friday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
          },
          period: period,
        ),
      ],
      transportations: [Transportation.pass],
      visitFrequencies: 'Une visite par semaine',
    ),
  );

  period = time_utils.DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(Duration(days: rng.nextInt(90))),
  );
  var internship = Internship(
    schoolBoardId: mySchoolBoardId,
    creationDate: DateTime.now(),
    studentId: students.firstWhere((e) => e.fullName == 'Melissa Poulain').id,
    signatoryTeacherId: myTeacherId,
    extraSupervisingTeacherIds: [],
    enterpriseId: enterprises.firstWhere((e) => e.name == 'Subway').id,
    jobId: enterprises.firstWhere((e) => e.name == 'Subway').jobs[0].id,
    extraSpecializationIds: [],
    supervisor: Person(
      firstName: 'Nobody',
      middleName: null,
      lastName: 'Forever',
      dateBirth: null,
      phone: null,
      address: null,
      email: '',
    ),
    dates: period,
    endDate: DateTime.now().add(const Duration(days: 10)),
    expectedDuration: 135,
    achievedDuration: 125,
    weeklySchedules: [
      WeeklySchedule(
        schedule: {
          Day.monday: DailySchedule(
            blocks: [
              TimeBlock(
                start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                end: const time_utils.TimeOfDay(hour: 12, minute: 00),
              ),
              TimeBlock(
                start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                end: const time_utils.TimeOfDay(hour: 15, minute: 00),
              ),
            ],
          ),
          Day.tuesday: DailySchedule(
            blocks: [
              TimeBlock(
                start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                end: const time_utils.TimeOfDay(hour: 12, minute: 00),
              ),
              TimeBlock(
                start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                end: const time_utils.TimeOfDay(hour: 15, minute: 00),
              ),
            ],
          ),
          Day.wednesday: DailySchedule(
            blocks: [
              TimeBlock(
                start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                end: const time_utils.TimeOfDay(hour: 12, minute: 00),
              ),
              TimeBlock(
                start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                end: const time_utils.TimeOfDay(hour: 15, minute: 00),
              ),
            ],
          ),
          Day.thursday: DailySchedule(
            blocks: [
              TimeBlock(
                start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                end: const time_utils.TimeOfDay(hour: 12, minute: 00),
              ),
              TimeBlock(
                start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                end: const time_utils.TimeOfDay(hour: 15, minute: 00),
              ),
            ],
          ),
        },
        period: period,
      ),
    ],
    transportations: [Transportation.none],
    visitFrequencies: 'Une visite par mois',
  );
  internship.enterpriseEvaluation = PostInternshipEnterpriseEvaluation(
    internshipId: internship.id,
    skillsRequired: ['Communiquer à l\'écrit', 'Interagir avec des clients'],
    taskVariety: 0,
    trainingPlanRespect: 1,
    autonomyExpected: 4,
    efficiencyExpected: 2,
    supervisionStyle: 1,
    easeOfCommunication: 5,
    absenceAcceptance: 4,
    supervisionComments: 'Milieu peu aidant, mais ouvert',
    acceptanceTsa: -1,
    acceptanceLanguageDisorder: 4,
    acceptanceIntellectualDisability: 4,
    acceptancePhysicalDisability: 4,
    acceptanceMentalHealthDisorder: 2,
    acceptanceBehaviorDifficulties: 2,
  );
  internships.add(internship);

  period = time_utils.DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(Duration(days: rng.nextInt(90))),
  );
  internships.add(
    Internship(
      schoolBoardId: mySchoolBoardId,
      creationDate: DateTime.now(),
      studentId: students.firstWhere((e) => e.fullName == 'Vincent Picard').id,
      signatoryTeacherId: myTeacherId,
      extraSupervisingTeacherIds: [],
      enterpriseId: enterprises.firstWhere((e) => e.name == 'IGA').id,
      jobId: enterprises.firstWhere((e) => e.name == 'IGA').jobs[0].id,
      extraSpecializationIds: [],
      supervisor: Person(
        firstName: 'Nobody',
        middleName: null,
        lastName: 'Forever',
        dateBirth: null,
        phone: null,
        address: null,
        email: '',
      ),
      dates: period,
      expectedDuration: 135,
      achievedDuration: -1,
      endDate: DateTime(0),
      weeklySchedules: [
        WeeklySchedule(
          schedule: {
            Day.monday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.tuesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.wednesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
          },
          period: period,
        ),
      ],
      transportations: [Transportation.yes],
      visitFrequencies: 'Une visite par semaine',
    ),
  );

  period = time_utils.DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(Duration(days: rng.nextInt(90))),
  );
  internships.add(
    Internship(
      schoolBoardId: mySchoolBoardId,
      creationDate: DateTime.now(),
      studentId: students.firstWhere((e) => e.fullName == 'Simon Gingras').id,
      // This is a Roméo Montaigu's student
      signatoryTeacherId: myPartnerTeacherId,
      extraSupervisingTeacherIds: [],
      enterpriseId: enterprises.firstWhere((e) => e.name == 'Auto Repair').id,
      jobId: enterprises.firstWhere((e) => e.name == 'Auto Repair').jobs[0].id,
      extraSpecializationIds: [],
      supervisor: Person(
        firstName: 'Nobody',
        middleName: null,
        lastName: 'Forever',
        dateBirth: null,
        phone: null,
        address: null,
        email: '',
      ),
      dates: period,
      endDate: DateTime.now().add(const Duration(days: 10)),
      expectedDuration: 135,
      achievedDuration: -1,
      weeklySchedules: [
        WeeklySchedule(
          schedule: {
            Day.monday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.wednesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.friday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
          },
          period: period,
        ),
      ],
      transportations: [Transportation.ticket],
      visitFrequencies: 'Une visite par semaine',
    ),
  );

  startingPeriod = DateTime.now().subtract(const Duration(days: 100));
  period = time_utils.DateTimeRange(
    start: startingPeriod,
    end: startingPeriod.add(Duration(days: rng.nextInt(90) + 360)),
  );
  internships.add(
    Internship(
      schoolBoardId: mySchoolBoardId,
      creationDate: DateTime.now(),
      studentId: students.firstWhere((e) => e.fullName == 'Jeanne Tremblay').id,
      // This is a Roméo Montaigu's student
      signatoryTeacherId: myPartnerTeacherId,
      extraSupervisingTeacherIds: [],
      enterpriseId: enterprises.firstWhere((e) => e.name == 'Metro Gagnon').id,
      jobId: enterprises.firstWhere((e) => e.name == 'Metro Gagnon').jobs[0].id,
      extraSpecializationIds: [],
      supervisor: Person(
        firstName: 'Nobody',
        middleName: null,
        lastName: 'Forever',
        dateBirth: null,
        phone: PhoneNumber.fromString('123-456-7890'),
        address: null,
        email: '',
      ),
      dates: period,
      expectedDuration: 135,
      achievedDuration: -1,
      endDate: DateTime(0),
      weeklySchedules: [
        WeeklySchedule(
          schedule: {
            Day.monday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.tuesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.wednesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.thursday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.friday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
          },
          period: period,
        ),
      ],
      transportations: [Transportation.none],
      visitFrequencies: 'Jamais',
    ),
  );

  period = time_utils.DateTimeRange(
    start: DateTime.now(),
    end: DateTime.now().add(Duration(days: rng.nextInt(90))),
  );
  internships.add(
    Internship(
      schoolBoardId: mySchoolBoardId,
      creationDate: DateTime.now(),
      studentId: students.firstWhere((e) => e.fullName == 'Diego Vargas').id,
      // This is a Roméo Montaigu's student
      signatoryTeacherId: myPartnerTeacherId,
      extraSupervisingTeacherIds: [myTeacherId],
      enterpriseId: enterprises.firstWhere((e) => e.name == 'Metro Gagnon').id,
      jobId: enterprises.firstWhere((e) => e.name == 'Metro Gagnon').jobs[1].id,
      extraSpecializationIds: [],
      supervisor: Person(
        firstName: 'Nobody',
        middleName: null,
        lastName: 'Forever',
        dateBirth: null,
        phone: null,
        address: null,
        email: '',
      ),
      dates: period,
      expectedDuration: 135,
      achievedDuration: -1,
      endDate: DateTime(0),
      weeklySchedules: [
        WeeklySchedule(
          schedule: {
            Day.monday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.tuesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.wednesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.thursday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.friday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
          },
          period: period,
        ),
      ],
      transportations: [Transportation.none],
      visitFrequencies: 'Une visite par semaine',
    ),
  );

  startingPeriod = DateTime.now().subtract(Duration(days: rng.nextInt(250)));
  period = time_utils.DateTimeRange(
    start: startingPeriod,
    end: startingPeriod.add(Duration(days: rng.nextInt(50))),
  );
  internships.add(
    Internship(
      schoolBoardId: mySchoolBoardId,
      creationDate: DateTime.now(),
      studentId: students.firstWhere((e) => e.fullName == 'Vanessa Monette').id,
      signatoryTeacherId: myTeacherId,
      extraSupervisingTeacherIds: [],
      enterpriseId: enterprises.firstWhere((e) => e.name == 'Jean Coutu').id,
      jobId: enterprises.firstWhere((e) => e.name == 'Jean Coutu').jobs[0].id,
      extraSpecializationIds: [],
      supervisor: Person(
        firstName: 'Un',
        middleName: null,
        lastName: 'Ami',
        dateBirth: null,
        phone: null,
        address: null,
        email: '',
      ),
      dates: period,
      endDate: period.end,
      expectedDuration: 135,
      achievedDuration: 100,
      weeklySchedules: [
        WeeklySchedule(
          schedule: {
            Day.monday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.tuesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
          },
          period: period,
        ),
      ],
      transportations: [Transportation.none],
      visitFrequencies: 'Une visite par semaine',
    ),
  );

  startingPeriod = DateTime.now().subtract(Duration(days: rng.nextInt(200)));
  period = time_utils.DateTimeRange(
    start: startingPeriod,
    end: startingPeriod.add(Duration(days: rng.nextInt(50))),
  );
  internships.add(
    Internship(
      schoolBoardId: mySchoolBoardId,
      creationDate: DateTime.now(),
      studentId: students.firstWhere((e) => e.fullName == 'Vanessa Monette').id,
      signatoryTeacherId: myTeacherId,
      extraSupervisingTeacherIds: [],
      enterpriseId: enterprises.firstWhere((e) => e.name == 'Pharmaprix').id,
      jobId: enterprises.firstWhere((e) => e.name == 'Pharmaprix').jobs[0].id,
      extraSpecializationIds: [],
      supervisor: Person(
        firstName: 'Deux',
        middleName: null,
        lastName: 'Amis',
        dateBirth: null,
        phone: null,
        address: null,
        email: '',
      ),
      dates: period,
      endDate: period.end,
      expectedDuration: 135,
      achievedDuration: 100,
      weeklySchedules: [
        WeeklySchedule(
          schedule: {
            Day.monday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
            Day.tuesday: DailySchedule(
              blocks: [
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 9, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 12, minute: 00),
                ),
                TimeBlock(
                  start: const time_utils.TimeOfDay(hour: 13, minute: 00),
                  end: const time_utils.TimeOfDay(hour: 15, minute: 00),
                ),
              ],
            ),
          },
          period: period,
        ),
      ],
      transportations: [Transportation.none],
      visitFrequencies: 'Tous les jours',
    ),
  );
  await _waitForDatabaseUpdate(internships, 9);

  // Set the visiting priorities of the internships for teacherA1Id
  final currentTeacher = teachers.firstWhere(
    (teacher) => teacher.id == myTeacherId,
  );
  var studentId = students.firstWhere((e) => e.fullName == 'Cedric Masson').id;
  var internshipId =
      internships
          .firstWhere((internship) => internship.studentId == studentId)
          .id;
  currentTeacher.setVisitingPriority(internshipId, VisitingPriority.values[2]);

  studentId = students.firstWhere((e) => e.fullName == 'Thomas Caron').id;
  internshipId =
      internships
          .firstWhere((internship) => internship.studentId == studentId)
          .id;
  currentTeacher.setVisitingPriority(internshipId, VisitingPriority.values[1]);

  studentId = students.firstWhere((e) => e.fullName == 'Melissa Poulain').id;
  internshipId =
      internships
          .firstWhere((internship) => internship.studentId == studentId)
          .id;
  currentTeacher.setVisitingPriority(internshipId, VisitingPriority.values[0]);
  await teachers.replaceWithConfirmation(currentTeacher);
}

Future<void> _waitForDatabaseUpdate(
  BackendListProvided list,
  int expectedLength, {
  bool strictlyEqualToExpected = false,
}) async {
  // Wait for the database to add all the students
  while (strictlyEqualToExpected
      ? list.length != expectedLength
      : list.length < expectedLength) {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
