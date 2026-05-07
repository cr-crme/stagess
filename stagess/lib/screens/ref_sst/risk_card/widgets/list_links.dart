import 'package:flutter/material.dart';
import 'package:stagess_common/models/ref_sst/risk.dart';
import 'package:url_launcher/url_launcher.dart';

class ListLinks extends StatelessWidget {
  //params and variables
  const ListLinks(this.links, {super.key});
  final List<RiskLink> links;
  @override
  Widget build(BuildContext context) {
    var widgetList = <Widget>[];
    for (RiskLink link in links) {
      widgetList.add(BuildALineOfALink(link));
    }
    return Column(children: widgetList);
  }
}

class BuildALineOfALink extends StatelessWidget {
  const BuildALineOfALink(this.link, {super.key});
  final RiskLink link;

  @override
  Widget build(BuildContext context) {
    final String linkTitle = link.title;
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: [
        TableRow(children: [
          Text(link.source),
          InkWell(
            onTap: () => _launchUrl(link.url),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                linkTitle,
                style: const TextStyle(
                    color: Colors.blue, decoration: TextDecoration.underline),
              ),
            ),
          )
        ])
      ],
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }
}
