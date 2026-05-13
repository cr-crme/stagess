import 'package:flutter/material.dart';

abstract class SingleInstanceManagerBase extends Widget {
  const SingleInstanceManagerBase(
      {super.key, required Widget child, required Widget isNotAllowedChild});

  Widget get child;
  Widget get isNotAllowedChild;
}
