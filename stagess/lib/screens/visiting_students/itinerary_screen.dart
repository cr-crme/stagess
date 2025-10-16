import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/provider_helpers/itineraries_helpers.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/screens/visiting_students/widgets/routing_map.dart';
import 'package:stagess/screens/visiting_students/widgets/waypoint_card.dart';
import 'package:stagess_common/models/generic/address.dart';
import 'package:stagess_common/models/itineraries/itinerary.dart';
import 'package:stagess_common/models/itineraries/visiting_priority.dart';
import 'package:stagess_common/models/itineraries/waypoint.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/custom_date_picker.dart';

final _logger = Logger('ItineraryMainScreen');

class ItineraryMainScreen extends StatefulWidget {
  const ItineraryMainScreen({super.key});

  static const route = '/itineraries';

  @override
  State<ItineraryMainScreen> createState() => _ItineraryMainScreenState();
}

class _ItineraryMainScreenState extends State<ItineraryMainScreen> {
  final List<Waypoint> _waypoints = [];
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fillAllWaypoints() async {
    _logger.fine('Filling all waypoints');
    final internships = InternshipsProvider.of(context, listen: false);

    var school = SchoolBoardsProvider.of(context, listen: false).currentSchool;
    if (!mounted || school == null) return;

    final enterprises = EnterprisesProvider.of(context, listen: false);
    if (enterprises.isEmpty) return;

    final students = {
      ...StudentsHelpers.mySupervizedStudents(
        context,
        listen: false,
        activeOnly: true,
      ),
    };
    if (!mounted) return;

    // Add the school as the first waypoint
    _waypoints.clear();
    _waypoints.add(
      await Waypoint.fromAddress(
        title: 'École',
        address: school.address,
        priority: VisitingPriority.school,
      ),
    );
    setState(() {});

    // Get the students from the registered students, but we copy them so
    // we don't mess with them
    for (final student in students) {
      final studentInternships = internships.byStudentId(student.id);
      if (studentInternships.isEmpty) continue;
      final internship = studentInternships.last;

      final enterprise = enterprises.fromIdOrNull(internship.enterpriseId);
      if (enterprise == null) continue;

      _waypoints.add(
        await Waypoint.fromAddress(
          title: '${student.firstName} ${student.lastName[0]}.',
          subtitle: enterprise.name,
          address: enterprise.address ?? Address.empty,
          priority: internship.visitingPriority,
        ),
      );
    }

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) => _fillAllWaypoints());
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building ItineraryMainScreen with ${_waypoints.length} waypoints',
    );

    return RawScrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      thickness: 7,
      minThumbLength: 75,
      thumbColor: Theme.of(context).primaryColor,
      radius: const Radius.circular(20),
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ScrollPhysics(),
        child: ItineraryScreen(waypoints: _waypoints),
      ),
    );
  }
}

class ItineraryScreen extends StatefulWidget {
  const ItineraryScreen({super.key, required this.waypoints});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
  final List<Waypoint> waypoints;
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  bool _hasLock = false;
  late final _routingController = RoutingController(
    destinations: widget.waypoints,
    itinerary: currentItinerary,
    onItineraryChanged: _onItineraryChanged,
  );

  void _onItineraryChanged() {
    setState(() {});
  }

  // We need to access TeachersProvider when dispose is called so we save it
  // and update it each time we would have used it
  late var _teachersProvider = TeachersProvider.of(context, listen: false);
  final _itineraries = <DateTime, Itinerary>{};
  Future<void> _selectItinerary(DateTime date) async {
    _teachersProvider = TeachersProvider.of(context, listen: false);

    while (!(await _teachersProvider.getLockForItem(
      _teachersProvider.currentTeacher!,
    ))) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    setState(() {
      _hasLock = true;
    });

    if (_itineraries[date] == null) {
      _itineraries[date] =
          ItinerariesHelpers.fromDate(
            date,
            teachers: _teachersProvider,
          )?.copyWith() ??
          Itinerary(date: date);
    }
    _routingController.setItinerary(
      _itineraries[date]!,
      teachers: _teachersProvider,
    );
  }

  late DateTime _currentDate;
  Itinerary get currentItinerary {
    if (_itineraries[_currentDate] == null) _selectItinerary(_currentDate);
    return _itineraries[_currentDate]!;
  }

  @override
  void initState() {
    super.initState();

    final date = DateTime.now();
    _currentDate = DateTime(date.year, date.month, date.day);
    _selectItinerary(_currentDate);
  }

  @override
  void dispose() {
    if (_routingController.hasChanged) {
      _routingController.saveItinerary(teachers: _teachersProvider);
    }
    _teachersProvider.releaseLockForItem(_teachersProvider.currentTeacher!);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building ItineraryMainScreen for date: $_currentDate');

    // We need to define small 200px over actual small screen width because of the
    // row nature of the page.
    final isSmall =
        MediaQuery.of(context).size.width <
        ResponsiveService.smallScreenWidth + 200;

    return Column(
      children: [
        if (_hasLock)
          Flex(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                isSmall ? CrossAxisAlignment.center : CrossAxisAlignment.start,
            direction: isSmall ? Axis.vertical : Axis.horizontal,
            children: [
              Flexible(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_showDate(), _map()],
                ),
              ),
              Flexible(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSmall) SizedBox(height: 60),
                    _Distance(
                      _routingController.distances,
                      itinerary: currentItinerary,
                    ),
                    _studentsToVisitWidget(context),
                  ],
                ),
              ),
            ],
          )
        else
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                SizedBox(
                  width: 300,
                  child: Text(
                    'Votre compte en cours de modification par votre administrateur. '
                    'Dès que possible, vous serez automatiquement connecté\u00b7e.',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _showDate() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Faire l\'itinéraire du\n${DateFormat('d MMMM yyyy', 'fr_CA').format(_currentDate)}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: _showDatePicker,
              borderRadius: BorderRadius.circular(30.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.calendar_month, size: 24),
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: IconButton(
              onPressed:
                  _routingController.hasChanged
                      ? () => _selectItinerary(_currentDate)
                      : null,
              icon: Icon(
                Icons.save,
                color:
                    _routingController.hasChanged
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showDatePicker() async {
    final newDate = await showCustomDatePicker(
      context: context,
      initialDate: _currentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 31)),
    );

    if (newDate == null || !mounted) return;

    // Keep only granularity of days
    _currentDate = DateTime(newDate.year, newDate.month, newDate.day);
    _selectItinerary(_currentDate);

    setState(() {});
  }

  Widget _map() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: MediaQuery.of(context).size.height * 0.5,
          child:
              widget.waypoints.isEmpty
                  ? Center(child: CircularProgressIndicator())
                  : Stack(
                    children: [
                      RoutingMap(
                        controller: _routingController,
                        waypoints:
                            widget.waypoints.length == 1
                                ? []
                                : widget.waypoints,
                        centerWaypoint: widget.waypoints.first,
                        itinerary: currentItinerary,
                        onItineraryChanged: (_) => setState(() {}),
                      ),
                      if (widget.waypoints.length == 1)
                        Container(
                          color: Colors.white.withAlpha(100),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
        );
      },
    );
  }

  Widget _studentsToVisitWidget(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        if (currentItinerary.isNotEmpty)
          ReorderableListView.builder(
            onReorder: (oldIndex, newIndex) {
              _routingController.move(oldIndex, newIndex);
              setState(() {});
            },
            buildDefaultDragHandles: !kIsWeb,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (context, index) {
              final way = currentItinerary[index];
              return WaypointCard(
                key: ValueKey(way.id),
                index: index,
                name: way.title,
                waypoint: way,
                onDelete: () => _routingController.removeFromItinerary(index),
              );
            },
            itemCount: currentItinerary.length,
          ),
      ],
    );
  }
}

class _Distance extends StatefulWidget {
  const _Distance(this.distances, {required this.itinerary});

  final List<double>? distances;
  final Itinerary itinerary;

  @override
  State<_Distance> createState() => __DistanceState();
}

class __DistanceState extends State<_Distance> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.distances == null) return Container();

    return GestureDetector(
      onTap: () {
        _isExpanded = !_isExpanded;
        setState(() {});
      },
      behavior: HitTestBehavior.opaque, // Make the full box clickable
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  child: Text(
                    'Kilométrage\u00a0: '
                    '${(widget.distances!.isEmpty ? 0 : widget.distances!.reduce((a, b) => a + b).toDouble() / 1000).toStringAsFixed(1)}km',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).disabledColor),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
            if (_isExpanded) ..._distancesTo(widget.distances!),
          ],
        ),
      ),
    );
  }

  List<Widget> _distancesTo(List<double?> distances) {
    List<Widget> out = [];
    if (distances.length + 1 != widget.itinerary.length) return out;

    for (int i = 0; i < distances.length; i++) {
      final distance = distances[i];
      final startingPoint = widget.itinerary[i];
      final endingPoint = widget.itinerary[i + 1];

      out.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
          child: Text(
            '${startingPoint.title} / ${endingPoint.title} : ${(distance! / 1000).toStringAsFixed(1)}km',
          ),
        ),
      );
    }

    return out;
  }
}
