import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

void showPdfDialog(
  BuildContext context, {
  required Future<Uint8List> Function(
          BuildContext context, PdfPageFormat format)
      pdfGeneratorCallback,
}) async {
  final data = await pdfGeneratorCallback(context, PdfPageFormat.letter);
  if (!context.mounted) return;

  return showDialog(
      context: context,
      builder: (ctx) => Dialog(
            backgroundColor: Colors.grey[500]?.withAlpha(225),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(25),
                        ),
                      ),
                    ),
                    Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: IconButton(
                            icon: Icon(Icons.close),
                            onPressed: () => Navigator.of(ctx).pop(),
                          ),
                        )),
                  ],
                ),
                Expanded(child: _PdfViewer(pdfData: data)),
              ],
            ),
          ));
}

class _PdfViewer extends StatefulWidget {
  const _PdfViewer({required this.pdfData});
  final Uint8List pdfData;

  @override
  State<_PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<_PdfViewer> {
  bool isInitialized = false;
  double screenWidth = -1.0;
  double paddingController = double.infinity;
  double zoomSpeed = 0.0;

  late final pdfWidget = PdfPreview(
    allowPrinting: true,
    allowSharing: true,
    canChangeOrientation: false,
    canChangePageFormat: false,
    canDebug: false,
    initialPageFormat: PdfPageFormat.letter,
    build: (format) => Future.value(widget.pdfData),
  );

  void _handleScreenSizeChange() {
    screenWidth = MediaQuery.of(context).size.width;
    zoomSpeed = screenWidth * 0.05;
    _limitZoomOut();
    WidgetsBinding.instance.addPostFrameCallback((_) => setState(() {}));
  }

  void _handleZoomIn() {
    paddingController -= zoomSpeed;
    if (paddingController < 0) {
      paddingController = 0;
    }
    setState(() {});
  }

  void _handleZoomOut() {
    paddingController += zoomSpeed;
    _limitZoomOut();
    setState(() {});
  }

  void _limitZoomOut() {
    final minimumPdfWidth =
        isInitialized ? MediaQuery.of(context).size.width / 5 : 300;
    isInitialized = true;
    if (paddingController >
        MediaQuery.of(context).size.width / 2 - minimumPdfWidth) {
      paddingController =
          MediaQuery.of(context).size.width / 2 - minimumPdfWidth;
    }
    if (paddingController < 0) paddingController = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (screenWidth != MediaQuery.of(context).size.width) {
      _handleScreenSizeChange();
    }

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: paddingController),
          child: pdfWidget,
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton(
                onPressed: _handleZoomIn,
                child: Icon(Icons.zoom_in),
              ),
              SizedBox(height: 12),
              FloatingActionButton(
                onPressed: _handleZoomOut,
                child: Icon(Icons.zoom_out),
              ),
            ],
          ),
        )
      ],
    );
  }
}
