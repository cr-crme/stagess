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

    _options[index].dispose();
    _options.removeAt(index);

    // Update indices of subsequent items
    for (int i = index; i < _options.length; i++) {
      _options[i] = _options[i].copyWith(index: i) as T;
    }

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _options.length ||
        newIndex < 0 ||
        newIndex >= _options.length) {
      return;
    }

    final item = _options.removeAt(oldIndex);
    _options.insert(newIndex, item);

    // Update indices of all items
    for (int i = 0; i < _options.length; i++) {
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
    this.minOptionCount = 0,
    this.maxOptionCount,
    this.maxSelectedOptions,
    required this.newItemBuilder,
    required this.updateItemBuilder,
    required this.itemToText,
    this.hasCheckboxes = true,
    this.canReorder = true,
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
  final bool canReorder;
  final int? maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return WidgetRepeater<T>(
      controller: controller,
      enabled: enabled,
      hasCheckboxes: hasCheckboxes,
      canReorder: canReorder,
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
    this.minOptionCount = 0,
    this.maxOptionCount,
    this.maxSelectedOptions,
    required this.newItemBuilder,
    required this.widgetBuilder,
    this.buttonTitle = 'Ajouter un élément',
    this.hasCheckboxes = true,
    this.canReorder = true,
  });

  final WidgetRepeaterController<T>? controller;
  final bool enabled;
  final int minOptionCount;
  final int? maxOptionCount;
  final int? maxSelectedOptions;
  final T Function(int index) newItemBuilder;
  final Widget Function(BuildContext context, int index, T item,
      void Function(T newItem) updateItem) widgetBuilder;
  final String buttonTitle;
  final bool hasCheckboxes;
  final bool canReorder;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReorderableListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            itemCount: _controller.options.length,
            onReorderItem: (oldIndex, newIndex) => setState(() {
              _controller.reorder(oldIndex, newIndex);
            }),
            itemBuilder: (context, i) => _buildTile(i),
          ),
          if (widget.enabled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: TextButton(
                onPressed: widget.enabled
                    ? () => _insertNewItem(_controller.options.length)
                    : null,
                child: Text(widget.buttonTitle),
              ),
            ),
        ]);
  }

  Padding _buildTile(int i) {
    return Padding(
      key: ValueKey(_controller.options[i].id),
      padding: EdgeInsets.only(top: i == 0 ? 0.0 : 12.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.canReorder)
            ReorderableDragStartListener(
              index: i,
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(25.0),
                child: Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Icon(
                    Icons.drag_handle,
                    color: widget.enabled
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                    size: 28.0,
                  ),
                ),
              ),
            ),
          if (widget.hasCheckboxes)
            Checkbox(
              value: _controller.options[i].isSelected,
              onChanged: widget.enabled &&
                      (widget.maxSelectedOptions == null ||
                          _controller.options[i].isSelected ||
                          _controller.selectedCount <
                              widget.maxSelectedOptions!)
                  ? (value) => _controller.updateOption(i,
                      _controller.options[i].copyWith(isSelected: value!) as T)
                  : null,
            ),
          if (widget.canReorder || widget.hasCheckboxes)
            const SizedBox(width: 8.0),
          widget.widgetBuilder(context, i, _controller.options[i], (newItem) {
            _controller.updateOption(i, newItem);
          }),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: InkWell(
              onTap: widget.enabled &&
                      _controller.options.length > widget.minOptionCount
                  ? () => _removeItem(i)
                  : null,
              borderRadius: BorderRadius.circular(25.0),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(Icons.delete,
                    color: widget.enabled &&
                            _controller.options.length > widget.minOptionCount
                        ? Colors.red
                        : Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
