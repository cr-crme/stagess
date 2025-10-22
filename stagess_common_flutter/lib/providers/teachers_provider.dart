import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/backend_list_provided.dart';

class TeachersProvider extends BackendListProvided<Teacher> {
  TeachersProvider({required super.uri, super.mockMe});

  static TeachersProvider of(BuildContext context, {listen = false}) =>
      Provider.of<TeachersProvider>(context, listen: listen);

  @override
  RequestFields getField([bool asList = false]) =>
      asList ? RequestFields.teachers : RequestFields.teacher;

  @override
  Teacher deserializeItem(data) {
    return Teacher.fromSerialized(data);
  }

  Teacher? get currentTeacher =>
      _authProvider?.teacherId == null || !hasId(_authProvider!.teacherId ?? '')
          ? null
          : this[_authProvider!.teacherId];

  @override
  FetchingFields get mandatoryFields => FetchingFields.fromMap({
    'school_board_id': FetchingFields.all,
    'school_id': FetchingFields.all,
    'first_name': FetchingFields.all,
    'middle_name': FetchingFields.all,
    'last_name': FetchingFields.all,
    'email': FetchingFields.all,
    'groups': FetchingFields.all,
    'has_registered_account': FetchingFields.all,
  });

  AuthProvider? _authProvider;
  void initializeAuth(AuthProvider auth) {
    _authProvider = auth;
    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }
}
