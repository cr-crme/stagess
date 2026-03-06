import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/itemized_text.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';

final _logger = Logger('IncidentsExpansionPanel');

class IncidentsExpansionPanel extends StatelessWidget {
  const IncidentsExpansionPanel({
    super.key,
    required this.enterprise,
    required this.job,
    required this.addSstEvent,
  });

  final Enterprise enterprise;
  final Job job;
  final void Function(Job job) addSstEvent;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building IncidentsExpansionPanel for job: ${job.specialization.name}');

    return AnimatedExpandingCard(
      elevation: 0.0,
      header: (context, isExpanded) => ListTile(
        title: const Text('Accidents et incidents en stage'),
        trailing: Visibility(
          visible: job.incidents.hasMajorIncident,
          child: Tooltip(
            message: 'Il y a au moins eu un incident majeur répertorié'
                ' pour cette entreprise',
            margin: EdgeInsets.only(
                left: MediaQuery.of(context).size.width / 4, right: 12),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.warning_amber,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 24.0, right: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIncidents(context,
                titleIfNotHasIncidents: 'Aucune blessure grave d\'élève',
                titleIfHasIncidents: 'Blessures graves d\'élèves',
                incidents: job.incidents.severeInjuries),
            const SizedBox(height: 16),
            _buildIncidents(context,
                titleIfNotHasIncidents:
                    'Aucun cas d\'agression ou de harcèlement',
                titleIfHasIncidents: 'Cas d\'agression ou de harcèlement',
                incidents: job.incidents.verbalAbuses),
            const SizedBox(height: 16),
            _buildIncidents(context,
                titleIfNotHasIncidents: 'Aucune blessure mineure',
                titleIfHasIncidents: 'Blessures mineures d\'élèves',
                incidents: job.incidents.minorInjuries),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () => addSstEvent(job),
                child: const Text('Signaler un incident'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidents(
    BuildContext context, {
    required String titleIfNotHasIncidents,
    required String titleIfHasIncidents,
    required List<Incident> incidents,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          incidents.isEmpty ? titleIfNotHasIncidents : titleIfHasIncidents,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (incidents.isNotEmpty)
          ItemizedText(incidents.map((e) {
            final teacher =
                TeachersProvider.of(context, listen: false).fromId(e.teacherId);
            return '${e.toString()}\nIncident rapporté par ${teacher.fullName}, le ${DateFormat.yMMMEd('fr_CA').format(e.date)}';
          }).toList()),
      ],
    );
  }
}
