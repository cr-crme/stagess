import 'package:pdf/widgets.dart' as pw;
import 'package:stagess/common/pdf_widgets/pdf_bullet_points.dart';

class PdfWerePresentAtMeeting extends pw.StatelessWidget {
  PdfWerePresentAtMeeting(
      {required this.werePresent, required this.studentName, this.textStyle});

  final List<String> werePresent;
  final String studentName;
  final pw.TextStyle? textStyle;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Column(
      children: [
        ...werePresent.map(
          (e) {
            final name = e == 'Stagiaire' ? studentName : e;

            return pw.Padding(
              padding: pw.EdgeInsets.only(top: 8),
              child: PdfBulletPoint(
                textStyle: textStyle,
                child: pw.Text(name, style: textStyle),
              ),
            );
          },
        )
      ],
    );
  }
}
