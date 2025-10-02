import 'package:mysql1/mysql1.dart';

class DummyMySqlConnection implements MySqlConnection {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
