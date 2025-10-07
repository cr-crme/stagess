import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:stagess_admin/screens/school_boards/add_school_dialog.dart';
import 'package:stagess_admin/screens/school_boards/confirm_delete_school_board_dialog.dart';
import 'package:stagess_admin/screens/school_boards/school_list_tile.dart';
import 'package:stagess_common/models/generic/access_level.dart';
import 'package:stagess_common/models/school_boards/school.dart';
import 'package:stagess_common/models/school_boards/school_board.dart';
import 'package:stagess_common/services/image_helpers.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

class SchoolBoardListTile extends StatefulWidget {
  const SchoolBoardListTile({
    super.key,
    required this.schoolBoard,
    this.isExpandable = true,
    this.forceEditingMode = false,
    double? elevation,
  }) : elevation = elevation ?? 5.0;

  final bool isExpandable;
  final bool forceEditingMode;
  final SchoolBoard schoolBoard;
  final double elevation;

  @override
  State<SchoolBoardListTile> createState() => SchoolBoardListTileState();
}

class SchoolBoardListTileState extends State<SchoolBoardListTile> {
  final _formKey = GlobalKey<FormState>();
  Future<bool> validate() async {
    // We do both like so, so all the fields get validated even if one is not valid
    bool isValid = _formKey.currentState?.validate() ?? false;
    return isValid;
  }

  @override
  void didUpdateWidget(covariant SchoolBoardListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.schoolBoard.getDifference(oldWidget.schoolBoard).isNotEmpty) {
      // The logo controller won't update automatically, so we need to do it manually
      setState(() {
        _logoController = Uint8List.fromList([...widget.schoolBoard.logo]);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnesstController.dispose();
    super.dispose();
  }

  bool _isExpanded = true;
  bool _isEditing = false;
  late final bool _canEdit =
      AuthProvider.of(context, listen: false).databaseAccessLevel >=
          AccessLevel.superAdmin ||
      (AuthProvider.of(context, listen: false).databaseAccessLevel ==
              AccessLevel.admin &&
          widget.schoolBoard.id ==
              AuthProvider.of(context, listen: false).schoolBoardId);
  late final bool _canDelete =
      AuthProvider.of(context, listen: false).databaseAccessLevel >=
      AccessLevel.superAdmin;

  late final _nameController = TextEditingController(
    text: widget.schoolBoard.name,
  );
  late Uint8List _logoController = Uint8List.fromList([
    ...widget.schoolBoard.logo,
  ]);
  late final _cnesstController = TextEditingController(
    text: widget.schoolBoard.cnesstNumber,
  );

  SchoolBoard get editedSchoolBoard => widget.schoolBoard.copyWith(
    name: _nameController.text,
    logo: _logoController,
    cnesstNumber: _cnesstController.text,
  );

  @override
  void initState() {
    super.initState();
    if (widget.forceEditingMode) _onClickedEditing();
  }

  Future<void> _onClickedDeleting() async {
    final schoolBoards = SchoolBoardsProvider.of(context, listen: false);
    final hasLock = await schoolBoards.getLockForItem(widget.schoolBoard);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de supprimer le centre de services scolaire, car il est en cours de modification par un autre utilisateur.',
        );
      }
      return;
    }

    // Show confirmation dialog
    final answer = await showDialog(
      context: context,
      builder:
          (context) =>
              ConfirmDeleteSchoolBoardDialog(schoolBoard: widget.schoolBoard),
    );
    if (answer == null || !answer || !mounted) {
      await schoolBoards.releaseLockForItem(widget.schoolBoard);
      return;
    }

    final isSuccess = await SchoolBoardsProvider.of(
      context,
    ).removeWithConfirmation(widget.schoolBoard);
    if (mounted) {
      showSnackBar(
        context,
        message:
            isSuccess
                ? 'Centre de services scolaire supprimé avec succès'
                : 'Échec de la suppression de la centre de services scolaire',
      );
    }
    await schoolBoards.releaseLockForItem(widget.schoolBoard);
  }

  Future<void> _onClickedEditing() async {
    final schoolBoards = SchoolBoardsProvider.of(context, listen: false);

    if (_isEditing) {
      // Validate the form
      if (!(await validate()) || !mounted) return;

      // Finish editing
      final newSchoolBoard = editedSchoolBoard;
      if (newSchoolBoard.getDifference(widget.schoolBoard).isNotEmpty) {
        final isSuccess = await schoolBoards.replaceWithConfirmation(
          newSchoolBoard,
        );
        if (mounted) {
          showSnackBar(
            context,
            message:
                isSuccess
                    ? 'Centre de services scolaire modifiée avec succès'
                    : 'Échec de la modification de la centre de services scolaire',
          );
        }
      }
      await schoolBoards.releaseLockForItem(widget.schoolBoard);
    } else {
      final hasLock = await schoolBoards.getLockForItem(widget.schoolBoard);
      if (!hasLock || !mounted) {
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier le centre de services scolaire, car il est en cours de modification par un autre utilisateur.',
          );
        }
        return;
      }
    }

    if (mounted) setState(() => _isEditing = !_isEditing);
  }

  @override
  Widget build(BuildContext context) {
    return widget.isExpandable
        ? AnimatedExpandingCard(
          initialExpandedState: _isExpanded,
          elevation: widget.elevation,
          onTapHeader: (isExpanded) => setState(() => _isExpanded = isExpanded),
          header:
              (ctx, isExpanded) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 12.0,
                        top: 8,
                        bottom: 8,
                      ),
                      child: Text(
                        widget.schoolBoard.name,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.titleLarge!.copyWith(color: Colors.black),
                      ),
                    ),
                  ),
                  if (_isExpanded)
                    Row(
                      children: [
                        if (_canDelete)
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: _onClickedDeleting,
                          ),
                        if (_canEdit)
                          IconButton(
                            icon: Icon(
                              _isEditing ? Icons.save : Icons.edit,
                              color: Theme.of(context).primaryColor,
                            ),
                            onPressed: _onClickedEditing,
                          ),
                      ],
                    ),
                ],
              ),
          child: _buildEditingForm(),
        )
        : _buildEditingForm();
  }

  Widget _buildEditingForm() {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildName(),
            _buildLogo(),
            _buildCnesst(),
            _buildSchoolNames(),
          ],
        ),
      ),
    );
  }

  Widget _buildName() {
    return _isEditing
        ? Padding(
          padding: const EdgeInsets.only(right: 12.0, bottom: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                validator:
                    (value) =>
                        value?.isEmpty == true
                            ? 'Le nom du centre de services scolaire est obligatoire'
                            : null,
                decoration: const InputDecoration(
                  labelText: 'Nom du centre de services scolaire',
                ),
              ),
            ],
          ),
        )
        : Container();
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Logo du centre de services scolaire'),
          _logoController.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(
                    width: ImageHelpers.logoWidth.toDouble(),
                    height: ImageHelpers.logoHeight.toDouble(),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Center(
                      child: const Text(
                        'Aucun logo n\'a été téléversé',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              )
              : Center(child: Image.memory(_logoController)),
          if (_isEditing)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result == null ||
                            result.files.first.bytes == null ||
                            !mounted) {
                          return;
                        }
                        setState(() {
                          _logoController = ImageHelpers.resizeImage(
                            result.files.first.bytes!,
                            width: null,
                            height: ImageHelpers.logoHeight,
                          );
                        });
                      },
                      icon: Icon(
                        Icons.upload_file_rounded,
                        color: Theme.of(context).primaryColor,
                      ),
                      tooltip: 'Téléverser un logo',
                    ),
                    if (_logoController.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _logoController = Uint8List(0);
                          });
                        },
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Supprimer le logo',
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCnesst() {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _cnesstController,
            enabled: _isEditing,
            decoration: const InputDecoration(
              labelText: 'Numéro de dossier à la CNESST',
              labelStyle: TextStyle(color: Colors.black),
            ),
            style: TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddSchoolDialog(SchoolBoard schoolBoard) async {
    final answer = await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => AddSchoolDialog(schoolBoard: schoolBoard),
    );
    if (answer is! School || !mounted) return;

    schoolBoard.schools.add(answer);
    final isSuccess = await SchoolBoardsProvider.of(
      context,
      listen: false,
    ).addWithConfirmation(schoolBoard);
    if (!mounted) return;

    showSnackBar(
      context,
      message:
          isSuccess
              ? 'École ajoutée avec succès'
              : 'Échec de l\'ajout de l\'école',
    );
  }

  Widget _buildSchoolNames() {
    final schools = _getSchools(widget.schoolBoard);

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          schools.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: const Text(
                    'Aucune école n\'a été associée pour l\'instant',
                  ),
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...schools.map(
                    (school) => Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: SchoolListTile(
                        school: school,
                        schoolBoard: widget.schoolBoard,
                        elevation: 0,
                        canEdit: _canEdit,
                        canDelete: _canDelete,
                      ),
                    ),
                  ),
                ],
              ),
          if (_canEdit && !widget.forceEditingMode)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Center(
                child: TextButton(
                  onPressed: () => _showAddSchoolDialog(widget.schoolBoard),
                  child: Text('Ajouter une école'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

List<School> _getSchools(SchoolBoard schoolBoard) {
  final schools = schoolBoard.schools;

  schools.sort((a, b) {
    final nameA = a.name.toLowerCase();
    final nameB = b.name.toLowerCase();
    return nameA.compareTo(nameB);
  });
  return schools;
}
