import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_bullet_points.dart';
import 'package:stagess/common/pdf_widgets/pdf_theme.dart';

class PdfWerePresentAtMeeting extends pw.StatelessWidget {
  PdfWerePresentAtMeeting({
    required this.werePresent,
    required this.studentName,
    this.textStyle,
  });

  final List<String> werePresent;
  final String studentName;
  final pw.TextStyle? textStyle;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        PdfTheme.titleSmall('Personnes présentes à l\'évaluation'),
        ...werePresent.asMap().keys.map(
          (index) {
            final e = werePresent[index];
            final name = e == 'Stagiaire' ? studentName : e;

            return PdfBulletPoint(
              textStyle: textStyle,
              child:
                  pw.Text(name, style: textStyle ?? PdfTheme.textStyleNormal),
            );
          },
        )
      ],
    );
  }
}
