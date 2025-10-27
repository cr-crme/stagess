import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/availability_status.dart';
import 'package:stagess/common/extensions/enterprise_extension.dart';
import 'package:stagess/common/extensions/job_extension.dart';
import 'package:stagess/common/widgets/disponibility_circle.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';

final _logger = Logger('EnterpriseCard');

class EnterpriseCard extends StatelessWidget {
  const EnterpriseCard({
    super.key,
    required this.enterprise,
    required this.onTap,
  });

  final Enterprise enterprise;
  final void Function(Enterprise enterprise) onTap;

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building EnterpriseCard for enterprise with id: ${enterprise.id}',
    );

    final schoolId = AuthProvider.of(context, listen: false).schoolId ?? '';

    final jobs = [...enterprise.jobs];
    final availableJobs = [...enterprise.availablejobs(context)];
    jobs.sort(
      (a, b) => a.specialization.name.toLowerCase().compareTo(
        b.specialization.name.toLowerCase(),
      ),
    );

    return Card(
      elevation: 10,
      child: ListTile(
        onTap: () => onTap(enterprise),
        title: Text(
          enterprise.name,
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Visibility(
              visible:
                  enterprise.address != null ||
                  enterprise.headquartersAddress != null,
              child: Text(
                enterprise.address != null
                    ? enterprise.address.toString()
                    : enterprise.headquartersAddress.toString(),
                style: TextStyle(color: Colors.grey[800]),
              ),
            ),
            ...(enterprise.status != EnterpriseStatus.active
                ? [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
                    child: Text(
                      'Aucun métier actif pour cette entreprise',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                ]
                : jobs.isEmpty
                ? [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 8, bottom: 4),
                    child: Text(
                      'Aucun métier actif pour cette entreprise',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                ]
                : jobs.map((job) {
                  final status = AvailabilityStatus.fromJob(
                    context,
                    enterprise: enterprise,
                    job: job,
                    availableJobs: availableJobs,
                  );

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        DisponibilityCircle(
                          positionsOffered: job.positionsOffered[schoolId] ?? 0,
                          positionsOccupied: job.positionsOccupied(
                            context,
                            listen: true,
                          ),
                          enabled: status.isEnabled,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            job.specialization.idWithName,
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                        ),
                      ],
                    ),
                  );
                })),
          ],
        ),
        trailing: Visibility(
          visible:
              jobs.lastWhereOrNull((e) => e.incidents.hasMajorIncident) != null,
          child: Tooltip(
            message:
                'Il y a au moins eu un accident répertorié pour cette entreprise',
            margin: EdgeInsets.only(
              left: MediaQuery.of(context).size.width / 4,
              right: 12,
            ),
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
    );
  }
}
