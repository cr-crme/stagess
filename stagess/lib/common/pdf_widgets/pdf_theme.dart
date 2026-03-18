import 'package:pdf/widgets.dart' as pw;

class PdfTheme {
  static pw.TextStyle get textStyleNormal =>
      pw.TextStyle(font: pw.Font.times(), fontSize: 12);
  static pw.TextStyle get textStyleBold =>
      pw.TextStyle(font: pw.Font.timesBold(), fontSize: 12);
  static pw.TextStyle get textStyleBoldItalic =>
      pw.TextStyle(font: pw.Font.timesBoldItalic(), fontSize: 12);

  static pw.Widget titleLarge(String text) {
    return pw.Padding(
      padding: pw.EdgeInsets.only(bottom: 4.0),
      child: pw.Text(text, style: textStyleBold.copyWith(fontSize: 18)),
    );
  }

  static pw.Widget titleMedium(String text) => pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 4.0),
        child: pw.Text(text, style: textStyleBold.copyWith(fontSize: 14)),
      );

  static pw.Widget titleSmall(
    String text, {
    pw.EdgeInsets? padding,
  }) =>
      pw.Padding(
        padding: padding ?? pw.EdgeInsets.all(0.0),
        child: pw.Text(text, style: textStyleBold.copyWith(fontSize: 12)),
      );

  static pw.Widget bodyMedium(String text, {pw.EdgeInsets? padding}) =>
      pw.Padding(
        padding: padding ?? pw.EdgeInsets.all(0.0),
        child: pw.Text(text, style: textStyleNormal),
      );
}
