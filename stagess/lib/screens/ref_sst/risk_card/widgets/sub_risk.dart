import 'package:flutter/material.dart';
import 'package:stagess/screens/ref_sst/risk_card/widgets/factors.dart';
import 'package:stagess/screens/ref_sst/risk_card/widgets/introduction.dart';
import 'package:stagess/screens/ref_sst/risk_card/widgets/situation_risk.dart';
import 'package:stagess/screens/ref_sst/risk_card/widgets/sub_title.dart';
import 'package:stagess/screens/ref_sst/risk_card/widgets/symptoms.dart';
import 'package:stagess_common/models/ref_sst/risk.dart' as common_risk;

class SubRisk extends StatelessWidget {
  //params and variables
  const SubRisk(this.subRisks, {super.key});
  final List<common_risk.SubRisk> subRisks;

  @override
  Widget build(BuildContext context) {
    final subRiskWidgets = <Widget>[];

    for (int i = 0; i < subRisks.length; i++) {
      common_risk.SubRisk subRisk = subRisks[i];
      subRiskWidgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 36.0),
        child: Column(
          children: [
            if (subRisks.length > 1) SubTitle(subRisk.id, subRisk.title),
            if (subRisks.length <= 1) const SizedBox(height: 12),
            Introduction(subRisk.intro),
            if (subRisk.images.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(subRisk.images[0]),
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 40),
                    child: const Text('Illustration: Hervé Charbonneau'),
                  ),
                ],
              ),
            if (subRisk.situations.isNotEmpty)
              SituationRisk(subRisk.situations),
            if (subRisk.images.length > 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Image.asset(subRisk.images[1]),
                  Container(
                    margin: const EdgeInsets.only(top: 5, right: 40),
                    child: const Text('Illustration: Hervé Charbonneau'),
                  ),
                ],
              ),
            if (subRisk.factors.isNotEmpty) Factors(subRisk.factors),
            if (subRisk.symptoms.isNotEmpty) Symptoms(subRisk.symptoms)
          ],
        ),
      ));
    }
    return Column(children: subRiskWidgets);
  }
}
