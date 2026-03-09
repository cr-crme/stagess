import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfTextBox extends pw.StatelessWidget {
  PdfTextBox({required this.child, this.textStyle});

  final pw.Widget child;
  final pw.TextStyle? textStyle;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      width: double.infinity,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black),
      ),
      child: pw.Padding(padding: pw.EdgeInsets.all(8), child: child),
    );
  }
}
