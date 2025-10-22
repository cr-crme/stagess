import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/backend_list_provided.dart';

class InternshipsProvider extends BackendListProvided<Internship> {
  InternshipsProvider({required super.uri, super.mockMe});

  static InternshipsProvider of(BuildContext context, {listen = true}) =>
      Provider.of<InternshipsProvider>(context, listen: listen);

  void updateTeacherNote(String studentId, String notes) {
    replace(byStudentId(studentId).last.copyWith(teacherNotes: notes));
  }

  List<Internship> byStudentId(String studentId) {
    return where((internship) => internship.studentId == studentId).toList();
  }

  @override
  Internship deserializeItem(data) {
    return Internship.fromSerialized(data);
  }

  @override
  FetchingFields get mandatoryFields => FetchingFields.fromMap({
    'school_board_id': FetchingFields.all,
    'student_id': FetchingFields.all,
    'enterprise_id': FetchingFields.all,
    'job_id': FetchingFields.all,
    'extra_specialization_ids': FetchingFields.all,
    'signatory_teacher_id': FetchingFields.all,
    'extra_supervising_teacher_ids': FetchingFields.all,
    'mutables': FetchingFields.fromMap({'id': FetchingFields.all}),
    'end_date': FetchingFields.all,
  });

  void initializeAuth(AuthProvider auth) {
    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }

  @override
  RequestFields getField([bool asList = false]) =>
      asList ? RequestFields.internships : RequestFields.internship;
}
