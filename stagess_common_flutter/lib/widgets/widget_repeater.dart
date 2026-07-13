import 'package:flutter/material.dart';
import 'package:stagess_common/models/generic/repeatable_items.dart';

export 'package:stagess_common/models/generic/repeatable_items.dart';

class WidgetRepeaterController<T extends RepeatableItem> {
  final List<T> _options;

  WidgetRepeaterController({
    List<T>? options,
  }) : _options = options ?? [];

  List<T> get options => List.unmodifiable(_options);

  int get length => _options.length;
  int get selectedCount =>
      _options.fold(0, (count, option) => count + (option.isSelected ? 1 : 0));

  void clear() {
    final elementCount = _options.length;
    for (int i = 0; i < elementCount; i++) {
      remove(0);
    }

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void add(T item) {
    insert(_options.length, item);
  }

  void unselectAll() {
    for (int i = 0; i < _options.length; i++) {
      if (_options[i].isSelected) {
        _options[i] = _options[i].copyWith(isSelected: false) as T;
      }
    }

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void insert(int index, T item) {
    if (index < 0) return;
    if (index > _options.length) index = _options.length;

    _options.insert(index, item);

    // Update indices of subsequent items
    for (int i = index + 1; i < _options.length; i++) {
      _options[i] = _options[i].copyWith(index: i) as T;
    }

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void remove(int index) {
    if (index < 0 || index >= length) return;

    _options.removeAt(index);

    // Update indices of subsequent items
    for (int i = index; i < _options.length; i++) {
      _options[i] = _options[i].copyWith(index: i) as T;
    }

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void updateOption(int index, T newValue) {
    if (index < 0 || index >= _options.length) return;
    _options[index] = newValue.copyWith(index: index) as T;

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  Function(VoidCallback)? _setStateCallback;

  void dispose() {
    _setStateCallback = null;
    clear();
  }
}

class TextFormRepeater<T extends RepeatableItem> extends StatelessWidget {
  const TextFormRepeater({
    super.key,
    required this.controller,
    this.enabled = true,
    this.minOptionCount = 1,
    this.maxOptionCount,
    this.maxSelectedOptions,
    required this.newItemBuilder,
    required this.updateItemBuilder,
    required this.itemToText,
    this.hasCheckboxes = true,
    this.maxLength,
    this.maxLines = 5,
  });

  final WidgetRepeaterController<T>? controller;
  final bool enabled;
  final int minOptionCount;
  final int? maxOptionCount;
  final int? maxSelectedOptions;
  final T Function(int index) newItemBuilder;
  final T Function(T item, String text) updateItemBuilder;
  final String Function(T item) itemToText;
  final bool hasCheckboxes;
  final int? maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return WidgetRepeater<T>(
      controller: controller,
      enabled: enabled,
      hasCheckboxes: hasCheckboxes,
      minOptionCount: minOptionCount,
      maxOptionCount: maxOptionCount,
      maxSelectedOptions: maxSelectedOptions,
      newItemBuilder: newItemBuilder,
      widgetBuilder: (context, index, item, onUpdated) {
        return Expanded(
          child: TextFormField(
            key: ValueKey(item.id),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            ),
            initialValue: itemToText(item),
            enabled: enabled,
            maxLength: maxLength,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) => onUpdated(updateItemBuilder(item, value)),
          ),
        );
      },
    );
  }
}

class WidgetRepeater<T extends RepeatableItem> extends StatefulWidget {
  const WidgetRepeater({
    super.key,
    this.controller,
    this.enabled = true,
    this.minOptionCount = 1,
    this.maxOptionCount,
    this.maxSelectedOptions,
    required this.newItemBuilder,
    required this.widgetBuilder,
    this.hasCheckboxes = true,
  });

  final WidgetRepeaterController<T>? controller;
  final bool enabled;
  final int minOptionCount;
  final int? maxOptionCount;
  final int? maxSelectedOptions;
  final T Function(int index) newItemBuilder;
  final Widget Function(BuildContext context, int index, T item,
      void Function(T newItem) updateItem) widgetBuilder;
  final bool hasCheckboxes;

  @override
  State<WidgetRepeater<T>> createState() => _WidgetRepeaterState<T>();
}

class _WidgetRepeaterState<T extends RepeatableItem>
    extends State<WidgetRepeater<T>> {
  late final _shouldDisposeController = widget.controller == null;
  late final WidgetRepeaterController<T> _controller =
      widget.controller ?? WidgetRepeaterController<T>();

  @override
  void initState() {
    super.initState();
    _controller._setStateCallback = setState;
    for (int i = _controller.options.length; i < widget.minOptionCount; i++) {
      _insertNewItem(i);
    }
  }

  @override
  void dispose() {
    if (_shouldDisposeController) _controller.dispose();

    super.dispose();
  }

  void _insertNewItem(int index) {
    _controller.insert(index, widget.newItemBuilder(index));
  }

  void _removeItem(int index) {
    _controller.remove(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_controller.options.isEmpty && widget.enabled)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: TextButton(
              onPressed: widget.enabled ? () => _insertNewItem(0) : null,
              child: const Text('Ajouter un premier élément'),
            ),
          ),
        for (int i = 0; i < _controller.options.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0.0 : 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.hasCheckboxes)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _controller.options[i].isSelected,
                        onChanged: widget.enabled &&
                                (widget.maxSelectedOptions == null ||
                                    _controller.options[i].isSelected ||
                                    _controller.selectedCount <
                                        widget.maxSelectedOptions!)
                            ? (value) => _controller.updateOption(
                                i,
                                _controller.options[i]
                                    .copyWith(isSelected: value!) as T)
                            : null,
                      ),
                      const SizedBox(width: 8.0),
                    ],
                  ),
                widget.widgetBuilder(
                  context,
                  i,
                  _controller.options[i],
                  (newItem) {
                    _controller.updateOption(i, newItem);
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: widget.enabled &&
                              (widget.maxOptionCount == null ||
                                  _controller.options.length <
                                      widget.maxOptionCount!)
                          ? () => _insertNewItem(i + 1)
                          : null,
                      borderRadius: BorderRadius.circular(25.0),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.add,
                          color: widget.enabled &&
                                  (widget.maxOptionCount == null ||
                                      _controller.options.length <
                                          widget.maxOptionCount!)
                              ? Colors.green
                              : Colors.grey,
                          size: 28,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: InkWell(
                        onTap: widget.enabled &&
                                _controller.options.length >
                                    widget.minOptionCount
                            ? () => _removeItem(i)
                            : null,
                        borderRadius: BorderRadius.circular(25.0),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.remove,
                            color: widget.enabled &&
                                    _controller.options.length >
                                        widget.minOptionCount
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
