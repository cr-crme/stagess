import 'package:pdf/widgets.dart' as pw;

class PdfTextBulletPoints extends pw.StatelessWidget {
  PdfTextBulletPoints({required this.elements, this.spacing});

  final Iterable<String> elements;
  final pw.EdgeInsets? spacing;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: elements
          .map((element) =>
              PdfBulletPoint(child: pw.Text(element), spacing: spacing))
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
  PdfBulletPoint({required this.child, this.textStyle, this.spacing});

  final pw.Widget child;
  final pw.TextStyle? textStyle;
  final pw.EdgeInsets? spacing;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('\u0097', style: textStyle),
          pw.SizedBox(width: 6.0),
          pw.Expanded(child: child),
        ],
      ),
      padding: spacing,
    );
  }
}
