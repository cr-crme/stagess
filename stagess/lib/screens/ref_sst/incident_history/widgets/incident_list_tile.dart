import 'package:flutter/material.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess/screens/ref_sst/incident_history/models/incidents_by_enterprise.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

class IncidentListTile extends StatelessWidget {
  const IncidentListTile({
    super.key,
    required this.specializationId,
    required this.incidents,
  });

  final String specializationId;
  final IncidentsByEnterprise incidents;

  @override
  Widget build(BuildContext context) {
    final specialization =
        ActivitySectorsService.specialization(specializationId);

    return AnimatedExpandingCard(
      header: (context, isExpanded) => Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12, left: 18),
              child: Text(
                specialization.name,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium!
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Tooltip(
            message: 'Nombre d\'accidents pour ce métier',
            child: Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        spreadRadius: 1,
                        blurRadius: 5,
                        color: Colors.grey,
                      )
                    ],
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(100)),
                child: Center(
                  child: Text(
                    '${incidents.length}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                )),
          )
        ],
      ),
      child: Column(
          children: incidents.enterprises
              .map((enterprise) => Padding(
                    padding: const EdgeInsets.only(left: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(enterprise.name),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ItemizedText(
                            incidents.description(enterprise)!,
                            interline: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ))
              .toList()),
    );
  }
}
