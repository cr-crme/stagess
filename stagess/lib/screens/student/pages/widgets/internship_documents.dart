import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/screens/student/pages/pdf/internship_contract_pdf_template.dart';
import 'package:stagess/screens/student/pages/pdf/visa_pdf_template.dart';
import 'package:stagess_common/models/internships/internship.dart';

final _logger = Logger('InternshipDocuments');

class InternshipDocuments extends StatefulWidget {
  const InternshipDocuments({super.key, required this.internship});

  final Internship internship;

  @override
  State<InternshipDocuments> createState() => _InternshipDocumentsState();
}

class _InternshipDocumentsState extends State<InternshipDocuments> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building InternshipDocuments for internship: ${widget.internship.id}');

    try {
      return Padding(
        padding: const EdgeInsets.only(left: 24, right: 24),
        child: ExpansionPanelList(
          elevation: 0,
          expansionCallback: (index, isExpanded) =>
              setState(() => _isExpanded = !_isExpanded),
          children: [
            ExpansionPanel(
              isExpanded: _isExpanded,
              canTapOnHeader: true,
              headerBuilder: (context, isExpanded) => Text('Documents',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge!
                      .copyWith(color: Colors.black)),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => showPdfDialog(
                          context,
                          pdfGeneratorCallback: (context, format) =>
                              generateInternshipContractPdf(context, format,
                                  internshipId: widget.internship.id),
                        ),
                        child: Text(
                          'Contrat de stage',
                          style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => showPdfDialog(
                          context,
                          pdfGeneratorCallback: (context, format) =>
                              generateVisaPdf(context, format,
                                  internshipId: widget.internship.id),
                        ),
                        child: Text(
                          'VISA',
                          style: const TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      );
    } catch (e) {
      return SizedBox(
        height: 60,
        child: Center(
            child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor)),
      );
    }
  }
}
