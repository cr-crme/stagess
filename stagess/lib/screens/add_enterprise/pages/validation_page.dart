import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/enterprise_activity_type_list_tile.dart';
import 'package:stagess_common_flutter/widgets/enterprise_job_list_tile.dart';

final _logger = Logger('ValidationPage');

class ValidationPage extends StatelessWidget {
  const ValidationPage({
    super.key,
    required this.enterprise,
    required this.activityTypeController,
    required this.jobControllers,
  });

  final Enterprise enterprise;
  final EnterpriseActivityTypeListController? activityTypeController;
  final List<EnterpriseJobListController>? jobControllers;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building ValidationPage');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SubTitle('Coordonnées de l\'établissement', left: 0),
          const SizedBox(height: 4),
          Text(
            'Nom de l\'entreprise',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(enterprise.name.isEmpty ? 'Non spécifié' : enterprise.name),
          const SizedBox(height: 8),
          Text('Adresse', style: Theme.of(context).textTheme.titleSmall),
          Text(enterprise.address?.toString() ?? 'Non spécifiée'),
          const SizedBox(height: 8),
          Text(
            'Téléphone de l\'établissement',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            enterprise.phone.toString().isEmpty
                ? 'Non spécifié'
                : enterprise.phone.toString(),
          ),
          const SizedBox(height: 16),
          const SubTitle('Entreprise représentée par', left: 0),
          const SizedBox(height: 4),
          Text(
            'Nom de la personne représentant l\'entreprise',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            enterprise.contact.fullName.isEmpty
                ? 'Non spécifié'
                : enterprise.contact.fullName,
          ),
          const SizedBox(height: 8),
          Text('Fonction', style: Theme.of(context).textTheme.titleSmall),
          Text(
            enterprise.contactFunction.isEmpty
                ? 'Non spécifiée'
                : enterprise.contactFunction,
          ),
          const SizedBox(height: 8),
          Text('Téléphone', style: Theme.of(context).textTheme.titleSmall),
          Text(
            enterprise.contact.phone.toString().isEmpty
                ? 'Non spécifié'
                : enterprise.contact.phone.toString(),
          ),
          const SizedBox(height: 8),
          Text('Courriel', style: Theme.of(context).textTheme.titleSmall),
          Text(
            (enterprise.contact.email?.isEmpty ?? true)
                ? 'Non spécifié'
                : enterprise.contact.email!,
          ),
          const SizedBox(height: 16),
          Text(
            'Types d\'activités',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          enterprise.activityTypes.isEmpty || activityTypeController == null
              ? const Text('Non spécifiés')
              : EnterpriseActivityTypeListTile(
                hideTitle: true,
                subtitle:
                    '* Sélectionner les mots clefs illustrant les activités de l’entreprise',
                controller: activityTypeController!,
                editMode: false,
                activityTabAtTop: false,
              ),
          const SizedBox(height: 16),
          if (jobControllers != null)
            ...jobControllers!.map(
              (controller) => EnterpriseJobListTile(
                key: UniqueKey(),
                schools:
                    SchoolBoardsProvider.of(
                              context,
                              listen: false,
                            ).currentSchool ==
                            null
                        ? []
                        : [
                          SchoolBoardsProvider.of(
                            context,
                            listen: false,
                          ).currentSchool!,
                        ],
                elevation: 0,
                initialExpandedState: true,
                canChangeExpandedState: false,
                jobPickerPadding: const EdgeInsets.only(
                  left: 12.0,
                  right: 24.0,
                ),
                controller: controller,
              ),
            ),
        ],
      ),
    );
  }
}
