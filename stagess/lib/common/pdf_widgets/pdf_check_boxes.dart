import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_colors_extension.dart';

class PdfCheckBoxes extends pw.StatelessWidget {
  PdfCheckBoxes({
    required this.options,
    this.includeOthers = false,
    this.otherValue,
    this.textStyle,
  });

  final Map<String, bool> options;
  final bool includeOthers;
  final String? otherValue;
  final pw.TextStyle? textStyle;

  @override
  pw.Widget build(pw.Context context) {
    if (includeOthers) {
      if (otherValue == null) {
        throw ArgumentError(
            'otherValue must be provided when includeOthers is true (at least an empty string)');
      }
      options['__OTHER__'] = otherValue!.isNotEmpty;
    }
    final hasOther = includeOthers && (otherValue?.isNotEmpty ?? false);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: options.entries.map(
        (entry) {
          return pw.Row(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black)),
                  child: pw.Checkbox(
                    value: true,
                    name: entry.key,
                    checkColor: entry.value
                        ? PdfColors.black
                        : PdfColorsExtension.transparent,
                    activeColor: PdfColors.white,
                  )),
              pw.SizedBox(width: 6.0),
              pw.Text(
                  entry.key == '__OTHER__'
                      ? 'Autre${hasOther ? ' : ' : ''}'
                      : entry.key,
                  style: textStyle),
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 12.0),
                child: pw.Container(
                  width: 200,
                  height: 24,
                  padding: const pw.EdgeInsets.only(left: 4.0),
                  decoration: hasOther
                      ? pw.BoxDecoration(
                          border: pw.Border.all(
                              color: includeOthers && entry.key == '__OTHER__'
                                  ? PdfColors.black
                                  : PdfColorsExtension.transparent))
                      : null,
                  child: hasOther
                      ? pw.Align(
                          alignment: pw.Alignment.centerLeft,
                          child: pw.Text(
                            otherValue!,
                            style: textStyle?.copyWith(
                                color: includeOthers && entry.key == '__OTHER__'
                                    ? null
                                    : PdfColorsExtension.transparent),
                          ))
                      : null,
                ),
              ),
            ],
          );
        },
      ).toList(),
    );
  }
}
