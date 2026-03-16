import 'package:flutter/material.dart';
import 'package:stagess_common/models/generic/selectable_text_items.dart';

export 'package:stagess_common/models/generic/selectable_text_items.dart';

class SelectableTextItemsController {
  final List<SelectableTextItem> _options;
  final List<TextEditingController> _optionControllers;

  SelectableTextItemsController({
    List<SelectableTextItem>? options,
  })  : _options = options ?? [],
        _optionControllers = (options ?? [])
            .map((option) => TextEditingController(text: option.text))
            .toList();

  List<SelectableTextItem> get options =>
      List.unmodifiable(_options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        return option.copyWith(text: _optionControllers[index].text);
      }));

  int get length => _options.length;
  int get selectedCount =>
      _options.fold(0, (count, option) => count + (option.isSelected ? 1 : 0));

  void clear() {
    final elementCount = _optionControllers.length;
    for (int i = 0; i < elementCount; i++) {
      remove(0);
    }

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void add(SelectableTextItem item) => insert(_options.length, item);

  void unselectAll() {
    for (int i = 0; i < _options.length; i++) {
      if (_options[i].isSelected) {
        _options[i] = _options[i].copyWith(isSelected: false);
      }
    }

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void insert(int index, SelectableTextItem item) {
    if (index < 0) return;
    if (index > _options.length) index = _options.length;

    _options.insert(index, item);
    _optionControllers.insert(index, TextEditingController(text: item.text));
    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void remove(int index) {
    if (index < 0 || index >= length) return;

    _options.removeAt(index);
    _optionControllers[index].dispose();
    _optionControllers.removeAt(index);

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void updateOption(int index, SelectableTextItem newValue) {
    if (index < 0 || index >= _options.length) return;
    _options[index] = newValue;

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  Function(VoidCallback)? _setStateCallback;

  void dispose() {
    _setStateCallback = null;
    clear();
  }
}

class SelectableTextBoxes extends StatefulWidget {
  const SelectableTextBoxes({
    super.key,
    required this.controller,
    this.enabled = true,
    this.maxOptions,
    this.maxSelectedOptions,
    required this.newItemBuilder,
  });

  final SelectableTextItemsController? controller;
  final bool enabled;
  final int? maxOptions;
  final int? maxSelectedOptions;
  final SelectableTextItem Function(int index) newItemBuilder;

  @override
  State<SelectableTextBoxes> createState() => _SelectableTextBoxesState();
}

class _SelectableTextBoxesState extends State<SelectableTextBoxes> {
  late final _shouldDisposeController = widget.controller == null;
  late final SelectableTextItemsController _controller =
      widget.controller ?? SelectableTextItemsController();

  @override
  void initState() {
    super.initState();
    _controller._setStateCallback = setState;
    if (_controller.options.isEmpty) {
      _controller.insert(0, widget.newItemBuilder(0));
    }
  }

  @override
  void dispose() {
    if (_shouldDisposeController) _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _controller.options.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0.0 : 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: _controller.options[i].isSelected,
                  onChanged: widget.enabled &&
                          (widget.maxSelectedOptions == null ||
                              _controller.options[i].isSelected ||
                              _controller.selectedCount <
                                  widget.maxSelectedOptions!)
                      ? (value) => _controller.updateOption(i,
                          _controller.options[i].copyWith(isSelected: value!))
                      : null,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextFormField(
                    controller: _controller._optionControllers[i],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    ),
                    enabled: widget.enabled,
                    maxLength: 100,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.black),
                    onEditingComplete: () => _controller.updateOption(
                        i,
                        _controller.options[i].copyWith(
                            text: _controller._optionControllers[i].text)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: widget.enabled &&
                              (widget.maxOptions == null ||
                                  _controller.options.length <
                                      widget.maxOptions!)
                          ? () => _controller.insert(
                                i + 1,
                                widget.newItemBuilder(i),
                              )
                          : null,
                      borderRadius: BorderRadius.circular(25.0),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.add,
                          color: widget.enabled &&
                                  (widget.maxOptions == null ||
                                      _controller.options.length <
                                          widget.maxOptions!)
                              ? Colors.green
                              : Colors.grey,
                          size: 28,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: InkWell(
                        onTap: widget.enabled && _controller.options.length > 1
                            ? () => _controller.remove(i)
                            : null,
                        borderRadius: BorderRadius.circular(25.0),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.remove,
                            color:
                                widget.enabled && _controller.options.length > 1
                                    ? Colors.red
                                    : Colors.grey,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
