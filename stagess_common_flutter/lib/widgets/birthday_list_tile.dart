import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BirthdayController {
  BirthdayController({required DateTime? initialValue}) : _value = initialValue;

  DateTime? _value;
  DateTime? get value => _value;

  void updateValue(DateTime? newValue) {
    _value = newValue;
  }

  void dispose() {
    _value = null;
  }
}

class BirthdayListTile extends StatefulWidget {
  const BirthdayListTile({
    super.key,
    this.title = 'Date de naissance : ',
    this.titleStyle,
    this.contentStyle,
    this.icon = Icons.calendar_today,
    this.onSaved,
    this.isMandatory = false,
    this.enabled = true,
    required this.controller,
  });

  final String title;
  final TextStyle? titleStyle;
  final TextStyle? contentStyle;
  final IconData icon;
  final Function(String?)? onSaved;
  final bool isMandatory;
  final bool enabled;
  final BirthdayController controller;

  @override
  State<BirthdayListTile> createState() => _BirthdayListTileState();
}

class _BirthdayListTileState extends State<BirthdayListTile> {
  Future<void> _onTap() async {
    final answer = await showDatePicker(
      context: context,
      initialDate:
          widget.controller.value == DateTime(0) ||
                  widget.controller.value == null
              ? DateTime.now()
              : widget.controller.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (answer == null || !mounted) return;

    setState(() {
      widget.controller._value = answer;
    });
  }

  void _deleteBirthday() {
    setState(() {
      widget.controller._value = DateTime(0);
    });
  }

  @override
  void didUpdateWidget(covariant BirthdayListTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.enabled ? _onTap : null,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 8.0,
          right: 12.0,
          top: 4.0,
          bottom: 4.0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style:
                      widget.titleStyle ?? const TextStyle(color: Colors.black),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.controller.value == null ||
                          widget.controller.value == DateTime(0)
                      ? 'Aucune fournie'
                      : DateFormat(
                        'yyyy-MM-dd',
                      ).format(widget.controller.value!),
                  style:
                      widget.contentStyle ??
                      const TextStyle(color: Colors.black),
                ),
              ],
            ),
            if (widget.enabled)
              IconButton(
                onPressed: _deleteBirthday,
                icon: Icon(Icons.delete, color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}
