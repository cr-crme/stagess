import 'package:flutter/material.dart';
import 'package:stagess/screens/ref_sst/risk_card/widgets/list_links.dart';
import 'package:stagess_common/models/ref_sst/risk.dart';

class Link extends StatelessWidget {
  //params and variables
  const Link(this.links, {super.key});
  final List<RiskLink> links;
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        margin: const EdgeInsets.only(top: 30, right: 25, left: 10, bottom: 10),
        child: ListTile(
          tileColor: Colors.grey[300],
          textColor: Colors.black,
          title: const Padding(
            padding: EdgeInsets.only(bottom: 5, top: 15),
            child: Text(
              'Pour aller plus loin',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 0, 0)),
            ),
          ),
          subtitle: ListLinks(links),
          isThreeLine: true,
        ),
      )
    ]);
  }
}
