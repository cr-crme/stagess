import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stagess/router.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/widgets/autocomplete_options_builder.dart';

class SstSearchBar extends StatelessWidget {
  const SstSearchBar({super.key});

  static TextEditingValue textEditingValue = const TextEditingValue();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 50,
          height: 70,
          decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
              color: Theme.of(context).primaryColor),
        ),
        Container(
          decoration: BoxDecoration(
              border: Border.all(), borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
          child: const ListTile(
            title: _AutoCompleteSstSearchBar(),
          ),
        ),
      ],
    );
  }
}

class _AutoCompleteSstSearchBar extends StatefulWidget {
  const _AutoCompleteSstSearchBar();

  @override
  State<_AutoCompleteSstSearchBar> createState() =>
      _AutoCompleteSstSearchBarState();
}

class _AutoCompleteSstSearchBarState extends State<_AutoCompleteSstSearchBar> {
  TextEditingController? _textController;
  void _clearText(TextEditingController controller) => controller.text = '';

  Widget _fieldViewBuilder(
      BuildContext context,
      TextEditingController textEditingController,
      FocusNode focusNode,
      VoidCallback onFieldSubmitted) {
    _textController = textEditingController;
    return TextFormField(
      decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Colors.white),
          labelText: 'Rechercher un métier',
          suffixIcon: IconButton(
              onPressed: () => _clearText(textEditingController),
              icon: const Icon(Icons.clear))),
      controller: textEditingController,
      focusNode: focusNode,
      onFieldSubmitted: (String value) => onFieldSubmitted(),
    );
  }

  Iterable<String> _optionsBuilder(
      TextEditingValue value, List<Specialization> options) {
    if (value.text == '') return const Iterable<String>.empty();
    return options
        .map<String?>((e) {
          final textToSearch = value.text.toLowerCase().trim();
          return e.name.toLowerCase().contains(textToSearch) ||
                  e.id.contains(value.text) ||
                  e.idWithName.toLowerCase().contains(textToSearch)
              ? e.idWithName
              : null;
        })
        .where((e) => e != null)
        .cast<String>();
  }

  List<Specialization> _evaluatedSpecializations() {
    List<Specialization> out = [];
    for (final sector in ActivitySectorsService.activitySectors) {
      for (final specialization in sector.specializations) {
        // If there is no risk, it does not mean this specialization
        // is risk-free, it means it was not evaluated
        var hasRisks = false;
        for (final skill in specialization.skills) {
          hasRisks = skill.risks.isNotEmpty;
          if (hasRisks) break;
        }
        if (hasRisks) out.add(specialization);
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final options = _evaluatedSpecializations();
    options
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Autocomplete<String>(
      fieldViewBuilder: _fieldViewBuilder,
      optionsBuilder: (value) => _optionsBuilder(value, options),
      optionsViewBuilder: (context, onSelected, options) =>
          OptionsBuilderForAutocomplete(
        onSelected: onSelected,
        options: options,
        optionToString: (String e) => e,
      ),
      onSelected: (choice) {
        FocusManager.instance.primaryFocus?.unfocus();
        goTo(context, choice, options);
      },
    );
  }

  void goTo(BuildContext context, String choice, List<Specialization> options) {
    final index = options.indexWhere((e) => e.idWithName == choice);

    if (_textController != null) _clearText(_textController!);
    GoRouter.of(context).goNamed(Screens.jobSst,
        pathParameters: Screens.params(options[index].id));
  }
}
