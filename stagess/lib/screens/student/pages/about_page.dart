import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/generic/phone_number.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/helpers/form_service.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/address_list_tile.dart';
import 'package:stagess_common_flutter/widgets/birthday_list_tile.dart';
import 'package:stagess_common_flutter/widgets/dialogs/help_dialog.dart';
import 'package:stagess_common_flutter/widgets/email_list_tile.dart';
import 'package:stagess_common_flutter/widgets/phone_list_tile.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';
import 'package:stagess_common_flutter/widgets/sub_title.dart';
import 'package:stagess_common_flutter/widgets/teacher_picker_tile.dart';
import 'package:stagess_common_flutter/widgets/widget_repeater.dart';

final _logger = Logger('AboutPage');

class AboutPage extends StatefulWidget {
  const AboutPage({super.key, required this.student});

  final Student student;

  @override
  State<AboutPage> createState() => AboutPageState();
}

class AboutPageState extends State<AboutPage> {
  final _formKey = GlobalKey<FormState>();
  bool get isEditing => _editing;

  late final _addressController = AddressController()
    ..initialValue = widget.student.address;

  late final _birthdayController = BirthdayController(
    initialValue: (widget.student.dateBirth ?? DateTime(0)) == DateTime(0)
        ? null
        : widget.student.dateBirth,
  );
  late final _phoneController =
      TextEditingController(text: widget.student.phone.toString());
  late final _emailController =
      TextEditingController(text: widget.student.email.toString());
  late final _teacherInChargeIdController = TeacherPickerController(
    initial: TeachersProvider.of(context)
        .firstWhereOrNull((e) => widget.student.teacherInChargeId == e.id),
  );
  late final _supplementaryTeacherInChargeIdsController =
      WidgetRepeaterController(
    options: widget.student.supplementaryTeacherInChargeIds
        .asMap()
        .map((index, e) => MapEntry(
            index, _RepeatableTeacher(id: e, index: index, context: context)))
        .values
        .toList(),
  );
  late final _contactFirstNameController =
      TextEditingController(text: widget.student.contact.firstName);
  late final _contactLastNameController =
      TextEditingController(text: widget.student.contact.lastName);
  late final _contactLinkController =
      TextEditingController(text: widget.student.contactLink);
  late final _contactPhoneController =
      TextEditingController(text: widget.student.contact.phone.toString());
  late final _contactEmailController =
      TextEditingController(text: widget.student.contact.email);

  @override
  void didUpdateWidget(covariant AboutPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.student.getDifference(editedStudent).isNotEmpty) {
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building AboutPage for student: ${widget.student.id}');

    return Theme(
      data: Theme.of(context).copyWith(disabledColor: Colors.black),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGeneralInformation(),
              _buildTeacherInChargeTile(),
              _buildEmergencyContact(),
              SizedBox(height: MediaQuery.of(context).size.height * 0.5),
            ],
          ),
        ),
      ),
    );
  }

  Student get editedStudent {
    return widget.student.copyWith(
      address: _addressController.address,
      dateBirth: _birthdayController.value,
      phone: PhoneNumber.fromString(_phoneController.text,
          id: widget.student.phone.id),
      email: _emailController.text,
      teacherInChargeId: _teacherInChargeIdController.teacher?.id ?? '',
      supplementaryTeacherInChargeIds:
          _supplementaryTeacherInChargeIdsController.options
              .map((e) => e.controller.teacher?.id)
              .where((e) => e != null && e.isNotEmpty)
              .cast<String>()
              .toList(),
      contact: widget.student.contact.copyWith(
        firstName: _contactFirstNameController.text,
        lastName: _contactLastNameController.text,
        phone: widget.student.contact.phone
            .copyWith(number: _contactPhoneController.text),
        email: _contactEmailController.text,
      ),
      contactLink: _contactLinkController.text,
    );
  }

  void _resetForm() {
    _addressController.initialValue = widget.student.address;
    _birthdayController.updateValue(
        (widget.student.dateBirth ?? DateTime(0)) == DateTime(0)
            ? null
            : widget.student.dateBirth);
    _phoneController.text = widget.student.phone.toString();
    _emailController.text = widget.student.email.toString();
    _teacherInChargeIdController.teacher = TeachersProvider.of(context)
        .firstWhereOrNull((e) => widget.student.teacherInChargeId == e.id);
    _supplementaryTeacherInChargeIdsController.clear();
    for (final teacherId in widget.student.supplementaryTeacherInChargeIds) {
      _supplementaryTeacherInChargeIdsController.add(
        _RepeatableTeacher(
            id: teacherId,
            index: _supplementaryTeacherInChargeIdsController.options.length,
            context: context),
      );
    }
    _contactFirstNameController.text = widget.student.contact.firstName;
    _contactLastNameController.text = widget.student.contact.lastName;
    _contactLinkController.text = widget.student.contactLink;
    _contactPhoneController.text = widget.student.contact.phone.toString();
    _contactEmailController.text = widget.student.contact.email;
  }

  bool _forceDisabled = false;
  bool _editing = false;
  Future<void> toggleEdit({bool save = true}) async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });
    final students = StudentsProvider.of(context, listen: false);

    if (_editing) {
      _logger.info('Saving student information');

      if (!save) {
        _editing = false;
        _resetForm();

        _logger.fine('Edit mode disabled without saving changes');
        await students.releaseLockForItem(widget.student);
        setState(() {
          _forceDisabled = false;
        });
        return;
      }
    } else {
      _logger.info('Entering edit mode for student information');
      final hasLock = await students.getLockForItem(widget.student);
      if (!hasLock || !mounted) {
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier cet élève, car il est en cours de modification par un autre utilisateur.',
          );
        }
        setState(() {
          _forceDisabled = false;
        });
        return;
      }

      _editing = true;
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    // Validate addresses
    final addressStatus = await _addressController.requestValidation();
    if (!mounted) return;
    if (addressStatus != null) {
      showSnackBar(context, message: addressStatus);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }
    if (!mounted) return;

    if (!FormService.validateForm(_formKey, save: true)) {
      setState(() {
        _forceDisabled = false;
      });
      return;
    }
    _editing = false;

    final newStudent = editedStudent;
    if (widget.student.getDifference(newStudent).isEmpty) {
      if (mounted) {
        showSnackBar(context, message: 'Les informations ont été enregistrées');
      }
      await students.releaseLockForItem(widget.student);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    final isSuccess = await students.replaceWithConfirmation(newStudent);

    if (mounted) {
      showSnackBar(context,
          message: isSuccess
              ? 'Les informations ont été enregistrées'
              : 'Une erreur est survenue lors de l\'enregistrement des informations');
    }
    await students.releaseLockForItem(widget.student);

    _logger.fine(
        'Student information saved ${isSuccess ? 'successfully' : 'failed to save'}');
    setState(() {
      _forceDisabled = false;
    });
  }

  Widget _buildGeneralInformation() {
    // ThemeData does not work anymore so we have to override the style manually
    const styleOverride = TextStyle(color: Colors.black);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Informations générales', top: 12),
        Padding(
          padding: const EdgeInsets.only(left: 12.0, right: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BirthdayListTile(
                controller: _birthdayController,
                enabled: _editing,
              ),
              const SizedBox(height: 8),
              PhoneListTile(
                controller: _phoneController,
                title: 'Téléphone de l\'élève',
                titleStyle: styleOverride,
                contentStyle: styleOverride,
                isMandatory: false,
                enabled: _editing,
              ),
              const SizedBox(height: 8),
              EmailListTile(
                title: 'Courriel de l\'élève',
                controller: _emailController,
                titleStyle: styleOverride,
                contentStyle: styleOverride,
                enabled: _editing,
              ),
              const SizedBox(height: 8),
              AddressListTile(
                addressController: _addressController,
                titleStyle: styleOverride,
                contentStyle: styleOverride,
                isMandatory: false,
                enabled: _editing,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTeacherInChargeTile() {
    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SubTitle('Enseignant·e·s responsable·s', left: 0),
          Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeacherInCharge(),
                const SizedBox(height: 24),
                _buildSupplementaryTeachersInCharge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeacherInCharge() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                _editing
                    ? 'Sélectionner l\'enseignant·e responsable'
                    : 'Enseignant·e responsable',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: IconButton(
                  onPressed: () {
                    showHelpDialog(
                      context,
                      title: 'Enseignant·e responsable',
                      content: Text(
                          'Avec les administrateurs, l\'enseignant responsable est '
                          'la seule personne capable de modifier les informations ' // TODO Confirm this is true (supplementary)
                          'personnelles de l’élève qui figurent sur l’onglet "À propos" '
                          'de la page de l’élève (p. ex. son adresse courriel)'),
                    );
                  },
                  icon:
                      Icon(Icons.info, color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
        TeacherPickerTile(
          controller: _teacherInChargeIdController,
          title: 'Nom de l\'enseignant·e',
          filter: (teacher) =>
              teacher.schoolBoardId == widget.student.schoolBoardId,
          editMode: _editing,
        ),
      ],
    );
  }

  Widget _buildSupplementaryTeachersInCharge() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                _editing
                    ? 'Sélectionner les intervenant·e·s supplémentaires'
                    : _supplementaryTeacherInChargeIdsController.options.isEmpty
                        ? 'Aucun·e intervenant·e supplémentaire sélectionné·e'
                        : 'Intervenant·e·s supplémentaires',
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: IconButton(
                  onPressed: () {
                    showHelpDialog(
                      context,
                      title: 'Intervenant·e·s supplémentaires',
                      content: Text(
                          'L\'élève apparaitra dans la liste d’élèves de tous les '
                          'intervenants supplémentaires sélectionnés dans la liste'),
                    );
                  },
                  icon:
                      Icon(Icons.info, color: Theme.of(context).primaryColor)),
            ),
          ],
        ),
        if (_editing ||
            _supplementaryTeacherInChargeIdsController.options.isNotEmpty)
          WidgetRepeater(
            controller: _supplementaryTeacherInChargeIdsController,
            buttonTitle: 'Ajouter un·e intervenant·e',
            hasCheckboxes: false,
            canReorder: false,
            enabled: _editing,
            newItemBuilder: (index) => _RepeatableTeacher(id: '', index: index),
            widgetBuilder: (context, index, item, onUpdated) {
              return Flexible(
                child: TeacherPickerTile(
                  title: 'Intervenant·e N°${index + 1}',
                  controller: item.controller,
                  editMode: _editing,
                  filter: (teacher) =>
                      teacher.schoolBoardId == widget.student.schoolBoardId,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildEmergencyContact() {
    // ThemeData does not work anymore so we have to override the style manually
    const styleOverride = TextStyle(color: Colors.black);

    return Padding(
      padding: const EdgeInsets.only(left: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SubTitle('Contact en cas d\'urgence', left: 0.0),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                TextFormField(
                  controller: _contactFirstNameController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom',
                    labelStyle: styleOverride,
                    disabledBorder: InputBorder.none,
                  ),
                  style: styleOverride,
                  enabled: _editing,
                ),
                TextFormField(
                  controller: _contactLastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de famille',
                    labelStyle: styleOverride,
                    disabledBorder: InputBorder.none,
                  ),
                  style: styleOverride,
                  enabled: _editing,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contactLinkController,
                  decoration: const InputDecoration(
                    labelText: 'Lien avec l\'élève',
                    labelStyle: styleOverride,
                    disabledBorder: InputBorder.none,
                  ),
                  style: styleOverride,
                  enabled: _editing,
                ),
                const SizedBox(height: 8),
                PhoneListTile(
                  controller: _contactPhoneController,
                  title: 'Téléphone du contact',
                  titleStyle: styleOverride,
                  contentStyle: styleOverride,
                  enabled: _editing,
                  isMandatory: false,
                ),
                const SizedBox(height: 8),
                EmailListTile(
                  title: 'Courriel du contact',
                  titleStyle: styleOverride,
                  contentStyle: styleOverride,
                  controller: _contactEmailController,
                  enabled: _editing,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatableTeacher extends RepeatableItem {
  static Teacher? toTeacher(BuildContext context, String id) =>
      TeachersProvider.of(context, listen: false)
          .firstWhereOrNull((e) => e.id == id);

  _RepeatableTeacher({
    required super.index,
    TeacherPickerController? controller,
    String? id,
    BuildContext? context,
  }) : controller = _prepareController(
            controller: controller, id: id, context: context);

  final TeacherPickerController controller;

  static TeacherPickerController _prepareController(
      {TeacherPickerController? controller,
      String? id,
      BuildContext? context}) {
    if (controller != null) {
      if (id != null && id.isNotEmpty) throw ArgumentError('controller and id');
      return controller;
    }

    if (id == null || id.isEmpty) {
      return TeacherPickerController(initial: null);
    }

    if (context == null) {
      throw ArgumentError(
          'controller and context cannot both be null if id is not empty');
    }
    return TeacherPickerController(initial: toTeacher(context, id));
  }

  @override
  _RepeatableTeacher copyWith({int? index, bool? isSelected}) {
    return _RepeatableTeacher(
        index: index ?? this.index, controller: controller);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
