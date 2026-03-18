import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_theme.dart';

class PdfSlider extends pw.StatelessWidget {
  PdfSlider({
    required this.value,
    required this.lowestLabel,
    required this.highestLabel,
    this.textStyle,
  });

  final double value;
  final double minValue = 1.0;
  final double maxValue = 5.0;
  final String lowestLabel;
  final String highestLabel;
  final pw.TextStyle? textStyle;

  @override
  pw.Widget build(pw.Context context) {
    final borderSize = 75.0;
    final buttonSize = 24.0;
    final sliderLength = 300.0;

    final filledPosition =
        ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.SizedBox(
            width: borderSize,
            child: pw.Text(lowestLabel,
                textAlign: pw.TextAlign.center,
                style: textStyle ?? PdfTheme.textStyleNormal)),
        pw.Center(
          child: pw.SizedBox(
            width: sliderLength,
            height: buttonSize + 2.0,
            child: pw.Stack(
              alignment: pw.Alignment.centerLeft,
              children: [
                pw.Positioned(
                  left: (buttonSize / 2),
                  child: pw.Container(
                    width: sliderLength - buttonSize,
                    height: 4,
                    color: PdfColors.grey300,
                  ),
                ),
                pw.Positioned(
                  left: (buttonSize / 2),
                  child: pw.Container(
                    width: (sliderLength - buttonSize) * filledPosition,
                    height: 4,
                    color: PdfColors.black,
                  ),
                ),
                pw.Positioned(
                    left: 1.0 +
                        (buttonSize / 2) +
                        (sliderLength - buttonSize) * filledPosition -
                        (buttonSize / 2),
                    child: pw.Container(
                      width: buttonSize - 2.0,
                      height: buttonSize - 2.0,
                      decoration: pw.BoxDecoration(
                        shape: pw.BoxShape.circle,
                        color: PdfColors.white,
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      child: pw.Center(
                          child: pw.Text(value.toStringAsFixed(1),
                              style: textStyle ?? PdfTheme.textStyleNormal)),
                    )),
              ],
            ),
          ),
        ),
        pw.SizedBox(
            width: borderSize,
            child: pw.Text(highestLabel,
                textAlign: pw.TextAlign.center,
                style: textStyle ?? PdfTheme.textStyleNormal)),
      ],
    );
  }
}
