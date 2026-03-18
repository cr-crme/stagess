import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stagess/common/provider_helpers/itineraries_helpers.dart';
import 'package:stagess/common/provider_helpers/students_helpers.dart';
import 'package:stagess/common/widgets/dialogs/show_pdf_dialog.dart';
import 'package:stagess/screens/visiting_students/itinerary_pdf_template.dart';
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
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('ItineraryMainScreen');

TextStyle _subtitleStyleOf(BuildContext context) => TextStyle(
      color: Theme.of(context).colorScheme.primary,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
String _newItineraryName = 'Nouvel itinéraire';

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

  void _fillAllWaypoints() {
    _logger.fine('Filling all waypoints');
    final internships = InternshipsProvider.of(context, listen: false);
    final currentTeacher =
        TeachersProvider.of(context, listen: false).currentTeacher;
    if (currentTeacher == null) return;

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
      Waypoint(
        title: 'École',
        address: school.address,
        priority: VisitingPriority.school,
      ),
    );

    // Get the students from the registered students, but we copy them so
    // we don't mess with them
    for (final student in students) {
      final studentInternships = internships.byStudentId(student.id);
      if (studentInternships.isEmpty) continue;
      final internship = studentInternships.last;

      final enterprise = enterprises.fromIdOrNull(internship.enterpriseId);
      if (enterprise == null) continue;

      _waypoints.add(
        Waypoint(
          title: '${student.firstName} ${student.lastName[0]}.',
          subtitle: enterprise.name,
          address: enterprise.address ?? Address.empty,
          priority: currentTeacher.visitingPriority(internship.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
      'Building ItineraryMainScreen with ${_waypoints.length} waypoints',
    );

    _fillAllWaypoints();
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
    itinerary: _currentItinerary,
    onItineraryChanged: _onItineraryChanged,
  );

  Future<void> _onItineraryChanged() async {
    await _saveItinerary();
    setState(() {});
  }

  void _acquireLock() async {
    while (!(await _teachersProvider.getLockForItem(
      _teachersProvider.currentTeacher!,
    ))) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    setState(() {
      _hasLock = true;
    });
  }

  // We need to access TeachersProvider when dispose is called so we save it
  // and update it each time we would have used it
  late var _teachersProvider = TeachersProvider.of(context, listen: false);
  late Itinerary _currentItinerary =
      _teachersProvider.currentTeacher?.itineraries.firstOrNull ??
          Itinerary(name: _newItineraryName);

  Future<void> _onSelectedItinerary(String? itineraryName) async {
    itineraryName ??= _currentItinerary.name;

    // Update the provider in case it has changed since the last time we used it
    _teachersProvider = TeachersProvider.of(context, listen: false);
    if (_teachersProvider.currentTeacher?.itineraries == null) return;

    final isNew = itineraryName == _newItineraryName;
    if (isNew) {
      final formKey = GlobalKey<FormState>();

      final isSuccess = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
                title: const Text('Créer un nouvel itinéraire'),
                content: Form(
                  key: formKey,
                  child: TextFormField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Nom de l\'itinéraire',
                    ),
                    maxLength: 50,
                    initialValue: '',
                    onChanged: (newValue) => itineraryName = newValue,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Le nom de l\'itinéraire ne peut pas être vide.';
                      } else if (value == _newItineraryName) {
                        return 'Veuillez choisir un nom différent de "$_newItineraryName".';
                      } else if (_teachersProvider.currentTeacher!.itineraries
                              .any((itinerary) => itinerary.name == value) ==
                          true) {
                        return 'Vous avez déjà un itinéraire avec ce nom.';
                      }
                      return null;
                    },
                  ),
                ),
                actions: [
                  if (_teachersProvider.currentTeacher!.itineraries.isNotEmpty)
                    OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Annuler'),
                    ),
                  TextButton(
                    onPressed: () {
                      if (!(formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: const Text('Confirmer'),
                  ),
                ],
              ));
      if (isSuccess != true || !mounted) return;

      if (_currentItinerary.name.isEmpty) {
        showSnackBar(context,
            message: 'Le nom de l\'itinéraire ne peut pas être vide.');
        return;
      }
    } else if (itineraryName == _currentItinerary.name) {
      return;
    }

    _currentItinerary = _teachersProvider.currentTeacher!.itineraries
        .firstWhere((e) => e.name == itineraryName!,
            orElse: () => Itinerary(name: itineraryName!));
    if (isNew) {
      await ItinerariesHelpers.add(_currentItinerary,
          teachers: _teachersProvider);
    }
    _routingController.setItinerary(_currentItinerary);

    final preferences = await SharedPreferences.getInstance();
    preferences.setString('last_itinerary_name', _currentItinerary.name);
  }

  Future<void> _saveItinerary() async {
    bool isSuccess =
        await _routingController.saveItinerary(teachers: _teachersProvider);
    if (!isSuccess) {
      if (!mounted) return;
      showSnackBar(
        context,
        message:
            'Une erreur est survenue lors de l\'enregistrement de l\'itinéraire.',
      );
    }
  }

  @override
  void initState() {
    super.initState();

    // Select the last itinerary used if exists, otherwise select the first one
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_teachersProvider.currentTeacher!.itineraries.isEmpty) {
        await _onSelectedItinerary(_newItineraryName);
        await _saveItinerary();
      }

      final preferences = await SharedPreferences.getInstance();
      final itineraryName = preferences.getString('last_itinerary_name');

      _currentItinerary = _teachersProvider.currentTeacher!.itineraries
          .firstWhere((e) => e.name == itineraryName,
              orElse: () => _currentItinerary);
      _routingController.setItinerary(_currentItinerary);
      setState(() {});
    });

    _acquireLock();
  }

  @override
  void dispose() {
    _teachersProvider.releaseLockForItem(_teachersProvider.currentTeacher!);
    _routingController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building ItineraryMainScreen for itinerary ${_currentItinerary.name}');

    // We need to define small 200px over actual small screen width because of the
    // row nature of the page.
    final isSmall = MediaQuery.of(context).size.width <
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
                child: _map(),
              ),
              Flexible(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.blueGrey.withAlpha(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(4.0),
                        child: Column(
                          children: [
                            _buildDropdownMenu(
                                itineraries: [
                              ...?_teachersProvider.currentTeacher?.itineraries
                            ]..sort((a, b) => a.name.compareTo(b.name))),
                            _studentsToVisitWidget(context),
                          ],
                        ),
                      ),
                      _Distance(
                        _routingController.distances,
                        itinerary: _currentItinerary,
                      ),
                      SizedBox(height: 12.0),
                    ],
                  ),
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

  Widget _buildDropdownMenu({required List<Itinerary> itineraries}) =>
      LayoutBuilder(
        builder: (context, constraints) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(40),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButton<String?>(
                icon: Icon(Icons.arrow_drop_down_outlined, size: 36),
                value: _currentItinerary.name == _newItineraryName
                    ? _currentItinerary.name
                    : _currentItinerary.name,
                items: [
                  ...itineraries.map((e) => _buildDropdownItem(
                      itineraryName: e.name, constraints: constraints)),
                  _buildDropdownItem(
                      itineraryName: _newItineraryName,
                      constraints: constraints),
                ],
                onChanged: _onSelectedItinerary,
              ),
            ),
          ],
        ),
      );

  DropdownMenuItem<String> _buildDropdownItem(
          {required String itineraryName,
          required BoxConstraints constraints}) =>
      DropdownMenuItem(
        value: itineraryName,
        child: SizedBox(
            width: constraints.maxWidth - 36,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(itineraryName),
                ),
                if (itineraryName == _newItineraryName)
                  Icon(Icons.add, size: 30, color: Colors.green),
              ],
            )),
      );

  Widget _map() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: MediaQuery.of(context).size.height * 0.5,
          child: widget.waypoints.isEmpty
              ? Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    RoutingMap(
                      controller: _routingController,
                      waypoints:
                          widget.waypoints.length == 1 ? [] : widget.waypoints,
                      centerWaypoint: widget.waypoints.first,
                      itinerary: _currentItinerary,
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
        ReorderableListView.builder(
          onReorder: (oldIndex, newIndex) {
            _routingController.move(oldIndex, newIndex);
            setState(() {});
          },
          buildDefaultDragHandles: !kIsWeb,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemBuilder: (context, index) {
            final way = _currentItinerary[index];
            return WaypointCard(
              key: ValueKey(way.id),
              index: index,
              name: way.title,
              waypoint: way,
              onDelete: () => _routingController.removeFromItinerary(index),
            );
          },
          itemCount: _currentItinerary.length,
        ),
      ],
    );
  }
}

class _Distance extends StatelessWidget {
  const _Distance(this.distances, {required this.itinerary});

  final List<double>? distances;
  final Itinerary itinerary;

  @override
  Widget build(BuildContext context) {
    if (distances == null) return Container();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  'Kilométrage\u00a0: '
                  '${(distances!.isEmpty ? 0 : distances!.reduce((a, b) => a + b).toDouble() / 1000).toStringAsFixed(1)}km',
                  style: _subtitleStyleOf(context),
                ),
              ),
              _exportToPdfButton(context),
            ],
          ),
          ..._distancesTo(distances!),
        ],
      ),
    );
  }

  List<Widget> _distancesTo(List<double?> distances) {
    List<Widget> out = [];
    if (distances.length + 1 != itinerary.length) return out;

    for (int i = 0; i < distances.length; i++) {
      final distance = distances[i];
      final startingPoint = itinerary[i];
      final endingPoint = itinerary[i + 1];

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

  Widget _exportToPdfButton(BuildContext context) {
    final hasItinerary = itinerary.length >= 2;

    return IconButton(
      onPressed: hasItinerary
          ? () => showPdfDialog(context,
              pdfGeneratorCallback: (context, format) => generateItineraryPdf(
                  context, format,
                  itineraryName: itinerary.name))
          : null,
      icon: Icon(Icons.picture_as_pdf,
          color: hasItinerary ? Theme.of(context).primaryColor : Colors.grey),
    );
  }
}
