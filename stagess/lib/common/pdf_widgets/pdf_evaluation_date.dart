import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_theme.dart';

class PdfEvaluationDate extends pw.StatelessWidget {
  PdfEvaluationDate({
    required this.evaluationDate,
    this.textStyle,
  });

  final DateTime evaluationDate;
  final pw.TextStyle? textStyle;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          PdfTheme.titleSmall('Évaluation en date du'),
          pw.Text(
            DateFormat('dd MMMM yyyy', 'fr_CA').format(evaluationDate),
            style: textStyle ?? PdfTheme.textStyleNormal,
          )
        ]);
  }
}
