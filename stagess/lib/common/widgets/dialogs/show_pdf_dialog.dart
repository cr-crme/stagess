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
  return showDialog(
      context: context,
      builder: (ctx) => Dialog(
            backgroundColor: Colors.grey[700],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(),
                      ),
                    )),
                Expanded(
                  child: PdfPreview(
                    allowPrinting: true,
                    allowSharing: true,
                    canChangeOrientation: false,
                    canChangePageFormat: false,
                    canDebug: false,
                    build: (format) => pdfGeneratorCallback(context, format),
                  ),
                ),
              ],
            ),
          ));
}
