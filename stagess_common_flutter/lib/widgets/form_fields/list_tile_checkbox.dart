import 'package:flutter/material.dart';

class ListTileCheckbox extends StatelessWidget {
  const ListTileCheckbox({
    required this.titleLabel,
    this.value,
    required this.onChanged,
    this.dense = true,
    super.key,
  });

  final String titleLabel;

  final bool? value;
  final void Function(bool? value) onChanged;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value!),
      child: ListTile(
        dense: dense,
        visualDensity: dense ? VisualDensity.compact : null,
        leading: Checkbox(
          value: value,
          onChanged: onChanged,
        ),
        title: Text(titleLabel),
      ),
    );
  }
}
