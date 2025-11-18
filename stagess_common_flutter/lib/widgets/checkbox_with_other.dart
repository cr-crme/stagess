import 'package:flutter/material.dart';
import 'package:stagess_common/utils.dart';

class CheckboxWithOtherController<T> {
  final List<T> elements;
  final bool hasNotApplicableOption;

  final Map<T, bool> _elementValues = {};
  bool _isNotApplicable = false;
  bool get isNotApplicable => _isNotApplicable;

  bool _hasOther = false;
  bool get hasOther => _hasOther;
  final _otherTextController = TextEditingController();
  String get otherText => _otherTextController.text;

  bool _hasFollowUp = false;
  bool get hasFollowUp => _hasFollowUp;

  ///
  /// This returns all the selected elements except for everything related to
  /// others
  List<T> get selected {
    final List<T> out = [];
    for (final e in _elementValues.keys) {
      if (_elementValues[e]!) {
        out.add(e);
      }
    }
    return out;
  }

  CheckboxWithOtherController({
    required this.elements,
    this.hasNotApplicableOption = false,
    List<String>? initialValues,
  }) {
    // Initialize all elements from the initial value
    for (final e in elements) {
      _elementValues[e] = initialValues?.contains(e.toString()) ?? false;
    }

    // But initial values may contains "other" element which must be parsed too
    if (hasNotApplicableOption &&
        initialValues != null &&
        initialValues.length == 1 &&
        initialValues[0] == CheckboxWithOther.notApplicableTag) {
      _isNotApplicable = true;
      return;
    }

    if (initialValues != null) {
      final elementsAsString = elements.map((e) => e.toString());
      for (final initial in initialValues) {
        if (initial.isNotEmpty && !elementsAsString.contains(initial)) {
          _hasOther = true;
          _otherTextController.text = _otherTextController.text.isEmpty
              ? initial
              : '${_otherTextController.text}\n$initial';
        }
      }
    }
  }

  ///
  /// This returns all the element in the form of a list of String
  List<String> get values {
    if (_isNotApplicable) return [CheckboxWithOther.notApplicableTag];

    final List<String> out = [];

    for (final e in _elementValues.keys) {
      if (_elementValues[e]!) {
        out.add(e.toString());
      }
    }
    if (_hasOther && _otherTextController.text.isNotEmpty) {
      out.add(_otherTextController.text);
    }
    return out;
  }

  void forceSetIfDifferent({required CheckboxWithOtherController comparator}) {
    if (areListsNotEqual(values, comparator.values)) {
      for (var element in elements) {
        _forceSet(element, comparator.selected.contains(element));
      }
      if (hasNotApplicableOption) {
        _forceSetIsNotApplicable(comparator.isNotApplicable);
      }
      _forceSetOther(comparator.hasOther);
      if (hasOther) {
        _forceSetOtherText(comparator.otherText);
      }
    }
  }

  void _forceSet(T element, bool value) {
    if (!_elementValues.containsKey(element)) {
      throw ArgumentError('Element $element is not part of the options');
    }

    _elementValues[element] = value;
    if (_state != null) {
      _state!._checkForShowingChild();
      _state!._forceRefresh();
    }
  }

  void _forceSetIsNotApplicable(bool value) {
    if (!hasNotApplicableOption) {
      throw Exception(
        'This controller does not have a "not applicable" option',
      );
    }
    _isNotApplicable = value;
    if (_isNotApplicable) {
      for (final e in _elementValues.keys) {
        _elementValues[e] = false;
      }
      _hasOther = false;
      _otherTextController.text = '';
      if (_state != null) _state!._checkForShowingChild();
    }
    if (_state != null) _state!._forceRefresh();
  }

  void _forceSetOther(bool value) {
    _hasOther = value;
    if (_state != null) {
      _state!._checkForShowingChild();
      _state!._forceRefresh();
    }
  }

  void _forceSetOtherText(String text) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // We must delay the update of the text controller to avoid a setState() issue
      _otherTextController.text = text;
      if (_state != null) {
        _state!._checkForShowingChild();
        _state!._forceRefresh();
      }
    });
  }

  _CheckboxWithOtherState<T>? _state;
  void _attach(_CheckboxWithOtherState<T> state) {
    if (_state != null) {
      throw Exception('A controller can only be attached to one widget');
    }
    _state = state;
  }

  void _detach() {
    _state = null;
  }
}

class CheckboxWithOther<T> extends StatefulWidget {
  static const notApplicableTag = '__NOT_APPLICABLE_INTERNAL__';

  const CheckboxWithOther({
    super.key,
    required this.controller,
    this.title,
    this.titleStyle,
    this.elementStyleBuilder,
    this.subWidgetBuilder,
    this.showOtherOption = true,
    this.errorMessageOther = 'Préciser au moins un élément',
    this.onOptionSelected,
    this.followUpChild,
    this.enabled = true,
  });

  final CheckboxWithOtherController<T> controller;
  final String? title;
  final TextStyle? titleStyle;
  final TextStyle Function(T element, bool isSelected)? elementStyleBuilder;
  final Widget Function(T element, bool isSelected)? subWidgetBuilder;
  final bool showOtherOption;
  final String errorMessageOther;
  final Function(List<String>)? onOptionSelected;
  final Widget? followUpChild;
  final bool enabled;

  @override
  State<CheckboxWithOther<T>> createState() => _CheckboxWithOtherState<T>();
}

class _CheckboxWithOtherState<T> extends State<CheckboxWithOther<T>> {
  bool get _showFollowUp =>
      widget.followUpChild != null && widget.controller._hasFollowUp;

  void _checkForShowingChild() {
    widget.controller._hasFollowUp =
        widget.controller._elementValues.values.any((e) => e) ||
            widget.controller._hasOther;
  }

  @override
  void initState() {
    super.initState();
    _checkForShowingChild();

    widget.controller._attach(this);
  }

  void _forceRefresh() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller._detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: widget.titleStyle ?? Theme.of(context).textTheme.titleSmall,
          ),
        ...widget.controller._elementValues.keys.map(
          (element) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                visualDensity: VisualDensity.compact,
                dense: true,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  element.toString(),
                  style: widget.elementStyleBuilder == null
                      ? Theme.of(context).textTheme.bodyMedium
                      : widget.elementStyleBuilder!(
                          element,
                          widget.controller._elementValues[element]!,
                        ),
                ),
                enabled: widget.enabled && !widget.controller._isNotApplicable,
                value: widget.controller._elementValues[element]!,
                onChanged: (newValue) {
                  widget.controller._forceSet(element, newValue!);
                  if (widget.onOptionSelected != null) {
                    widget.onOptionSelected!(widget.controller.values);
                  }
                },
              ),
              if (widget.subWidgetBuilder != null)
                widget.subWidgetBuilder!(
                  element,
                  widget.controller._elementValues[element]!,
                ),
            ],
          ),
        ),
        if (widget.controller.hasNotApplicableOption)
          CheckboxListTile(
            visualDensity: VisualDensity.compact,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(
              'Ne s\'applique pas',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            enabled: widget.enabled,
            value: widget.controller._isNotApplicable,
            onChanged: (newValue) {
              widget.controller._forceSetIsNotApplicable(newValue!);
              if (widget.onOptionSelected != null) {
                widget.onOptionSelected!(widget.controller.values);
              }
            },
          ),
        if (widget.showOtherOption)
          CheckboxListTile(
            visualDensity: VisualDensity.compact,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text('Autre', style: Theme.of(context).textTheme.bodyMedium),
            value: widget.controller._hasOther,
            enabled: widget.enabled && !widget.controller._isNotApplicable,
            onChanged: (newValue) {
              widget.controller._forceSetOther(newValue!);
              if (widget.onOptionSelected != null) {
                widget.onOptionSelected!(widget.controller.values);
              }
            },
          ),
        Visibility(
          visible: widget.controller._hasOther,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Préciser\u00a0:',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                TextFormField(
                  controller: widget.controller._otherTextController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: null,
                  style: Theme.of(context).textTheme.bodyMedium,
                  keyboardType: TextInputType.multiline,
                  onChanged: (text) {
                    if (widget.onOptionSelected != null) {
                      widget.onOptionSelected!(widget.controller.values);
                    }
                  },
                  enabled: widget.enabled,
                  validator: (value) => widget.controller._hasOther &&
                          (value == null ||
                              !RegExp('[a-zA-Z0-9]').hasMatch(value))
                      ? widget.errorMessageOther
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (_showFollowUp && widget.showOtherOption) const SizedBox(height: 12),
        if (_showFollowUp) widget.followUpChild!,
      ],
    );
  }
}
