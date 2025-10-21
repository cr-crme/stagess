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

  void initializeAuth(AuthProvider auth) {
    final fields = {
      'name': null,
      'address': null,
      'jobs': {'specialization_id': null, 'positions_offered': null},
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
