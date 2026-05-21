import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/autocomplete_options_builder.dart';
import 'package:stagess_common_flutter/widgets/checkbox_with_other.dart';
import 'package:stagess_common_flutter/widgets/entity_picker_tile.dart';
import 'package:stagess_common_flutter/widgets/incidents_expansion_panel.dart';
import 'package:stagess_common_flutter/widgets/jobs_expansion_panels/comments_expansion_panel.dart';
import 'package:stagess_common_flutter/widgets/jobs_expansion_panels/photo_expansion_panel.dart';
import 'package:stagess_common_flutter/widgets/jobs_expansion_panels/supervision_expansion_panel.dart';

class EnterpriseJobListController {
  BuildContext context;

  EnterpriseStatus enterpriseStatus;

  late Specialization? _specialization = _job.specializationOrNull;
  Specialization? get specialization => _specialization;

  final List<Specialization>? _specializationsWhiteList;
  final List<Specialization>? _specializationBlacklist;

  late final _minimumAgeController = TextEditingController(
    text: _job.minimumAge.toString(),
  );
  late final Map<String, int> _positionsOffered = _job.positionsOffered.map(
    (key, value) => MapEntry(key, value),
  );
  Map<String, int> get _realPositionsOffered {
    final statuses = enterpriseStatus == EnterpriseStatus.active
        ? _positionsOffered.map((key, value) => MapEntry(key, value))
        : _positionsOffered.map((key, value) => MapEntry(key, 0));

    if (_reservedForPickerController?.selection != null) {
      final schoolId = _reservedForSchoolId;
      if (schoolId != null) {
        for (final element in statuses.keys) {
          if (element != schoolId) {
            statuses[element] = 0;
          }
        }
      }
    }
    return statuses;
  }

  final Map<String, int> _positionsOccupied = {};
  Map<String, int> get positionsOccupied =>
      enterpriseStatus == EnterpriseStatus.active ? _positionsOccupied : {};

  late var _preInternshipRequests = _job.preInternshipRequests;

  final EntityPickerController? _reservedForPickerController;
  String? get _reservedForSchoolId =>
      context.mounted && _reservedForPickerController?.selectionId != null
          ? TeachersProvider.of(
              context,
              listen: false,
            ).fromIdOrNull(_reservedForPickerController!.selectionId!)?.schoolId
          : null;

  final Job _job;
  EnterpriseJobListController({
    required this.context,
    required this.enterpriseStatus,
    required Job? job,
    List<Specialization>? specializationWhiteList,
    List<Specialization>? specializationBlackList,
    EntityPickerController? reservedForPickerController,
  })  : _job = job?.copyWith() ?? Job.empty,
        _specializationsWhiteList = specializationWhiteList,
        _specializationBlacklist = specializationBlackList,
        _reservedForPickerController = reservedForPickerController {
    final students = StudentsProvider.of(context, listen: false);
    final internships = InternshipsProvider.of(context, listen: false);

    _positionsOccupied.clear();
    for (final intership in internships) {
      if (intership.currentContract?.jobId == _job.id && intership.isActive) {
        final schoolId = students
            .firstWhereOrNull(
              (student) => student.id == intership.studentId,
            )
            ?.schoolId;
        if (schoolId == null) continue;

        _positionsOccupied[schoolId] = (_positionsOccupied[schoolId] ?? 0) + 1;
      }
    }
  }

  Job get job => _job.copyWith(
        specialization: _specialization,
        minimumAge: int.tryParse(_minimumAgeController.text),
        positionsOffered: _realPositionsOffered,
        preInternshipRequests: _preInternshipRequests,
        reservedForId: _reservedForPickerController == null
            ? _job.reservedForId
            : (_reservedForPickerController?.selectionId ?? ''),
      );

  void dispose() {
    _minimumAgeController.dispose();
  }
}

class EnterpriseJobListTile extends StatefulWidget {
  const EnterpriseJobListTile({
    super.key,
    required this.controller,
    required this.schools,
    this.editMode = false,
    this.onRequestDelete,
    this.canChangeExpandedState = true,
    this.initialExpandedState = false,
    this.elevation = 10.0,
    this.specializationOnly = false,
    this.showHeader = true,
    this.jobPickerPadding,
    this.availabilityIsMandatory = false,
    this.showExtended = false,
    this.addSstEvent,
    this.addComment,
    this.removeImage,
  });

  final EnterpriseJobListController controller;
  final List<School>? schools;
  final bool editMode;
  final Function()? onRequestDelete;
  final bool canChangeExpandedState;
  final bool initialExpandedState;
  final double elevation;
  final bool specializationOnly;
  final bool showHeader;
  final EdgeInsets? jobPickerPadding;
  final bool availabilityIsMandatory;
  final bool showExtended;
  final void Function(Job job)? addSstEvent;
  final void Function(Job job)? addComment;
  final void Function(Job job, int index)? removeImage;

  @override
  State<EnterpriseJobListTile> createState() => _EnterpriseJobListTileState();
}

class _EnterpriseJobListTileState extends State<EnterpriseJobListTile> {
  Job get job => widget.controller.job;

  @override
  void initState() {
    super.initState();
    widget.controller._reservedForPickerController?.addListener(_refresh);

    {
      if (widget.showExtended && widget.addSstEvent == null) {
        throw ArgumentError(
            'addSstEvent must be provided if showExtended is true');
      }
      if (widget.showExtended && widget.addComment == null) {
        throw ArgumentError(
            'addComment must be provided if showExtended is true');
      }
    }
  }

  void _refresh() => setState(() {});

  void _updatePositions(String schoolId, int newCount) {
    setState(() => widget.controller._positionsOffered[schoolId] = newCount);
  }

  @override
  void dispose() {
    widget.controller._reservedForPickerController?.removeListener(_refresh);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant EnterpriseJobListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    _preInternshipRequestsController.forceSetIfDifferent(
      comparator: CheckboxWithOtherController(
        elements: PreInternshipRequestTypes.values,
        initialValues: [
          ...job.preInternshipRequests.requests.map((e) => e.toString()),
          job.preInternshipRequests.other ?? '',
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = AuthProvider.of(context, listen: false);

    final schools = widget.schools?.where(
          (school) =>
              (authProvider.databaseAccessLevel <
                      AccessLevel.schoolBoardAdmin &&
                  school.id == authProvider.schoolId) &&
              (widget.controller._reservedForSchoolId == null ||
                  widget.controller._reservedForSchoolId == school.id),
        ) ??
        [];

    return AnimatedExpandingCard(
      elevation: widget.elevation,
      canChangeExpandedState: widget.canChangeExpandedState,
      initialExpandedState: widget.initialExpandedState,
      header: (ctx, isExpanded) => widget.showHeader
          ? Padding(
              padding: const EdgeInsets.only(left: 12.0, top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          widget.controller._specialization?.idWithName ??
                              'Aucun métier sélectionné',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (widget.editMode && widget.onRequestDelete != null)
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: widget.onRequestDelete,
                        ),
                    ],
                  ),
                  SizedBox(height: 4.0),
                  if (widget.controller._reservedForPickerController != null)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: widget.editMode ? 20 : 12,
                      ),
                      child: _buildReservedFor(),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    widget.editMode
                        ? '* Indiquer le nombre de places de stages disponibles :'
                        : 'Nombre de places de stages disponibles :',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  ...schools.map(
                    (school) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 2.0,
                      ),
                      child: _buildAvailability(school: school),
                    ),
                  ),
                  if (widget.canChangeExpandedState) const SizedBox(height: 8),
                ],
              ),
            )
          : const SizedBox.shrink(),
      child: Padding(
        padding: widget.jobPickerPadding ??
            const EdgeInsets.only(left: 24.0, top: 12.0, right: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildJobPicker(),
            ),
            if (!widget.specializationOnly)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMinimumAge(),
                  const SizedBox(height: 8),
                  if (!widget.showHeader)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.editMode
                              ? '* Indiquer le nombre de places de stages disponibles :'
                              : 'Nombre de places de stages disponibles :',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        ...schools.map(
                          (school) => _buildAvailability(school: school),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  _buildPrerequisites(),
                  if (widget.showExtended)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: AnimatedExpandingCard(
                          elevation: 0.0,
                          header: (context, isExpanded) => Text(
                              isExpanded
                                  ? 'Moins de détails sur le métier...'
                                  : 'Plus de détails sur le métier...',
                              style: Theme.of(context).textTheme.titleMedium),
                          child: _buildMoreDetails()),
                    ),
                  const SizedBox(height: 12),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Specialization> get _availableSpecialization {
    // Make a copy of the available specializations
    List<Specialization> out = [
      ...(widget.controller._specializationsWhiteList ??
          ActivitySectorsService.allSpecializations),
    ];
    out.sort((a, b) => a.name.compareTo(b.name)); // Sort them by name
    return out;
  }

  Autocomplete<Specialization> _buildJobPicker() {
    return Autocomplete<Specialization>(
      displayStringForOption: (specialization) => specialization.idWithName,
      optionsBuilder: (textEditingValue) => _availableSpecialization
          .where(
            (s) => s.idWithName.toLowerCase().contains(
                  textEditingValue.text.toLowerCase().trim(),
                ),
          )
          .toList(),
      optionsViewBuilder: (context, onSelected, options) =>
          OptionsBuilderForAutocomplete(
        onSelected: onSelected,
        options: options,
        optionToString: (Specialization e) => e.idWithName,
      ),
      onSelected: (specialization) {
        FocusManager.instance.primaryFocus?.unfocus();
        widget.controller._specialization = specialization;
        setState(() {});
      },
      initialValue: TextEditingValue(
        text: widget.controller._specialization?.idWithName ?? '',
      ),
      fieldViewBuilder: (_, controller, focusNode, onSubmitted) {
        if (_availableSpecialization.length == 1) {
          widget.controller._specialization = _availableSpecialization[0];
          controller.text = widget.controller._specialization!.idWithName;
        }
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          validator: (value) {
            if (widget.controller._specialization == null) {
              return 'Sélectionner un métier.';
            }
            if (widget.controller._specializationBlacklist?.contains(
                  widget.controller._specialization,
                ) ??
                false) {
              return 'Ce métier existe déjà pour cette entreprise.';
            }
            return null;
          },
          style: const TextStyle(color: Colors.black),
          enabled: widget.editMode && _availableSpecialization.length != 1,
          decoration: InputDecoration(
            labelText: '* Métier semi-spécialisé',
            labelStyle: TextStyle(color: Colors.black),
            hintText: 'Saisir nom ou n° de métier',
            suffixIcon: _availableSpecialization.length == 1
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      if (focusNode.hasFocus) focusNode.nextFocus();
                      widget.controller._specialization = null;
                      controller.clear();
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildMinimumAge() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            '* Âge minimum des stagiaires (ans)',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.24,
          child: TextFormField(
            controller: widget.controller._minimumAgeController,
            enabled: widget.editMode,
            validator: (value) {
              final current = int.tryParse(value!);
              if (current == null) return 'Préciser';
              if (current < 15 || current > 30) return 'Minimum 15 ans';
              return null;
            },
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: (widget.editMode ? null : TextStyle(color: Colors.black)),
          ),
        ),
      ],
    );
  }

  int _positionOffered(String schoolId) {
    return widget.controller._realPositionsOffered[schoolId] ?? 0;
  }

  int _positionOccupied(String schoolId) {
    return widget.controller.positionsOccupied[schoolId] ?? 0;
  }

  int _positionRemaining(String schoolId) =>
      _positionOffered(schoolId) - _positionOccupied(schoolId);

  Widget _buildAvailability({required School school}) {
    final positionsRemaining = _positionRemaining(school.id);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(
              width: widget.editMode ? 140 : 75,
              child: widget.editMode
                  ? FormField(
                      validator: (value) => widget.availabilityIsMandatory &&
                              _positionOffered(school.id) == 0
                          ? 'Ajouter au moins une place.'
                          : null,
                      builder: (state) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _positionOffered(school.id) == 0
                                    ? null
                                    : () => _updatePositions(
                                          school.id,
                                          _positionOffered(school.id) - 1,
                                        ),
                                icon: Icon(
                                  Icons.remove,
                                  color: _positionOffered(school.id) == 0
                                      ? Colors.grey
                                      : Colors.black,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '$positionsRemaining / ${_positionOffered(school.id)}',
                                ),
                              ),
                              IconButton(
                                onPressed: widget.controller.enterpriseStatus ==
                                        EnterpriseStatus.active
                                    ? () => _updatePositions(
                                          school.id,
                                          _positionOffered(school.id) + 1,
                                        )
                                    : null,
                                icon: Icon(
                                  Icons.add,
                                  color: widget.controller.enterpriseStatus ==
                                          EnterpriseStatus.active
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          if (state.hasError)
                            Text(
                              state.errorText!,
                              style: const TextStyle(color: Colors.red),
                            ),
                        ],
                      ),
                    )
                  : Text(
                      '$positionsRemaining / ${_positionOffered(school.id)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
            ),
            Text(school.name),
          ],
        ),
      ],
    );
  }

  late final _preInternshipRequestKey = ValueKey(
    '${job.id}_pre_internship_requests',
  );
  late final _preInternshipRequestsController = CheckboxWithOtherController(
    elements: PreInternshipRequestTypes.values,
    initialValues: [
      ...job.preInternshipRequests.requests.map((e) => e.toString()),
      job.preInternshipRequests.other ?? '',
    ],
  );

  Widget _buildPrerequisites() {
    return BuildPrerequisitesCheckboxes(
      checkboxKey: _preInternshipRequestKey,
      controller: _preInternshipRequestsController,
      enabled: widget.editMode,
      onChanged: (values) {
        widget.controller._preInternshipRequests =
            PreInternshipRequests.fromStrings(values,
                notApplicableTag: CheckboxWithOther.notApplicableTag);
      },
    );
  }

  Widget _buildReservedFor() {
    return Padding(
      padding: const EdgeInsets.only(right: 36.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.editMode
                ? 'Indiquer si les stages pour ce métier sont accessibles à tous les '
                    'enseignants ou s\'ils sont réservés à un.e enseignant.e '
                : 'Stages pour ce métier sont accessibles à :',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: widget.editMode
                ? EntityPickerTile(
                    title: widget.editMode ? null : '',
                    controller: widget.controller._reservedForPickerController!,
                    editMode: widget.editMode,
                  )
                : Text(
                    widget.controller._reservedForPickerController!.selection ??
                        'Tous les enseignant\u00b7e\u00b7s',
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreDetails() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IncidentsExpansionPanel(job: job, addSstEvent: widget.addSstEvent),
        const SizedBox(height: 12),
        SupervisionExpansionPanel(job: job),
        const SizedBox(height: 12),
        PhotoExpansionPanel(
            job: job, addImage: null, removeImage: widget.removeImage),
        const SizedBox(height: 12),
        CommentsExpansionPanel(job: job, addComment: widget.addComment)
      ],
    );
  }
}

class BuildPrerequisitesCheckboxes extends StatelessWidget {
  const BuildPrerequisitesCheckboxes({
    super.key,
    required this.controller,
    required this.checkboxKey,
    this.enabled = true,
    this.onChanged,
    this.hideTitle = false,
  });

  final Key checkboxKey;
  final CheckboxWithOtherController<PreInternshipRequestTypes> controller;
  final bool enabled;
  final Function(List<String>)? onChanged;
  final bool hideTitle;

  @override
  Widget build(BuildContext context) {
    return CheckboxWithOther<PreInternshipRequestTypes>(
      key: checkboxKey,
      controller: controller,
      title: hideTitle
          ? null
          : 'Exigences de l\'entreprise avant d\'accueillir des élèves en stage:',
      titleStyle: Theme.of(context).textTheme.bodyLarge,
      otherMaxLength: 500,
      enabled: enabled,
      onOptionSelected: (_) {
        if (onChanged != null) {
          onChanged!(controller.values);
        }
      },
    );
  }
}
