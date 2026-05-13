import 'package:flutter/material.dart';

import 'single_instance_manager_base.dart';

class SingleInstanceManager extends StatelessWidget
    implements SingleInstanceManagerBase {
  const SingleInstanceManager(
      {super.key, required this.child, required Widget isNotAllowedChild});

  @override
  final Widget child;

  @override
  Widget get isNotAllowedChild => throw UnimplementedError(
      'isNotAllowedChild is not used in this implementation');

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
