import 'package:flutter/material.dart';
import 'package:stagess_common/models/ref_sst/risk.dart';

//SST
class ClickableRiskTile extends StatelessWidget {
  //params and variables
  const ClickableRiskTile(this.risk, {super.key, required this.onTap});
  final Risk risk;
  final Function(Risk) onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 0.5,
        child: ListTile(
          title: Text(
            'FICHE ${risk.number}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          subtitle: Text(
            risk.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          isThreeLine: true,
          onTap: () => onTap(risk),
        ));
  }
}
