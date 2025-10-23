import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
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

  @override
  FetchableFields get referenceFetchableFields => Student.fetchableFields;

  Future<void> initializeAuth(AuthProvider auth) async {
    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }
}
