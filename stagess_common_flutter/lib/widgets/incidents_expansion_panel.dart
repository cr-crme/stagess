import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common_flutter/providers/admins_provider.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/dialogs/add_sst_event_dialog.dart';
import 'package:stagess_common_flutter/widgets/itemized_text.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('IncidentsExpansionPanel');

class IncidentsExpansionPanel extends StatelessWidget {
  const IncidentsExpansionPanel({
    super.key,
    required this.enterpriseId,
    required this.job,
    this.isExpandable = true,
  });

  final String? enterpriseId;
  final Job job;
  final bool isExpandable;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building IncidentsExpansionPanel for job: ${job.specialization.name}');

    return AnimatedExpandingCard(
      elevation: 0.0,
      canChangeExpandedState: isExpandable,
      initialExpandedState: !isExpandable,
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
            if (enterpriseId != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: ElevatedButton(
                    onPressed: () => _addSstEvent(context, job),
                    child: const Text('Signaler un incident'),
                  ),
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
            final user = TeachersProvider.of(context, listen: false)
                    .fromIdOrNull(e.userId)
                    ?.fullName ??
                AdminsProvider.of(context, listen: false)
                    .fromIdOrNull(e.userId)
                    ?.fullName ??
                'Une personne inconnue';
            return '${e.toString()}\nIncident rapporté par $user, le ${DateFormat.yMMMEd('fr_CA').format(e.date)}';
          }).toList()),
      ],
    );
  }

  void _addSstEvent(BuildContext context, Job job) async {
    _logger.finer('Adding SST event to job: ${job.specialization.name}');
    final enterprises = EnterprisesProvider.of(context, listen: false);
    final enterprise = enterprises.fromId(enterpriseId!);
    final userId = AuthProvider.of(context, listen: false).currentId;
    if (userId == null) return;

    final hasLock = await enterprises.getLockForItem(enterprise);
    if (!hasLock || !context.mounted) {
      if (context.mounted) {
        showSnackBar(
          context,
          message:
              'Impossible d\'ajouter un événement SST, car l\'entreprise est en cours de modification par un autre utilisateur.',
        );
      }
      return;
    }

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddSstEventDialog(),
    );
    if (result == null) {
      await enterprises.releaseLockForItem(enterprise);
      return;
    }

    final incident =
        Incident(userId: userId, date: DateTime.now(), result['description']);
    switch (result['eventType'] as SstEventType) {
      case SstEventType.severe:
        job.incidents.severeInjuries.add(incident);
        break;
      case SstEventType.verbal:
        job.incidents.verbalAbuses.add(incident);
        break;
      case SstEventType.minor:
        job.incidents.minorInjuries.add(incident);
        break;
    }
    enterprises[enterprise].jobs.replace(job);
    await enterprises.replaceWithConfirmation(enterprise);
    await enterprises.releaseLockForItem(enterprise);
    if (context.mounted) {
      showSnackBar(context, message: 'L\'événement SST a été ajouté');
    }
    _logger.finer('SST event added to job: ${job.specialization.name}');
  }
}
