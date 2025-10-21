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
  Map<String, dynamic> get mandatoryFields => {
    'school_board_id': null,
    'student_id': null,
    'signatory_teacher_id': null,
    'extra_supervising_teacher_ids': null,
  };

  void initializeAuth(AuthProvider auth) {
    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }

  @override
  RequestFields getField([bool asList = false]) =>
      asList ? RequestFields.internships : RequestFields.internship;
}
