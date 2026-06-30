import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stagess_common/communication_protocol.dart';
import 'package:stagess_common/models/generic/empty_item.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/backend_list_provided.dart';

class BootLoaderProvider extends BackendListProvided<EmptyItem> {
  BootLoaderProvider({required super.uri, super.mockMe});

  static BootLoaderProvider of(BuildContext context, {listen = false}) =>
      Provider.of<BootLoaderProvider>(context, listen: listen);

  @override
  RequestFields getField([bool asList = false]) =>
      asList ? RequestFields.none : RequestFields.none;

  @override
  EmptyItem deserializeItem(data) {
    return EmptyItem.fromSerialized(data);
  }

  @override
  FetchableFields get referenceFetchableFields => EmptyItem.fetchableFields;

  void initializeAuth(AuthProvider auth) {
    initializeFetchingData(authProvider: auth);
  }
}
