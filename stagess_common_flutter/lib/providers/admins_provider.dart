import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/persons/admin.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/backend_list_provided.dart';

class AdminsProvider extends BackendListProvided<Admin> {
  AdminsProvider({required super.uri, super.mockMe});

  static AdminsProvider of(BuildContext context, {listen = false}) =>
      Provider.of<AdminsProvider>(context, listen: listen);

  @override
  RequestFields getField([bool asList = false]) =>
      asList ? RequestFields.admins : RequestFields.admin;

  @override
  Admin deserializeItem(data) {
    return Admin.fromSerialized(data);
  }

  @override
  FetchableFields get referenceFetchableFields => FetchableFields.reference({
    'school_board_id': FetchableFields.mandatory,
    'first_name': FetchableFields.mandatory,
    'middle_name': FetchableFields.mandatory,
    'last_name': FetchableFields.mandatory,
    'email': FetchableFields.mandatory,
    'access_level': FetchableFields.mandatory,
    'has_registered_account': FetchableFields.mandatory,
  });

  void initializeAuth(AuthProvider auth) {
    if (!auth.isFullySignedIn ||
        auth.databaseAccessLevel < AccessLevel.superAdmin) {
      return;
    }

    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }

  Future<bool> addUserToDatabase({
    required String email,
    required AccessLevel userType,
  }) async {
    try {
      final response = await sendMessageWithResponse(
        message: CommunicationProtocol(
          requestType: RequestType.registerUser,
          field: RequestFields.teacher,
          data: {'email': email, 'user_type': userType.serialize()},
        ),
      );

      return response.response == Response.success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteUserFromDatabase({
    required String email,
    required AccessLevel userType,
  }) async {
    try {
      final response = await sendMessageWithResponse(
        message: CommunicationProtocol(
          requestType: RequestType.unregisterUser,
          field: RequestFields.teacher,
          data: {'email': email, 'user_type': userType.serialize()},
        ),
      );

      return response.response == Response.success;
    } catch (e) {
      return false;
    }
  }
}
