import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/generic/photo.dart';
import 'package:stagess_common/services/image_helpers.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/dialogs/help_dialog.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('PhotoExpansionPanel');

class PhotoExpansionPanel extends StatefulWidget {
  const PhotoExpansionPanel({
    super.key,
    required this.enterpriseId,
    required this.job,
    this.onChangingImage,
  });

  final String? enterpriseId;
  final Job job;
  final Function(bool isDone)? onChangingImage;

  @override
  State<PhotoExpansionPanel> createState() => _PhotoExpansionPanelState();
}

class _PhotoExpansionPanelState extends State<PhotoExpansionPanel> {
  late final _scrollController = ScrollController()
    ..addListener(() => setState(() {}));

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _scrollPhotos(int direction) {
    const photoWidth = 150.0;
    _scrollController.animateTo(
      _scrollController.offset + (direction * photoWidth),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _showPhoto(int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0, top: 20, left: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(widget.job.photos[index].bytes),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: InkWell(
                  onTap: () {
                    _removeImage(widget.job, index);
                    setState(() {});
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(25),
                  child: const Icon(Icons.delete, color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building PhotoExpansionPanel for job: ${widget.job.specialization.name}',
    );

    final canLeftScroll =
        _scrollController.hasClients && _scrollController.offset > 0;

    // The || is a hack because the maxScrollExtend is zero when first opening the card
    final canRightScroll = _scrollController.hasClients &&
        (_scrollController.offset <
                _scrollController.position.maxScrollExtent ||
            (widget.job.photos.length > 2 && _scrollController.offset == 0));

    final canAddPhotos =
        widget.enterpriseId != null && widget.job.photos.isEmpty;

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) => ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Photos du poste de travail'),
            _buildInfoButton(context, isExpanded: isExpanded),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.job.photos.isNotEmpty &&
                    _scrollController.hasClients)
                  InkWell(
                    onTap: canLeftScroll ? () => _scrollPhotos(-1) : null,
                    borderRadius: BorderRadius.circular(25),
                    child: Icon(
                      Icons.arrow_left,
                      color: canLeftScroll
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      size: 40,
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _scrollController,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...widget.job.photos.isEmpty
                            ? [const Text('Aucune image disponible')]
                            : widget.job.photos.asMap().keys.map(
                                  (i) => InkWell(
                                    onTap: () => _showPhoto(i),
                                    child: Card(
                                      child: Image.memory(
                                        widget.job.photos[i].bytes,
                                        height: 250,
                                      ),
                                    ),
                                  ),
                                ),
                      ],
                    ),
                  ),
                ),
                if (widget.job.photos.isNotEmpty &&
                    _scrollController.hasClients)
                  InkWell(
                    onTap: canRightScroll ? () => _scrollPhotos(1) : null,
                    borderRadius: BorderRadius.circular(25),
                    child: Icon(
                      Icons.arrow_right,
                      color: canRightScroll
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      size: 40,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: canAddPhotos
                        ? () => _addImage(widget.job, ImageSource.gallery)
                        : null,
                    icon: Icon(
                      Icons.image,
                      color: canAddPhotos
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: canAddPhotos
                        ? () => _addImage(widget.job, ImageSource.camera)
                        : null,
                    icon: Icon(
                      Icons.camera_alt,
                      color: canAddPhotos
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addImage(Job job, ImageSource source) async {
    if (widget.onChangingImage != null) widget.onChangingImage!(false);

    _logger.finer('Adding image to job: ${job.specialization.name}');
    final enterprises = EnterprisesProvider.of(context, listen: false);
    final enterprise =
        enterprises.firstWhere((e) => e.id == widget.enterpriseId);

    final hasLock = await enterprises.getLockForItem(enterprise);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible d\'ajouter une image, car l\'entreprise est en cours de modification par un autre utilisateur.',
        );
      }
      if (widget.onChangingImage != null) widget.onChangingImage!(true);
      return;
    }

    late List<XFile?> images;
    if (source == ImageSource.camera) {
      images = [(await ImagePicker().pickImage(source: ImageSource.camera))];
    } else {
      images = await ImagePicker().pickMultiImage();
    }
    if (images.isEmpty) {
      await enterprises.releaseLockForItem(enterprise);
      if (widget.onChangingImage != null) widget.onChangingImage!(true);
      return;
    }

    for (XFile? file in images) {
      if (file == null) continue;
      final Uint8List bytes = await ImageHelpers.resizeImage(
        await (kIsWeb ? file.readAsBytes() : File(file.path).readAsBytes()),
        width: null,
        height: 350,
      );

      job.photos.add(Photo(bytes: bytes));
    }

    final isSuccess = await enterprises.replaceWithConfirmation(enterprise);
    await enterprises.releaseLockForItem(enterprise);
    if (mounted) {
      showSnackBar(context,
          message: isSuccess
              ? 'L\'image a été ajoutée'
              : 'Une erreur est survenue lors de l\'ajout de l\'image');
    }

    if (widget.onChangingImage != null) widget.onChangingImage!(true);
    _logger.finer('Image(s) added to job: ${job.specialization.name}');
  }

  void _removeImage(Job job, int index) async {
    if (widget.onChangingImage != null) widget.onChangingImage!(false);
    _logger.finer('Removing image from job: ${job.specialization.name}');

    final enterprises = EnterprisesProvider.of(context, listen: false);
    final enterprise =
        enterprises.firstWhere((e) => e.id == widget.enterpriseId);
    final hasLock = await enterprises.getLockForItem(enterprise);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de supprimer l\'image, car l\'entreprise est en cours de modification par un autre utilisateur.',
        );
      }
      if (widget.onChangingImage != null) widget.onChangingImage!(true);
      return;
    }

    job.photos.removeAt(index);
    await enterprises.replaceWithConfirmation(enterprise);
    await enterprises.releaseLockForItem(enterprise);
    if (mounted) {
      showSnackBar(context, message: 'L\'image a été supprimée');
    }

    if (widget.onChangingImage != null) widget.onChangingImage!(true);
    _logger.finer('Image removed from job: ${job.specialization.name}');
  }
}

Widget _buildInfoButton(BuildContext context, {required bool isExpanded}) {
  return Visibility(
    visible: isExpanded,
    maintainSize: true,
    maintainAnimation: true,
    maintainState: true,
    child: Align(
      alignment: Alignment.topRight,
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () => showHelpDialog(
          context,
          title: 'Photos du poste',
          content: const Text(
              'Les photos doivent représenter un poste de travail vide, ou '
              'encore des travailleurs de dos.\n'
              'Ne pas prendre des photos où on peut les reconnaitre.'),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(Icons.info, color: Theme.of(context).primaryColor),
        ),
      ),
    ),
  );
}
