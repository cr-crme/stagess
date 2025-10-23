import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
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
  FetchableFields get referenceFetchableFields => FetchableFields.reference({
    'school_board_id': FetchableFields.mandatory,
    'name': FetchableFields.mandatory,
    'address': FetchableFields.mandatory,
    'jobs': FetchableFields.reference({
      'id': FetchableFields.mandatory,
      'specialization_id': FetchableFields.mandatory,
      'positions_offered': FetchableFields.mandatory,
    }),
  });

  void initializeAuth(AuthProvider auth) {
    initializeFetchingData(authProvider: auth);
    auth.addListener(() => initializeFetchingData(authProvider: auth));
  }
}
