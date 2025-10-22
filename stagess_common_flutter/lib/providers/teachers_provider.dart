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
  FetchableFields get fetchableFields => FetchableFields({
    'school_board_id': FetchableFields.mandatory,
    'school_id': FetchableFields.mandatory,
    'first_name': FetchableFields.mandatory,
    'middle_name': FetchableFields.mandatory,
    'last_name': FetchableFields.mandatory,
    'date_birth': FetchableFields.optional,
    'phone': FetchableFields.optional,
    'email': FetchableFields.mandatory,
    'address': FetchableFields.optional,
    'has_registered_account': FetchableFields.mandatory,
    'groups': FetchableFields.mandatory,
    'itineraries': FetchableFields.optional,
    'visiting_priorities': FetchableFields.optional,
  });

  AuthProvider? _authProvider;
  void initializeAuth(AuthProvider auth) {
    _authProvider = auth;
    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }
}
