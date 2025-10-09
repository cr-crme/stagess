import 'package:flutter/material.dart';

class RadioWithFollowUpController<T> {
  T? _current;
  T? get value => _current;
  void forceSet(T? value) {
    _current = value;
    if (_state != null) {
      _state!._checkShowFollowUp();
      _state!._forceRefresh();
    }
  }

  RadioWithFollowUpController({T? initialValue}) : _current = initialValue;

  _RadioWithFollowUpState<T>? _state;
  void _attach(_RadioWithFollowUpState<T> state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }
}

class RadioWithFollowUp<T> extends StatefulWidget {
  const RadioWithFollowUp({
    super.key,
    this.title,
    this.titleStyle,
    this.initialValue,
    this.controller,
    required this.elements,
    this.elementsThatShowChild,
    this.followUpChild,
    this.onChanged,
    this.enabled = true,
  });

  final String? title;
  final TextStyle? titleStyle;
  final T? initialValue;
  final RadioWithFollowUpController<T>? controller;
  final List<T> elements;
  final List<T>? elementsThatShowChild;
  final Widget? followUpChild;
  final Function(T? values)? onChanged;
  final bool enabled;

  @override
  State<RadioWithFollowUp<T>> createState() => _RadioWithFollowUpState<T>();
}

class _RadioWithFollowUpState<T> extends State<RadioWithFollowUp<T>> {
  late final RadioWithFollowUpController<T> _controller;

  bool _hasFollowUp = false;
  bool get _showFollowUp => widget.followUpChild != null && _hasFollowUp;

  @override
  void initState() {
    super.initState();

    if (widget.controller != null && widget.initialValue != null) {
      throw ArgumentError(
        'Cannot provide both a controller and an initial value',
      );
    } else if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = RadioWithFollowUpController<T>(
        initialValue: widget.initialValue,
      );
    }

    _controller._attach(this);

    _checkShowFollowUp();
  }

  void _checkShowFollowUp() {
    _hasFollowUp =
        widget.elementsThatShowChild?.contains(_controller.value) ?? false;
  }

  void _forceRefresh() {
    setState(() {});
  }

  @override
  void dispose() {
    _controller._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RadioGroup(
          groupValue: _controller.value,
          onChanged: (newValue) {
            _controller.forceSet(newValue);
            if (widget.onChanged != null) widget.onChanged!(_controller.value);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title != null)
                Text(
                  widget.title!,
                  style:
                      widget.titleStyle ??
                      Theme.of(context).textTheme.titleSmall,
                ),
              ...widget.elements.map((element) => _buildElementTile(element)),
            ],
          ),
        ),
        if (_showFollowUp) widget.followUpChild!,
      ],
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
