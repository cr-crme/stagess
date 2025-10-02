import 'package:flutter/material.dart';

class RadioWithFollowUp<T> extends StatefulWidget {
  const RadioWithFollowUp({
    super.key,
    this.title,
    this.titleStyle,
    this.initialValue,
    required this.elements,
    this.elementsThatShowChild,
    this.followUpChild,
    this.onChanged,
    this.enabled = true,
  });

  final String? title;
  final TextStyle? titleStyle;
  final T? initialValue;
  final List<T> elements;
  final List<T>? elementsThatShowChild;
  final Widget? followUpChild;
  final Function(T? values)? onChanged;
  final bool enabled;

  @override
  State<RadioWithFollowUp<T>> createState() => RadioWithFollowUpState<T>();
}

class RadioWithFollowUpState<T> extends State<RadioWithFollowUp<T>> {
  late T? _current = widget.initialValue;

  /// This is a callback that can be called using the global key
  void forceValue(T value) => setState(() => _current = value);

  bool get hasFollowUp => _hasFollowUp;
  bool _hasFollowUp = false;

  bool get _showFollowUp => widget.followUpChild != null && _hasFollowUp;

  T? get value => _current;

  @override
  void initState() {
    super.initState();
    _checkShowFollowUp();
  }

  void _checkShowFollowUp() {
    _hasFollowUp = widget.elementsThatShowChild?.contains(_current) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return RadioGroup(
      groupValue: _current,
      onChanged: (newValue) {
        _current = newValue;
        _checkShowFollowUp();
        setState(() {});
        if (widget.onChanged != null) widget.onChanged!(value);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.title != null)
            Text(
              widget.title!,
              style:
                  widget.titleStyle ?? Theme.of(context).textTheme.titleSmall,
            ),
          ...widget.elements.map((element) => _buildElementTile(element)),
          if (_showFollowUp) widget.followUpChild!,
        ],
      ),
    );
  }

  RadioListTile<T> _buildElementTile(T element) {
    return RadioListTile<T>(
      visualDensity: VisualDensity.compact,
      dense: true,
      enabled: widget.enabled,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        element.toString(),
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      fillColor: WidgetStateColor.resolveWith((state) {
        return widget.enabled ? Theme.of(context).primaryColor : Colors.grey;
      }),
      value: element,
    );
  }
}
