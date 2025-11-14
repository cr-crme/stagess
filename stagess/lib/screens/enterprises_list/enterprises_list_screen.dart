import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/enterprise_extension.dart';
import 'package:stagess/common/extensions/job_extension.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/common/widgets/search.dart';
import 'package:stagess/router.dart';
import 'package:stagess/screens/add_enterprise/add_enterprise_screen.dart';
import 'package:stagess/screens/enterprises_list/widgets/enterprise_card.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job_list.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/itineraries/waypoint.dart';
import 'package:stagess_common/models/persons/person.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/widgets/cached_flutter_map.dart';

final _logger = Logger('EnterprisesListScreen');

class EnterprisesListScreen extends StatefulWidget {
  const EnterprisesListScreen({super.key});

  static const route = '/enterprises';

  @override
  State<EnterprisesListScreen> createState() => _EnterprisesListScreenState();
}

class _EnterprisesListScreenState extends State<EnterprisesListScreen>
    with SingleTickerProviderStateMixin {
  final _enterpriseKey = GlobalKey<_EnterprisesByListState>();
  bool _withSearchBar = false;

  late final _tabController = TabController(
    initialIndex: 0,
    length: 2,
    vsync: this,
  )..addListener(() => setState(() {}));

  void _search() => setState(() => _withSearchBar = !_withSearchBar);

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building EnterprisesListScreen');

    final appBar = ResponsiveService.appBarOf(
      context,
      title: const Text('Entreprises'),
      actions: [
        if (_tabController.index == 0)
          IconButton(onPressed: _search, icon: const Icon(Icons.search)),
        IconButton(
          onPressed: () {
            _withSearchBar = false;
            _enterpriseKey.currentState?.searchController.text = '';
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => Dialog(child: AddEnterpriseScreen()),
            );
          },
          tooltip: 'Ajouter une entreprise',
          icon: const Icon(Icons.add),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.list),
                SizedBox(width: 8),
                Text('Vue liste'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map),
                SizedBox(width: 8),
                Text('Vue carte'),
              ],
            ),
          ),
        ],
      ),
    );

    final enterprises = EnterprisesProviderExtension.availableEnterprisesOf(
      context,
      listen: true,
    );

    return ResponsiveService.scaffoldOf(
      context,
      appBar: appBar,
      smallDrawer: MainDrawer.small,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: TabBarView(
        controller: _tabController,
        children: [
          SizedBox(
            width: 100,
            child: _EnterprisesByList(
              key: _enterpriseKey,
              withSearchBar: _withSearchBar,
              enterprises: enterprises,
            ),
          ),
          _EnterprisesByMap(enterprises: enterprises),
        ],
      ),
    );
  }
}

class _EnterprisesByList extends StatefulWidget {
  const _EnterprisesByList({
    super.key,
    required this.withSearchBar,
    required this.enterprises,
  });

  final bool withSearchBar;
  final List<Enterprise> enterprises;

  @override
  State<_EnterprisesByList> createState() => _EnterprisesByListState();
}

class _EnterprisesByListState extends State<_EnterprisesByList> {
  bool _hideNotAvailable = false;
  late final searchController = TextEditingController()
    ..addListener(() => setState(() {}));

  List<Enterprise> _sortEnterprisesByName(List<Enterprise> enterprises) {
    _logger.finer('Sorting enterprises by name');

    final res = List<Enterprise>.from(enterprises);
    res.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return res.toList();
  }

  List<Enterprise> _filterSelectedEnterprises(List<Enterprise> enterprises) {
    _logger.finer(
      'Filtering enterprises based on search and availability '
      '(searchController.text: ${searchController.text}, '
      'hideNotAvailable: $_hideNotAvailable)',
    );

    final schoolId = AuthProvider.of(context, listen: false).schoolId;
    if (schoolId == null) return enterprises;

    return enterprises.where((enterprise) {
      // Remove if should not be shown by filter availability filter
      if (_hideNotAvailable &&
          enterprise.availablejobs(context).every(
                (job) =>
                    job.positionsRemaining(
                      context,
                      schoolId: schoolId,
                      listen: true,
                    ) <=
                    0,
              )) {
        return false;
      }

      final textToSearch = searchController.text.toLowerCase().trim();

      // Perform the searchbar filter
      if (enterprise.name.toLowerCase().contains(textToSearch)) {
        return true;
      }
      if (enterprise.availablejobs(context).any((job) {
        final hasSpecialization =
            job.specialization.name.toLowerCase().contains(textToSearch);
        final hasSector = job.specialization.sector.name.toLowerCase().contains(
              textToSearch,
            );
        return hasSpecialization || hasSector;
      })) {
        return true;
      }
      if (enterprise.activityTypes.any(
        (type) => type.name.toLowerCase().contains(textToSearch),
      )) {
        return true;
      }
      if (enterprise.address.toString().toLowerCase().contains(textToSearch)) {
        return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building _EnterprisesByList');

    // Register to the enterprises provider to refresh the list if it changes
    EnterprisesProvider.of(context, listen: true);

    final enterprises = _sortEnterprisesByName(
      _filterSelectedEnterprises(widget.enterprises),
    );

    return Column(
      children: [
        if (widget.withSearchBar)
          Container(
            decoration: BoxDecoration(color: Theme.of(context).primaryColor),
            child: Search(controller: searchController),
          ),
        SwitchListTile(
          title: const Text('N\'afficher que les stages disponibles'),
          value: _hideNotAvailable,
          onChanged: (value) => setState(() => _hideNotAvailable = value),
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: enterprises.length,
            itemBuilder: (context, index) => EnterpriseCard(
              enterprise: enterprises.elementAt(index),
              onTap: (enterprise) => GoRouter.of(context).goNamed(
                Screens.enterprise,
                pathParameters: Screens.params(enterprise),
                queryParameters: Screens.queryParams(pageIndex: '0'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EnterprisesByMap extends StatelessWidget {
  const _EnterprisesByMap({required this.enterprises});

  final List<Enterprise> enterprises;

  List<Marker> _latlngToMarkers(
    BuildContext context,
    Map<Enterprise, Waypoint> enterprises,
  ) {
    _logger.finer(
      'Converting enterprises to markers (enterprises: ${enterprises.length})',
    );
    List<Marker> out = [];

    final schoolId = AuthProvider.of(context, listen: false).schoolId;
    if (schoolId == null) return out;

    const double markerSize = 40;
    for (final i in enterprises.keys.toList().asMap().keys) {
      // i == 0 is the school
      final enterprise = enterprises.keys.toList()[i];
      final remainingPositions = enterprise.jobsWithRemainingPositions(context,
          schoolId: schoolId, listen: true);

      double nameWidth = 160;
      double nameHeight = 100;
      final waypoint = enterprises[enterprise]!;
      final color = i == 0
          ? Colors.purple
          : enterprise.status == EnterpriseStatus.active
              ? (remainingPositions.isNotEmpty ? Colors.green : Colors.red)
              : Colors.grey;

      out.add(
        Marker(
          point: waypoint.toLatLng(),
          alignment: const Alignment(0.8, 0.0), // Centered almost at max right
          width: markerSize + nameWidth,
          height: markerSize + nameHeight,
          child: Row(
            children: [
              GestureDetector(
                onTap: i == 0
                    ? null
                    : () => GoRouter.of(context).goNamed(
                          Screens.enterprise,
                          pathParameters: Screens.params(enterprise),
                          queryParameters: Screens.queryParams(pageIndex: '0'),
                        ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(75),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    i == 0 ? Icons.school : Icons.location_on_sharp,
                    size: markerSize,
                    color: color,
                  ),
                ),
              ),
              if (waypoint.showTitle)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: color.withAlpha(125),
                    shape: BoxShape.rectangle,
                  ),
                  child: Text(waypoint.title),
                ),
            ],
          ),
        ),
      );
    }
    return out;
  }

  Map<Enterprise, Waypoint> _fetchEnterprisesCoordinates(
    BuildContext context,
  ) {
    _logger.finer(
      'Fetching enterprises coordinates (enterprises: ${enterprises.length})',
    );
    final Map<Enterprise, Waypoint> out = {};

    final schoolBoard =
        SchoolBoardsProvider.of(context, listen: false).currentSchoolBoard;
    if (schoolBoard == null) return out;
    final school =
        SchoolBoardsProvider.of(context, listen: false).currentSchool;
    if (school == null) return out;

    final schoolAsEnterprise = Enterprise(
      schoolBoardId: schoolBoard.id,
      status: EnterpriseStatus.active,
      name: school.name,
      activityTypes: {},
      recruiterId: '',
      jobs: JobList(),
      contact: Person.empty,
      address: school.address,
    );
    out[schoolAsEnterprise] =
        Waypoint(title: school.name, address: school.address);

    for (final enterprise in enterprises) {
      out[enterprise] = Waypoint(
        title: enterprise.name,
        address: enterprise.address ?? Address.empty,
      );
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building _EnterprisesByMap');
    Map<Enterprise, Waypoint> locations = _fetchEnterprisesCoordinates(context);
    final waypoint = locations[locations.keys.first]!;

    return SingleChildScrollView(
        physics: const ScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 150,
          child: CachedFlutterMap(
            options:
                MapOptions(initialCenter: waypoint.toLatLng(), initialZoom: 14),
            markersOverlayBuilder: (context) => MarkerLayer(
              markers: _latlngToMarkers(context, locations),
            ),
          ),
        ));
  }
}
