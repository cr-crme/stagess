import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('PhotoExpansionPanel');

class PhotoExpansionPanel extends StatefulWidget {
  const PhotoExpansionPanel({
    super.key,
    required this.job,
    required this.addImage,
    required this.removeImage,
  });

  final Job job;
  final void Function(Job job, ImageSource source) addImage;
  final void Function(Job job, int index) removeImage;

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
                    widget.removeImage(widget.job, index);
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
                    onPressed: widget.job.photos.length < 3
                        ? () => widget.addImage(widget.job, ImageSource.gallery)
                        : null,
                    icon: Icon(
                      Icons.image,
                      color: widget.job.photos.length < 3
                          ? Theme.of(context).primaryColor
                          : Colors.grey,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: widget.job.photos.length < 3
                        ? () => widget.addImage(widget.job, ImageSource.camera)
                        : null,
                    icon: Icon(
                      Icons.camera_alt,
                      color: widget.job.photos.length < 3
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
        onTap: () => showSnackBar(
          context,
          message:
              'Les photos doivent représenter un poste de travail vide, ou '
              'encore des travailleurs de dos.\n'
              'Ne pas prendre des photos où on peut les reconnaitre.',
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(Icons.info, color: Theme.of(context).primaryColor),
        ),
      ),
    ),
  );
}
