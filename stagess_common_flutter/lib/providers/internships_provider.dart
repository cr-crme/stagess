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
  FetchableFields get fetchableFields => FetchableFields({
    'school_board_id': FetchableFields.mandatory,
    'student_id': FetchableFields.mandatory,
    'enterprise_id': FetchableFields.mandatory,
    'job_id': FetchableFields.mandatory,
    'extra_specialization_ids': FetchableFields.mandatory,
    'signatory_teacher_id': FetchableFields.mandatory,
    'extra_supervising_teacher_ids': FetchableFields.mandatory,
    'mutables': FetchableFields({'id': FetchableFields.mandatory}),
    'end_date': FetchableFields.mandatory,
  });

  void initializeAuth(AuthProvider auth) {
    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }

  @override
  RequestFields getField([bool asList = false]) =>
      asList ? RequestFields.internships : RequestFields.internship;
}
