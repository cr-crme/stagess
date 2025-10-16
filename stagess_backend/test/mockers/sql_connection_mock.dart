import 'package:mysql1/mysql1.dart';
import 'package:stagess_backend/repositories/admins_repository.dart';
import 'package:stagess_backend/repositories/enterprises_repository.dart';
import 'package:stagess_backend/repositories/internships_repository.dart';
import 'package:stagess_backend/repositories/school_boards_repository.dart';
import 'package:stagess_backend/repositories/students_repository.dart';
import 'package:stagess_backend/repositories/teachers_repository.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_common/models/generic/access_level.dart';

class DatabaseUserMock extends DatabaseUser {
  final bool _isVerified;
  final String _schoolBoardId;
  final AccessLevel _accessLevel;

  DatabaseUserMock({
    bool isVerified = true,
    String schoolBoardId = '100',
    AccessLevel accessLevel = AccessLevel.teacher,
  })  : _isVerified = isVerified,
        _schoolBoardId = schoolBoardId,
        _accessLevel = accessLevel,
        super.empty();

  @override
  String get schoolBoardId => _schoolBoardId;

  @override
  AccessLevel get accessLevel => _accessLevel;

  @override
  bool get isVerified => _isVerified;
}

class ResultRowMock implements ResultRow {
  final Map<String, dynamic> _fields;
  @override
  Map<String, dynamic> get fields => _fields;

  ResultRowMock({required Map<String, dynamic> fields}) : _fields = fields;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ResultsMock implements Results {
  final List<ResultRow> _rows;

  ResultsMock({required List<ResultRow> rows}) : _rows = rows;

  // Return a successful empty result set
  @override
  Iterator<ResultRow> get iterator => _rows.iterator;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummyMySqlConnection implements MySqlConnection {
  final SchoolBoardsRepository? schoolBoardsRepository;
  final AdminsRepository? adminsRepository;
  final TeachersRepository? teachersRepository;
  final StudentsRepository? studentsRepository;
  final EnterprisesRepository? enterprisesRepository;
  final InternshipsRepository? internshipsRepository;

  DummyMySqlConnection({
    this.schoolBoardsRepository,
    this.adminsRepository,
    this.teachersRepository,
    this.studentsRepository,
    this.enterprisesRepository,
    this.internshipsRepository,
  });

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Results> query(String sql, [List<Object?>? values]) async {
    if (sql.contains('FROM admins t WHERE t.email = ?')) {
      if (adminsRepository == null) return ResultsMock(rows: []);

      final admins = await adminsRepository!
          .getAll(user: DatabaseUserMock(accessLevel: AccessLevel.superAdmin));

      if ((values?.length ?? 0) != 1) {
        throw 'Not implemented number of admins query';
      }
      final filter = values?[0];

      var data = admins.data == null
          ? <String, dynamic>{}
          : {
              for (var entry in admins.data!.entries)
                if (entry.value['email'] == filter) entry.key: entry.value
            };
      if (data.isNotEmpty) data = data.values.first;

      return ResultsMock(rows: [ResultRowMock(fields: data)]);
    }

    return ResultsMock(rows: []);
  }
}
