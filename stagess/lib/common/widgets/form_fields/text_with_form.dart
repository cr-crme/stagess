import 'package:flutter/material.dart';

class TextWithForm extends StatelessWidget {
  const TextWithForm({
    super.key,
    required this.title,
    this.enabled,
    this.titleStyle,
    this.controller,
    this.initialValue,
    this.onChanged,
    this.onSaved,
    this.validator,
    this.maxLength,
  });

  final String title;
  final bool? enabled;
  final TextStyle? titleStyle;
  final TextEditingController? controller;
  final String? initialValue;
  final void Function(String? text)? onChanged;
  final void Function(String? text)? onSaved;
  final String? Function(String? text)? validator;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: titleStyle ?? Theme.of(context).textTheme.titleSmall,
        ),
        TextFormField(
          controller: controller,
          enabled: enabled,
          initialValue: initialValue,
          onChanged: onChanged,
          onSaved: onSaved,
          validator: validator,
          style: Theme.of(context).textTheme.bodyMedium,
          minLines: 1,
          maxLines: 10,
          maxLength: maxLength,
        ),
      ],
    );
  }
}
