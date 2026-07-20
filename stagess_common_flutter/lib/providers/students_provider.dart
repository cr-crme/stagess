import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/backend_list_provided.dart';

class StudentsProvider extends BackendListProvided<Student> {
  StudentsProvider({required super.uri, super.mockMe});
  String? currentId;

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
  void itemChanged(String id) {
    // When new fields are registered to a student in the list, if this student
    // is from another group, but current teacher was added to the teachers in charge
    // we must request the full data for that particular student.
    final student = fromIdOrNull(id);

    // If this is a new student, normal behavior applies
    if (student == null) return;

    // If the student is not in charge of the current teacher, normal behavior applies
    if (student.teacherInChargeId != currentId &&
        !student.supplementaryTeacherInChargeIds.contains(currentId)) {
      return;
    }

    // If the student is not yet initialized, request the full data for this student
    if (student.fullName.isEmpty) {
      fetchData(id: id, fields: Student.fetchableFields, forceRefetchAll: true);
    }
  }

  @override
  FetchableFields get referenceFetchableFields => Student.fetchableFields;

  Future<void> initializeAuth(AuthProvider auth) async {
    currentId = auth.currentId;
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }
}
