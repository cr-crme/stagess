import 'package:flutter/material.dart';

class SubTitle extends StatelessWidget {
  const SubTitle(
    this.text, {
    super.key,
    this.left = 16.0,
    this.top = 24.0,
    this.bottom = 8.0,
    this.right = 0.0,
  });

  final String text;
  final double left;
  final double top;
  final double bottom;
  final double right;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(left: left, top: top, bottom: bottom, right: right),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}
