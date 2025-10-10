import 'dart:async';
import 'dart:convert';

import 'package:mysql1/mysql1.dart';
import 'package:stagess_backend/utils/database_user.dart';
import 'package:stagess_backend/utils/exceptions.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/person.dart';

final _protectedTables = [
  'students',
  'teachers',
  'enterprises',
  'internships',
];

abstract class SqlInterface {
  ///
  /// The current connection to the database
  get connection;

  ///
  /// Try to perform a query, and catch any database exception to rethrow
  Future<Results> tryQuery(String query, [List<Object?>? values]);

  ///
  /// Perform a SELECT query and return the results as a list of maps
  Future<List<Map<String, dynamic>>> performSelectQuery({
    required DatabaseUser user,
    required String tableName,
    List<String>? fieldsToFetch,
    Map<String, String>? filters,
    List<MySqlTableAccessor>? subqueries,
  });

  ///
  /// Craft and perform an INSERT query
  Future<Results> performInsertQuery({
    required String tableName,
    required Map<String, dynamic> data,
  });

  ///
  /// Craft and perform an UPDATE query
  Future<Results> performUpdateQuery({
    required String tableName,
    Map<String, String>? filters,
    required Map<String, dynamic> data,
  });

  ///
  /// Craft and perform a DELETE query
  Future<Results> performDeleteQuery({
    required String tableName,
    Map<String, String>? filters,
  });

  ///
  /// Craft and perform an INSERT queries for person entity
  Future<void> performInsertPerson({
    required Person person,
    bool skipAddingEntity = false,
  });

  ///
  /// Craft and perform an UPDATE queries for person entity
  Future<void> performUpdatePerson({
    required Person person,
    required Person previous,
  });

  ///
  /// Craft and perform an INSERT queries for phone number
  Future<void> performInsertPhoneNumber({
    required PhoneNumber phoneNumber,
    required String entityId,
  });

  ///
  /// Craft and perform an UPDATE queries for phone number
  Future<void> performUpdatePhoneNumber({
    required PhoneNumber phoneNumber,
    required PhoneNumber previous,
  });

  ///
  /// Craft and perform a DELETE queries for phone number
  Future<void> performDeletePhoneNumber({
    required PhoneNumber phoneNumber,
  });

  ///
  /// Craft and perform an INSERT queries for address
  Future<void> performInsertAddress({
    required Address address,
    required String entityId,
  });

  ///
  /// Craft and perform an UPDATE queries for address
  Future<void> performUpdateAddress({
    required Address address,
    required Address previous,
  });

  ///
  /// Craft and perform a DELETE queries for address
  Future<void> performDeleteAddress({
    required Address address,
  });

  ///
  /// Craft a subquery that will join a relation table to get the data from another table
  MySqlTableAccessor joinSubquery({
    required String dataTableName,
    String? asName,
    String dataTableIdName = 'id',
    required String relationTableName,
    required String idNameToDataTable,
    required String idNameToMainTable,
    String mainTableIdName = 'id',
    required List<String> fieldsToFetch,
  });

  ///
  /// Craft a subquery that will select data from another table based on a foreign key
  MySqlTableAccessor selectSubquery({
    required String dataTableName,
    String? asName,
    String idNameToDataTable = 'id',
    String idNameToMainTable = 'id',
    required List<String> fieldsToFetch,
  });
}

class MySqlInterface implements SqlInterface {
  MySqlConnection _connection;
  @override
  MySqlConnection get connection => _connection;

  static Future<MySqlInterface> connect({
    required Future<MySqlConnection> Function() connectToDatabase,
  }) async =>
      MySqlInterface._(
          connection: await connectToDatabase(),
          connectToDatabase: connectToDatabase);

  MySqlInterface._({
    required MySqlConnection connection,
    required Future<MySqlConnection> Function() connectToDatabase,
  }) : _connection = connection {
    // Keep alive the connection

    Timer.periodic(Duration(minutes: 5), (timer) async {
      await _keepAlive(connectToDatabase: connectToDatabase);
    });
  }

  Future<void> _keepAlive(
      {required Future<MySqlConnection> Function() connectToDatabase}) async {
    try {
      await tryQuery('SELECT 1');
    } catch (e) {
      _connection = await connectToDatabase();
    }
  }

// coverage:ignore-start
  @override
  Future<Results> tryQuery(String query, [List<Object?>? values]) async {
    try {
      return await connection.query(query, values);
    } on MySqlException catch (e) {
      throw DatabaseFailureException(
          'Database failure: ${e.message} (${e.errorNumber}). '
          'This should not happen, please contact the administrator of the database.');
    } catch (e) {
      throw DatabaseFailureException('Database failure: $e. '
          'This should not happen, please contact the administrator of the database.');
    }
  }
// coverage:ignore-end

// coverage:ignore-start
  @override
  Future<List<Map<String, dynamic>>> performSelectQuery({
    required DatabaseUser user,
    required String tableName,
    List<String>? fieldsToFetch,
    Map<String, String>? filters,
    List<MySqlTableAccessor>? subqueries,
  }) async {
    if (_protectedTables.contains(tableName) &&
        (filters?['school_board_id']?.isEmpty ?? true)) {
      // If the table is protected, we need to check if the user has super admin access
      if (user.accessLevel < AccessLevel.superAdmin) {
        throw InvalidRequestException(
            'You cannot access a protected table $tableName without a school board id.');
      }
    }

    final results = await tryQuery(
        craftSelectQuery(
            tableName: tableName,
            fieldsToFetch: fieldsToFetch,
            filters: filters,
            sublists: subqueries),
        [...filters?.values ?? []]);

    final List<Map<String, dynamic>> list = [];
    for (final row in results) {
      final Map<String, dynamic> map = row.fields;
      if (subqueries == null || subqueries.isEmpty) {
        list.add(map);
        continue;
      }
      for (final sublist in subqueries) {
        final tableRow = map[sublist.tableName];
        if (tableRow == null) continue;
        map[sublist.tableName] =
            jsonDecode((tableRow is String ? tableRow : tableRow.toString()));
      }
      list.add(map);
    }

    return list;
  }
// coverage:ignore-end

  String craftSelectQuery({
    required String tableName,
    List<String>? fieldsToFetch,
    Map<String, String>? filters,
    List<MySqlTableAccessor>? sublists,
  }) {
    final filtersAsString = (filters == null || filters.isEmpty)
        ? ''
        : 'WHERE ${filters.keys.map((e) => 't.$e = ?').join(' AND ')}';
    final fieldsToFetchAsString = fieldsToFetch == null || fieldsToFetch.isEmpty
        ? 't.*'
        : 't.${fieldsToFetch.join(', t.')}';

    return '''SELECT $fieldsToFetchAsString${sublists == null || sublists.isEmpty ? '' : ','} 
      ${sublists?.map((e) => e._craft(mainTableAlias: 't')).join(',') ?? ''}
    FROM $tableName t $filtersAsString
    ''';
  }

// coverage:ignore-start
  @override
  Future<Results> performInsertQuery({
    required String tableName,
    required Map<String, dynamic> data,
  }) async =>
      await tryQuery(
          craftInsertQuery(tableName: tableName, data: data), [...data.values]);
// coverage:ignore-end

  String craftInsertQuery({
    required String tableName,
    required Map<String, dynamic> data,
  }) =>
      '''INSERT INTO $tableName (${data.keys.join(', ')})
       VALUES (${data.keys.map((e) => '?').join(', ')})''';

// coverage:ignore-start
  @override
  Future<Results> performUpdateQuery({
    required String tableName,
    Map<String, String>? filters,
    required Map<String, dynamic> data,
  }) async =>
      await tryQuery(
          craftUpdateQuery(tableName: tableName, filters: filters, data: data),
          [...data.values, ...(filters?.values ?? [])]);
// coverage:ignore-end

  String craftUpdateQuery({
    required String tableName,
    required Map<String, String>? filters,
    required Map<String, dynamic> data,
  }) {
    final filtersAsString = filters == null
        ? ''
        : 'WHERE ${filters.keys.map((e) => '$e = ?').join(' AND ')}';

    return '''UPDATE $tableName SET ${data.keys.join(' = ?, ')} = ?
       $filtersAsString''';
  }

// coverage:ignore-start
  @override
  Future<Results> performDeleteQuery({
    required String tableName,
    Map<String, String>? filters,
  }) async =>
      await tryQuery(craftDeleteQuery(tableName: tableName, filters: filters),
          filters?.values.toList() ?? []);
// coverage:ignore-end

  String craftDeleteQuery({
    required String tableName,
    Map<String, String>? filters,
  }) {
    final filtersAsString = filters == null
        ? ''
        : 'WHERE ${filters.keys.map((e) => '$e = ?').join(' AND ')}';

    return '''DELETE FROM $tableName
       $filtersAsString''';
  }

// coverage:ignore-start
  ///
  /// Specific helpers
  @override
  Future<void> performInsertPerson({
    required Person person,
    bool skipAddingEntity = false,
  }) async {
    if (!skipAddingEntity) {
      await performInsertQuery(
          tableName: 'entities', data: {'shared_id': person.id});
    }
    await performInsertQuery(tableName: 'persons', data: {
      'id': person.id,
      'first_name': person.firstName,
      'middle_name': person.middleName,
      'last_name': person.lastName,
      'date_birthday': person.dateBirth?.toIso8601String().substring(0, 10),
      'email': person.email,
    });

    await performInsertPhoneNumber(
        phoneNumber: person.phone ?? PhoneNumber.empty, entityId: person.id);

    await performInsertAddress(
        address: person.address ?? Address.empty, entityId: person.id);
  }

  @override
  Future<void> performUpdatePerson({
    required Person person,
    required Person previous,
  }) async {
    // Update the person if needed
    final toUpdate = <String, dynamic>{};
    if (person.firstName != previous.firstName) {
      toUpdate['first_name'] = person.firstName;
    }
    if (person.middleName != previous.middleName) {
      toUpdate['middle_name'] = person.middleName;
    }
    if (person.lastName != previous.lastName) {
      toUpdate['last_name'] = person.lastName;
    }
    if (person.dateBirth != previous.dateBirth) {
      toUpdate['date_birthday'] =
          person.dateBirth?.toIso8601String().substring(0, 10);
    }
    if (person.email != previous.email) {
      toUpdate['email'] = person.email;
    }
    if (toUpdate.isNotEmpty) {
      await performUpdateQuery(
        tableName: 'persons',
        filters: {'id': person.id},
        data: toUpdate,
      );
    }

    // Update the phone number if needed
    if (person.phone != previous.phone) {
      // Update the phone number
      if (person.phone == null) {
        // Delete the phone number
        await performDeletePhoneNumber(phoneNumber: previous.phone!);
      } else if (previous.phone == null) {
        // Insert the new phone number
        await performInsertPhoneNumber(
            phoneNumber: person.phone!, entityId: person.id);
      } else {
        // Update the phone number
        await performUpdatePhoneNumber(
            phoneNumber: person.phone!, previous: previous.phone!);
      }
    }

    // Update the address if needed
    if (person.address != previous.address) {
      // Update the address
      if (person.address == null) {
        // Delete the address
        await performDeleteAddress(address: previous.address!);
      } else if (previous.address == null) {
        // Insert the new address
        await performInsertAddress(
            address: person.address!, entityId: person.id);
      } else {
        // Update the address
        await performUpdateAddress(
            address: person.address!, previous: previous.address!);
      }
    }
  }

  @override
  Future<void> performInsertPhoneNumber({
    required PhoneNumber phoneNumber,
    required String entityId,
  }) async {
    await performInsertQuery(tableName: 'phone_numbers', data: {
      'id': phoneNumber.id,
      'entity_id': entityId,
      'phone_number': phoneNumber.toString()
    });
  }

  @override
  Future<void> performUpdatePhoneNumber({
    required PhoneNumber phoneNumber,
    required PhoneNumber previous,
  }) async {
    // Update the phone number if needed
    if (phoneNumber.toString() == previous.toString()) return;
    await performUpdateQuery(
        tableName: 'phone_numbers',
        filters: {'id': previous.id},
        data: {'phone_number': phoneNumber.toString()});
  }

  @override
  Future<void> performDeletePhoneNumber({
    required PhoneNumber phoneNumber,
  }) async {
    await performDeleteQuery(
        tableName: 'phone_numbers', filters: {'id': phoneNumber.id});
  }

  @override
  Future<void> performInsertAddress({
    required Address address,
    required String entityId,
  }) async {
    await performInsertQuery(tableName: 'addresses', data: {
      'id': address.id,
      'entity_id': entityId,
      'civic': address.civicNumber,
      'street': address.street,
      'apartment': address.apartment,
      'city': address.city,
      'postal_code': address.postalCode
    });
  }

  @override
  Future<void> performUpdateAddress({
    required Address address,
    required Address previous,
  }) async {
    // Update the address if needed
    final toUpdate = <String, dynamic>{};

    if (address.civicNumber != previous.civicNumber) {
      toUpdate['civic'] = address.civicNumber;
    }
    if (address.street != previous.street) {
      toUpdate['street'] = address.street;
    }
    if (address.apartment != previous.apartment) {
      toUpdate['apartment'] = address.apartment;
    }
    if (address.city != previous.city) {
      toUpdate['city'] = address.city;
    }
    if (address.postalCode != previous.postalCode) {
      toUpdate['postal_code'] = address.postalCode;
    }
    if (toUpdate.isNotEmpty) {
      await performUpdateQuery(
          tableName: 'addresses', filters: {'id': previous.id}, data: toUpdate);
    }
  }

  @override
  Future<void> performDeleteAddress({
    required Address address,
  }) async {
    await performDeleteQuery(
        tableName: 'addresses', filters: {'id': address.id});
  }
// coverage:ignore-end

  @override
  MySqlTableAccessor joinSubquery({
    required String dataTableName,
    String? asName,
    String dataTableIdName = 'id',
    required String relationTableName,
    required String idNameToDataTable,
    required String idNameToMainTable,
    String mainTableIdName = 'id',
    required List<String> fieldsToFetch,
  }) =>
      _MySqlJoinSubQuery(
          dataTableName: dataTableName,
          asName: asName,
          dataTableIdName: dataTableIdName,
          relationTableName: relationTableName,
          idNameToDataTable: idNameToDataTable,
          idNameToMainTable: idNameToMainTable,
          mainTableIdName: mainTableIdName,
          fieldsToFetch: fieldsToFetch);

  @override
  MySqlTableAccessor selectSubquery({
    required String dataTableName,
    String? asName,
    String idNameToDataTable = 'id',
    String idNameToMainTable = 'id',
    required List<String> fieldsToFetch,
  }) =>
      _MySqlSelectSubQuery(
          dataTableName: dataTableName,
          asName: asName,
          idNameToDataTable: idNameToDataTable,
          idNameToMainTable: idNameToMainTable,
          fieldsToFetch: fieldsToFetch);
}

class MariaDbSqlInterface extends MySqlInterface {
  static Future<MariaDbSqlInterface> connect({
    required Future<MySqlConnection> Function() connectToDatabase,
  }) async =>
      MariaDbSqlInterface._(
          connection: await connectToDatabase(),
          connectToDatabase: connectToDatabase);

  MariaDbSqlInterface._(
      {required super.connection, required super.connectToDatabase})
      : super._();

  @override
  Future<Results> tryQuery(String query, [List<Object?>? values]) async {
    // MariaDB fails when a JSON_OBJECT is used with a non-null values. When this
    // happens, we need to collapse the "?" in the query ourselves. NOTE: This is
    // dangerous, as it can lead to SQL injection if the query is not properly
    // sanitized.

    if (values != null && values.isNotEmpty) {
      for (final value in values) {
        final escaped = _escapeValue(value); // safe escaping
        // replace only the first "?" at a time
        query = query.replaceFirst('?', escaped);
      }
    }
    return super.tryQuery(query);
  }

  String _escapeValue(Object? value) {
    if (value == null) return 'NULL';

    if (value is num) return value.toString();
    if (value is bool) return value ? '1' : '0';

    // For DateTime, format as MySQL DATETIME
    if (value is DateTime) {
      return "'${value.toUtc().toIso8601String().replaceFirst('T', ' ').split('.').first}'";
    }

    // Fallback: treat as string
    var s = value.toString();
    // Escape backslashes and quotes
    s = s.replaceAll(r'\', r'\\');
    s = s.replaceAll("'", r"\'");
    s = s.replaceAll('"', r'\"');
    return "'$s'";
  }

  @override
  MySqlTableAccessor joinSubquery({
    required String dataTableName,
    String? asName,
    String dataTableIdName = 'id',
    required String relationTableName,
    required String idNameToDataTable,
    required String idNameToMainTable,
    String mainTableIdName = 'id',
    required List<String> fieldsToFetch,
  }) =>
      _MariaDbJoinSubQuery(
          dataTableName: dataTableName,
          asName: asName,
          dataTableIdName: dataTableIdName,
          relationTableName: relationTableName,
          idNameToDataTable: idNameToDataTable,
          idNameToMainTable: idNameToMainTable,
          mainTableIdName: mainTableIdName,
          fieldsToFetch: fieldsToFetch);

  @override
  MySqlTableAccessor selectSubquery({
    required String dataTableName,
    String? asName,
    String idNameToDataTable = 'id',
    String idNameToMainTable = 'id',
    required List<String> fieldsToFetch,
  }) =>
      _MariaDbSelectSubQuery(
          dataTableName: dataTableName,
          asName: asName,
          idNameToDataTable: idNameToDataTable,
          idNameToMainTable: idNameToMainTable,
          fieldsToFetch: fieldsToFetch);
}

abstract class MySqlTableAccessor {
  String get tableName;
  String get tableIdName;

  String _craft({required String mainTableAlias});

  String _dispatchFieldsToFetch(
      {required List<String> fieldsToFetch,
      required String tableElementAlias}) {
    if (fieldsToFetch.isEmpty) throw 'Fields cannot be empty';

    String fieldsInMainList = '';
    for (final field in fieldsToFetch) {
      fieldsInMainList += '\'$field\', $tableElementAlias.$field, ';
    }
    fieldsInMainList =
        fieldsInMainList.substring(0, fieldsInMainList.length - 2);

    return fieldsInMainList;
  }
}

class _MySqlJoinSubQuery extends MySqlTableAccessor {
  // Data table
  final String dataTableName;
  final String asName;
  final String dataTableIdName;
  @override
  String get tableName => asName;
  @override
  String get tableIdName => dataTableIdName;

  // Relation table
  final String relationTableName;
  final String idNameToDataTable;
  final String idNameToMainTable;

  // Main table
  final String mainTableIdName;
  final List<String> fieldsToFetch;

  _MySqlJoinSubQuery({
    required this.dataTableName,
    String? asName,
    this.dataTableIdName = 'id',
    required this.relationTableName,
    required this.idNameToDataTable,
    required this.idNameToMainTable,
    this.mainTableIdName = 'id',
    required this.fieldsToFetch,
  }) : asName = asName ?? dataTableName;

  @override
  String _craft({required String mainTableAlias}) {
    return '''IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
              ${_dispatchFieldsToFetch(fieldsToFetch: fieldsToFetch, tableElementAlias: 'st')}
            )
        )
        FROM $relationTableName idt
        JOIN $dataTableName st ON idt.$idNameToDataTable = st.$dataTableIdName
        WHERE idt.$idNameToMainTable = $mainTableAlias.$mainTableIdName
      ), JSON_ARRAY()) AS $tableName''';
  }
}

class _MySqlSelectSubQuery extends MySqlTableAccessor {
  final String dataTableName;
  final String asName;
  @override
  String get tableName => asName;

  final String idNameToDataTable;
  final String idNameToMainTable;
  @override
  String get tableIdName => idNameToDataTable;

  final List<String> fieldsToFetch;

  _MySqlSelectSubQuery({
    required this.dataTableName,
    String? asName,
    this.idNameToDataTable = 'id',
    this.idNameToMainTable = 'id',
    required this.fieldsToFetch,
  }) : asName = asName ?? dataTableName;

  @override
  String _craft({required String mainTableAlias}) {
    return '''IFNULL((
        SELECT JSON_ARRAYAGG(
            JSON_OBJECT(
              ${_dispatchFieldsToFetch(fieldsToFetch: fieldsToFetch, tableElementAlias: 'st')}
            )
        )
        FROM $dataTableName st
        WHERE st.$idNameToDataTable = $mainTableAlias.$idNameToMainTable
      ), JSON_ARRAY()) AS $tableName''';
  }
}

class _MariaDbJoinSubQuery extends MySqlTableAccessor {
  // Data table
  final String dataTableName;
  final String asName;
  final String dataTableIdName;
  @override
  String get tableName => asName;
  @override
  String get tableIdName => dataTableIdName;

  // Relation table
  final String relationTableName;
  final String idNameToDataTable;
  final String idNameToMainTable;

  // Main table
  final String mainTableIdName;
  final List<String> fieldsToFetch;

  _MariaDbJoinSubQuery({
    required this.dataTableName,
    String? asName,
    this.dataTableIdName = 'id',
    required this.relationTableName,
    required this.idNameToDataTable,
    required this.idNameToMainTable,
    this.mainTableIdName = 'id',
    required this.fieldsToFetch,
  }) : asName = asName ?? dataTableName;

  @override
  String _craft({required String mainTableAlias}) {
    return '''
      IFNULL((
        SELECT CONCAT(
          '[',
            GROUP_CONCAT(
              JSON_OBJECT(
                ${_dispatchFieldsToFetch(fieldsToFetch: fieldsToFetch, tableElementAlias: 'st')}
              )
              SEPARATOR ','
            ),
          ']'
        )
        FROM $relationTableName idt
        JOIN $dataTableName st ON idt.$idNameToDataTable = st.$dataTableIdName
        WHERE idt.$idNameToMainTable = $mainTableAlias.$mainTableIdName
      ), '[]') AS $tableName''';
  }
}

class _MariaDbSelectSubQuery extends MySqlTableAccessor {
  final String dataTableName;
  final String asName;
  @override
  String get tableName => asName;

  final String idNameToDataTable;
  final String idNameToMainTable;
  @override
  String get tableIdName => idNameToDataTable;

  final List<String> fieldsToFetch;

  _MariaDbSelectSubQuery({
    required this.dataTableName,
    String? asName,
    this.idNameToDataTable = 'id',
    this.idNameToMainTable = 'id',
    required this.fieldsToFetch,
  }) : asName = asName ?? dataTableName;

  @override
  String _craft({required String mainTableAlias}) {
    return '''
      IFNULL((
        SELECT CONCAT(
          '[',
            GROUP_CONCAT(
              JSON_OBJECT(
                ${_dispatchFieldsToFetch(fieldsToFetch: fieldsToFetch, tableElementAlias: 'st')}
              )
              SEPARATOR ','
            ),
          ']'
        )
        FROM $dataTableName st
        WHERE st.$idNameToDataTable = $mainTableAlias.$idNameToMainTable
      ), '[]') AS $tableName''';
  }
}
