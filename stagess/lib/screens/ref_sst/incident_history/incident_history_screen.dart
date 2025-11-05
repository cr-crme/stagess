import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/enterprise_extension.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/common/widgets/search.dart';
import 'package:stagess/screens/ref_sst/incident_history/models/incidents_by_enterprise.dart';
import 'package:stagess/screens/ref_sst/incident_history/widgets/incident_list_tile.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';

final _logger = Logger('IncidentHistoryScreen');

enum _FilterType { bySpecialization, byNumberOfIncident }

class IncidentHistoryScreen extends StatelessWidget {
  const IncidentHistoryScreen({super.key});
  static const route = '/incident-history';

  Future<void> _fetchEnterprises(BuildContext context) async {
    final enterprises = EnterprisesProvider.of(context, listen: false);
    await Future.wait([
      ...enterprises.map(
        (e) => enterprises.fetchData(
          id: e.id,
          fields: FetchableFields({'jobs': FetchableFields.all}),
        ),
      ),
    ]);
    return;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchEnterprises(context),
      builder: (context, snapshot) {
        final hasFullData = snapshot.connectionState == ConnectionState.done;

        return _IncidentHistoryScreenInternal(hasFullData: hasFullData);
      },
    );
  }
}

class _IncidentHistoryScreenInternal extends StatefulWidget {
  const _IncidentHistoryScreenInternal({required this.hasFullData});

  final bool hasFullData;

  @override
  State<_IncidentHistoryScreenInternal> createState() =>
      _IncidentHistoryScreenInternalState();
}

class _IncidentHistoryScreenInternalState
    extends State<_IncidentHistoryScreenInternal> {
  final _searchController = TextEditingController();
  bool _showSearchBar = false;
  var _currentFilter = _FilterType.byNumberOfIncident;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    super.dispose();
    _searchController.dispose();
  }

  Map<Specialization, IncidentsByEnterprise> _fetchAllIncidents(
      BuildContext context) {
    final enterprises = EnterprisesProviderExtension.availableEnterprisesOf(
      context,
    )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final textToSearch = _searchController.text.toLowerCase().trim();

    Map<Specialization, IncidentsByEnterprise> out = {};
    for (final enterprise in enterprises) {
      for (final job in enterprise.availablejobs(context)) {
        // Do not add if there is no incident
        if (job.incidents.isEmpty) continue;

        // If a search filter is added
        if (_showSearchBar && textToSearch != '') {
          if (!job.specialization.idWithName.toLowerCase().contains(
                textToSearch,
              )) {
            continue;
          }
        }

        if (!out.containsKey(job.specialization)) {
          out[job.specialization] = IncidentsByEnterprise();
        }
        out[job.specialization]!.add(
          enterprise,
          job.incidents.all.map((e) => e.incident).toList(),
        );
      }
    }

    return out;
  }

  List<Specialization> _filterBySpecialization(
    Map<Specialization, IncidentsByEnterprise> incidents,
  ) {
    _logger.finer(
      'Filtering by specialization with ${incidents.length} entries',
    );
    return incidents.keys.sorted((a, b) => a.name.compareTo(b.name)).toList();
  }

  List<Specialization> _filterByNumberOfIncident(
    Map<Specialization, IncidentsByEnterprise> incidents,
  ) {
    _logger.finer(
      'Filtering by number of incidents with ${incidents.length} entries',
    );
    return incidents.keys.sorted(
      (a, b) => incidents[b]!.length - incidents[a]!.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building IncidentHistoryScreen');

    final incidents = _fetchAllIncidents(context);

    late List<Specialization> sortedSpecializationId;
    switch (_currentFilter) {
      case _FilterType.bySpecialization:
        sortedSpecializationId = _filterBySpecialization(incidents);
        break;
      case _FilterType.byNumberOfIncident:
        sortedSpecializationId = _filterByNumberOfIncident(incidents);
    }

    return ResponsiveService.scaffoldOf(
      context,
      appBar: ResponsiveService.appBarOf(
        context,
        title: const Text('Historique d\'accidents'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _showSearchBar = !_showSearchBar),
            icon: const Icon(Icons.search),
          ),
        ],
        bottom: _showSearchBar ? Search(controller: _searchController) : null,
      ),
      smallDrawer: null,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: widget.hasFullData
          ? Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _FilterTile(
                        title: 'Tri par métier',
                        icon: Icons.work,
                        onTap: () => setState(
                          () => _currentFilter = _FilterType.bySpecialization,
                        ),
                        isSelected:
                            _currentFilter == _FilterType.bySpecialization,
                      ),
                    ),
                    Expanded(
                      child: _FilterTile(
                        title: 'Tri par nombre accidents',
                        icon: Icons.personal_injury_outlined,
                        onTap: () => setState(
                          () => _currentFilter = _FilterType.byNumberOfIncident,
                        ),
                        isSelected:
                            _currentFilter == _FilterType.byNumberOfIncident,
                      ),
                    ),
                  ],
                ),
                if (incidents.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 12.0,
                        left: 36,
                        right: 36,
                      ),
                      child: Text(
                        'Aucun incident ou blessure d\'élève n\'a été rapporté '
                        'par le personnel enseignant',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                if (incidents.isNotEmpty)
                  Expanded(
                    child: ListView.builder(
                      itemCount: incidents.length,
                      itemBuilder: (context, index) {
                        final specialization = sortedSpecializationId[index];
                        return IncidentListTile(
                          specializationId: specialization.id,
                          incidents: incidents[specialization]!,
                        );
                      },
                    ),
                  ),
              ],
            )
          : Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
    );
  }
}

class _FilterTile extends StatelessWidget {
  const _FilterTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final Function() onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building FilterTile for $title');

    return InkWell(
      onTap: onTap,
      child: Card(
        color:
            isSelected ? Theme.of(context).primaryColor.withAlpha(150) : null,
        child: Row(
          children: [
            const SizedBox(height: 48, width: 12),
            Icon(icon, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: isSelected ? Colors.white : null,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
