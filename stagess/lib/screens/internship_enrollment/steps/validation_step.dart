import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/screens/internship_enrollment/steps/caracteristics_step.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/schedule_selector.dart';

final _logger = Logger('ValidationStep');

class ValidationStep extends StatelessWidget {
  const ValidationStep(
      {super.key,
      required this.internship,
      required this.weeklySchedulesController});

  final Internship? internship;
  final WeeklySchedulesController? weeklySchedulesController;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building ScheduleStep widget');

    final student = internship == null
        ? null
        : StudentsProvider.of(context).fromIdOrNull(internship!.studentId);
    final enterprise = internship == null
        ? null
        : EnterprisesProvider.of(context)
            .fromIdOrNull(internship!.enterpriseId);

    final specialization = [...(enterprise?.jobs.rawList ?? [])]
        .firstWhereOrNull((job) => job.id == internship?.jobId)
        ?.specialization;
    final extraSpecialization = internship?.extraSpecializationIds
        .map((id) => ActivitySectorsService.specialization(id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SubTitle('Stagiaire', left: 0),
        Text('Nom du stagiaire:',
            style: Theme.of(context).textTheme.titleSmall),
        Text(student?.fullName ?? 'Aucun stagiaire sélectionné'),
        const SizedBox(height: 8),
        const SubTitle('Métier(s)', left: 0),
        Text('Métier principal:',
            style: Theme.of(context).textTheme.titleSmall),
        Text(specialization?.idWithName ?? 'Aucun métier sélectionné'),
        if ((extraSpecialization ?? []).isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Métier(s) supplémentaire(s):',
                  style: Theme.of(context).textTheme.titleSmall),
              ...extraSpecialization!.map((e) => Text(e.idWithName)),
            ],
          ),
        SubTitle('Responsable en milieu de stage', left: 0),
        Text('Nom du responsable:',
            style: Theme.of(context).textTheme.titleSmall),
        Text(internship?.currentContract?.supervisor.fullName ??
            'Aucun responsable sélectionné'),
        const SizedBox(height: 8),
        Text('Téléphone du responsable:',
            style: Theme.of(context).textTheme.titleSmall),
        Text(internship?.currentContract?.supervisor.phone.toString().isEmpty ??
                true
            ? 'Non spécifié'
            : internship!.currentContract!.supervisor.phone.toString()),
        const SizedBox(height: 8),
        Text('Courriel du responsable:',
            style: Theme.of(context).textTheme.titleSmall),
        Text(internship?.currentContract?.supervisor.email.toString().isEmpty ??
                true
            ? 'Non spécifié'
            : internship!.currentContract!.supervisor.email.toString()),
        const SizedBox(height: 8),
        const SubTitle('Horaire du stage', left: 0),
        if (weeklySchedulesController == null ||
            weeklySchedulesController!.weeklySchedules.isEmpty)
          const Text(
            'Aucun horaire de stage sélectionné.',
            style: TextStyle(fontStyle: FontStyle.italic),
          )
        else
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 180,
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Date de début',
                          labelStyle: TextStyle(color: Colors.black),
                          border: InputBorder.none),
                      style: TextStyle(color: Colors.black),
                      controller: TextEditingController(
                          text: weeklySchedulesController!.dateRange == null
                              ? null
                              : DateFormat.yMMMEd('fr_CA').format(
                                  weeklySchedulesController!.dateRange!.start)),
                      enabled: false,
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Date de fin',
                          labelStyle: TextStyle(color: Colors.black),
                          border: InputBorder.none),
                      style: TextStyle(color: Colors.black),
                      controller: TextEditingController(
                          text: weeklySchedulesController!.dateRange == null
                              ? null
                              : DateFormat.yMMMEd('fr_CA').format(
                                  weeklySchedulesController!.dateRange!.end)),
                      enabled: false,
                    ),
                  ),
                ],
              ),
              ScheduleSelector(
                scheduleController: weeklySchedulesController!,
                editMode: false,
              ),
            ],
          ),
        SubTitle('Nombre d\'heures prévues', left: 0),
        Text(internship?.expectedDuration == null ||
                (internship?.expectedDuration ?? -1) <= 0
            ? 'Non spécifié'
            : 'L\'élève devra réaliser : ${internship?.expectedDuration}h de stage'),
        TransportationsCheckBoxes(
          withTitle: true,
          editMode: false,
          transportations: internship?.currentContract?.transportations ?? [],
        ),
        SubTitle('Fréquence des visites de l\'enseignant·e', left: 0),
        Text(internship?.currentContract?.visitFrequencies == null ||
                (internship?.currentContract?.visitFrequencies.isEmpty == true)
            ? 'Non spécifié'
            : internship!.currentContract!.visitFrequencies),
      ],
    );
  }
}
