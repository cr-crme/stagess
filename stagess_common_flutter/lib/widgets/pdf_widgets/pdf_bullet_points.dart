import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfTextBulletPoints extends pw.StatelessWidget {
  PdfTextBulletPoints(
      {required this.elements,
      this.spacing,
      this.bulletColor = PdfColors.black});

  final Iterable<String> elements;
  final pw.EdgeInsets? spacing;
  final PdfColor bulletColor;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: elements
          .map((element) => PdfBulletPoint(
              child: pw.Text(element),
              spacing: spacing,
              bulletColor: bulletColor))
          .toList(),
    );
  }
}

class PdfBulletPoints extends pw.StatelessWidget {
  PdfBulletPoints({required this.children, this.spacing});

  final Iterable<pw.Widget> children;
  final pw.EdgeInsets? spacing;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: children
          .map((element) => PdfBulletPoint(child: element, spacing: spacing))
          .toList(),
    );
  }
}

class PdfBulletPoint extends pw.StatelessWidget {
  PdfBulletPoint({
    required this.child,
    this.textStyle,
    this.spacing,
    this.bulletColor = PdfColors.black,
  });

  final pw.Widget child;
  final pw.TextStyle? textStyle;
  final pw.EdgeInsets? spacing;
  final PdfColor bulletColor;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 5, right: 6),
            width: 4,
            height: 4,
            decoration:
                pw.BoxDecoration(color: bulletColor, shape: pw.BoxShape.circle),
          ),
          pw.SizedBox(width: 6.0),
          pw.Expanded(child: child),
        ],
      ),
      padding: spacing,
    );
  }
}
