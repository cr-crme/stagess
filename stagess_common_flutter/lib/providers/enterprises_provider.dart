import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/backend_list_provided.dart';

class EnterprisesProvider extends BackendListProvided<Enterprise> {
  EnterprisesProvider({required super.uri, super.mockMe});

  static EnterprisesProvider of(BuildContext context, {listen = true}) =>
      Provider.of<EnterprisesProvider>(context, listen: listen);

  @override
  Enterprise deserializeItem(data) {
    return Enterprise.fromSerialized(data);
  }

  @override
  RequestFields getField([bool asList = false]) =>
      asList ? RequestFields.enterprises : RequestFields.enterprise;

  @override
  FetchingFields get mandatoryFields => FetchingFields.fromMap({
    'school_board_id': FetchingFields.all,
    'name': FetchingFields.all,
    'address': FetchingFields.all,
    'jobs': FetchingFields.fromMap({
      'id': FetchingFields.all,
      'specialization_id': FetchingFields.all,
      'positions_offered': FetchingFields.all,
    }),
  });

  void initializeAuth(AuthProvider auth) {
    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }
}
