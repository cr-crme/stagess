import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_colors_extension.dart';

class PdfRadioButtons extends pw.StatelessWidget {
  PdfRadioButtons({
    required this.options,
    this.textStyle,
  });

  final Map<String, bool> options;
  final pw.TextStyle? textStyle;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: options.entries.map(
        (entry) {
          return pw.Padding(
              padding: pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Container(
                    width: 12,
                    height: 12,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      border: pw.Border.all(color: PdfColors.black),
                    ),
                    child: pw.Center(
                      child: pw.Container(
                        width: 6,
                        height: 6,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          color: entry.value
                              ? PdfColors.black
                              : PdfColorsExtension.transparent,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 4),
                  pw.Text(entry.key, style: textStyle),
                ],
              ));
        },
      ).toList(),
    );
  }
}
