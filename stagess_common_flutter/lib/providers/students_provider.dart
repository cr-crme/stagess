import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/backend_list_provided.dart';

class StudentsProvider extends BackendListProvided<Student> {
  StudentsProvider({required super.uri, super.mockMe});

  static StudentsProvider of(BuildContext context, {listen = true}) {
    return Provider.of<StudentsProvider>(context, listen: listen);
  }

  @override
  RequestFields getField([bool asList = false]) {
    return asList ? RequestFields.students : RequestFields.student;
  }

  @override
  Student deserializeItem(data) {
    return Student.fromSerialized(data);
  }

  Future<void> initializeAuth(AuthProvider auth) async {
    final fields = {
      'school_board_id': null,
      'school_id': null,
      'first_name': null,
      'middle_name': null,
      'last_name': null,
      'group': null,
    };
    initializeFetchingData(authProvider: auth, initialFieldsToFetch: fields);
    auth.addListener(
      () => initializeFetchingData(
        authProvider: auth,
        initialFieldsToFetch: fields,
      ),
    );
  }
}
