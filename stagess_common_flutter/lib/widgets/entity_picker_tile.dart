import 'package:flutter/material.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/widgets/autocomplete_options_builder.dart';

class EntityPickerController {
  TextEditingController? _textController;
  // Allows to listen to changes to the _textController
  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _textController?.removeListener(listener);
    _listeners.remove(listener);
  }

  final String allElementsTitle;
  final Map<String, String> _allElements = {};

  String? _selection;
  String? get selection => _selection;
  String? get selectionId =>
      _allElements.entries.firstWhereOrNull((e) => e.value == _selection)?.key;
  set selection(String? value) {
    _selection = value;
    _textController?.text = value ?? '';
    _formKey.currentState?.didChange(value);
  }

  EntityPickerController({
    required this.allElementsTitle,
    required String? initialId,
    required List<School> schools,
    required List<Teacher> teachers,
  }) {
    _allElements.addAll(schools.asMap().map((_, v) => MapEntry(v.id, v.name)));
    _allElements.addAll(
      teachers.asMap().map((k, v) => MapEntry(v.id, v.fullName)),
    );
    _selection = _allElements[initialId] ?? allElementsTitle;
  }

  final _formKey = GlobalKey<FormFieldState<String>>();

  void dispose() {
    // Since _textController is managed by the FormField, we don't need to
    // dispose of it here.
  }
}

class EntityPickerTile extends StatelessWidget {
  const EntityPickerTile({
    super.key,
    this.title,
    required this.controller,
    required this.editMode,
  });

  final String? title;
  final EntityPickerController controller;
  final bool editMode;

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: controller._formKey,
      initialValue: controller._selection,
      builder: (field) => _builder(context, field),
      enabled: editMode,
    );
  }

  Widget _builder(BuildContext context, FormFieldState<String> state) {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller._selection ?? ''),
      optionsBuilder: (textEditingValue) {
        controller._selection =
            textEditingValue.text.isEmpty ? null : textEditingValue.text;

        // We show everything if there is no text. Otherwise, we show only if
        // the names containing that approach the text.
        if (textEditingValue.text.isEmpty) {
          return [
            controller.allElementsTitle,
            ...controller._allElements.values,
          ];
        }
        return controller._allElements.values.where(
          (e) =>
              e.toLowerCase().contains(textEditingValue.text.toLowerCase()) &&
              e.toLowerCase() != textEditingValue.text.toLowerCase(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) =>
          OptionsBuilderForAutocomplete(
        onSelected: onSelected,
        options: options,
        optionToString: (String e) => e,
      ),
      onSelected: (item) => controller.selection = item.isEmpty ? null : item,
      fieldViewBuilder: (_, textController, focusNode, onSubmitted) {
        controller._textController = textController;
        for (final listener in controller._listeners) {
          textController.addListener(listener);
        }

        return TextField(
          controller: controller._textController,
          focusNode: focusNode,
          readOnly: false,
          enabled: editMode,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            labelText: title ?? 'Sélectionner dans la liste',
            labelStyle: const TextStyle(color: Colors.black),
            errorText: state.errorText,
            suffixIcon: editMode
                ? IconButton(
                    onPressed: () {
                      if (focusNode.hasFocus) focusNode.previousFocus();
                      controller.selection = null;
                      textController.clear();
                      state.didChange(null);
                    },
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
        );
      },
    );
  }
}
