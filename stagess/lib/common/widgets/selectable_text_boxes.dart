import 'package:flutter/material.dart';

class SelectableTextBoxesController {
  final List<TextEditingController> _options;
  final List<bool> _selectedOptions;

  SelectableTextBoxesController({
    Map<String, bool>? options,
  })  : _options = (options ?? {})
            .keys
            .map((option) => TextEditingController(text: option))
            .toList(),
        _selectedOptions = (options ?? {}).values.toList();

  List<MapEntry<String, bool>> get options => List.generate(_options.length,
      (index) => MapEntry(_options[index].text, _selectedOptions[index]));

  void clear() {
    for (final controller in _options) {
      controller.dispose();
    }
    _options.clear();
    _selectedOptions.clear();
    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void insert(int index, {String value = '', bool isSelected = false}) {
    if (index < 0) return;
    if (index > _options.length) index = _options.length;

    _options.insert(index, TextEditingController(text: value));
    _selectedOptions.insert(index, isSelected);
    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void remove(int index) {
    if (index < 0 || index >= _options.length) return;
    _options[index].dispose();

    _options.removeAt(index);
    _selectedOptions.removeAt(index);

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void _toggleOption(int index) {
    _selectedOptions[index] = !_selectedOptions[index];

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  void _updateOption(int index, String newValue) {
    if (index < 0 || index >= _options.length) return;
    _options[index].text = newValue;

    if (_setStateCallback != null) _setStateCallback!(() {});
  }

  Function(VoidCallback)? _setStateCallback;

  void dispose() {
    _setStateCallback = null;
    clear();
  }
}

class SelectableTextBoxes extends StatefulWidget {
  const SelectableTextBoxes({super.key, required this.controller});

  final SelectableTextBoxesController? controller;

  @override
  State<SelectableTextBoxes> createState() => _SelectableTextBoxesState();
}

class _SelectableTextBoxesState extends State<SelectableTextBoxes> {
  late final _shouldDisposeController = widget.controller == null;
  late final SelectableTextBoxesController _controller =
      widget.controller ?? SelectableTextBoxesController(options: {});

  @override
  void initState() {
    super.initState();
    _controller._setStateCallback = setState;
    if (_controller.options.isEmpty) _controller.insert(0);
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
                  value: _controller._selectedOptions[i],
                  onChanged: (_) => _controller._toggleOption(i),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: TextFormField(
                    controller: _controller._options[i],
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                    ),
                    maxLength: 100,
                    maxLines: 5,
                    onEditingComplete: () => _controller._updateOption(
                        i, _controller._options[i].text),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () => _controller.insert(i + 1),
                      borderRadius: BorderRadius.circular(25.0),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.add,
                          color: Colors.green,
                          size: 28,
                        ),
                      ),
                    ),
                    Visibility(
                      visible: _controller.options.length > 1,
                      maintainSize: true,
                      maintainAnimation: true,
                      maintainState: true,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: InkWell(
                          onTap: () => _controller.remove(i),
                          borderRadius: BorderRadius.circular(25.0),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Icon(
                              Icons.remove,
                              color: Colors.red,
                              size: 28,
                            ),
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
