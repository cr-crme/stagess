import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/extensions/availability_status.dart';
import 'package:stagess/common/extensions/enterprise_extension.dart';
import 'package:stagess/common/extensions/job_extension.dart';
import 'package:stagess/common/widgets/dialogs/add_sst_event_dialog.dart';
import 'package:stagess/common/widgets/dialogs/add_text_dialog.dart';
import 'package:stagess/common/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:stagess/common/widgets/dialogs/job_creator_dialog.dart';
import 'package:stagess/common/widgets/disponibility_circle.dart';
import 'package:stagess/common/widgets/sub_title.dart';
import 'package:stagess/screens/enterprise/pages/jobs_expansion_panels/comments_expansion_panel.dart';
import 'package:stagess/screens/enterprise/pages/jobs_expansion_panels/incidents_expansion_panel.dart';
import 'package:stagess/screens/enterprise/pages/jobs_expansion_panels/photo_expansion_panel.dart';
import 'package:stagess/screens/enterprise/pages/jobs_expansion_panels/prerequisites_expansion_panel.dart';
import 'package:stagess/screens/enterprise/pages/jobs_expansion_panels/sst_expansion_panel.dart';
import 'package:stagess/screens/enterprise/pages/jobs_expansion_panels/supervision_expansion_panel.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/enterprises/job_comment.dart';
import 'package:stagess_common/models/generic/photo.dart';
import 'package:stagess_common/models/persons/teacher.dart';
import 'package:stagess_common/services/image_helpers.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/school_boards_provider.dart';
import 'package:stagess_common_flutter/providers/teachers_provider.dart';
import 'package:stagess_common_flutter/widgets/animated_expanding_card.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

final _logger = Logger('JobsPage');

class JobsPage extends StatefulWidget {
  const JobsPage({
    super.key,
    required this.enterprise,
    required this.onAddInternshipRequest,
  });

  final Enterprise enterprise;
  final Function(Enterprise, Specialization) onAddInternshipRequest;

  @override
  State<JobsPage> createState() => JobsPageState();
}

class JobsPageState extends State<JobsPage> {
  final Map<String, UniqueKey> _cardKey = {};
  final Map<String, List> _expandedSections = {};
  final Map<String, GlobalKey<PrerequisitesBodyState>> _prerequisitesFormKeys =
      {};
  final Map<String, bool> _isEditingPrerequisites = {};

  bool _forceDisabled = false;
  bool get isEditing => _isEditingPrerequisites.containsValue(true);
  void cancelEditing() {
    _logger.info('Canceling editing in JobsPage');
    for (final e in _isEditingPrerequisites.keys) {
      _isEditingPrerequisites[e] = false;
    }
    EnterprisesProvider.of(
      context,
      listen: false,
    ).releaseLockForItem(widget.enterprise);
    _logger.fine('Editing cancelled in JobsPage');
    setState(() {});
  }

  Future<void> addJob() async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });
    _logger.finer('Adding job for enterprise: ${widget.enterprise.id}');
    final enterprises = EnterprisesProvider.of(context, listen: false);

    final hasLock = await enterprises.getLockForItem(widget.enterprise);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible d\'ajouter un poste, car l\'entreprise est en cours de modification par un autre utilisateur.',
        );
      }
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    // Building the dialog in a Scaffold allows for the Snackbar to be shown
    // over the dialog box
    final newJob = await showDialog<Job>(
      context: context,
      builder:
          (context) => Scaffold(
            backgroundColor: Colors.transparent,
            body: JobCreatorDialog(enterprise: widget.enterprise),
          ),
    );

    if (newJob == null) {
      await enterprises.releaseLockForItem(widget.enterprise);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }
    widget.enterprise.jobs.add(newJob);
    await enterprises.replaceWithConfirmation(widget.enterprise);
    await enterprises.releaseLockForItem(widget.enterprise);
    if (mounted) {
      showSnackBar(context, message: 'Le poste a bien été ajouté');
    }
    setState(() {
      _forceDisabled = false;
    });
    _logger.finer('Job added: ${newJob.specialization.name}');
  }

  void _addImage(Job job, ImageSource source) async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });
    _logger.finer('Adding image to job: ${job.specialization.name}');
    final enterprises = EnterprisesProvider.of(context, listen: false);

    final hasLock = await enterprises.getLockForItem(widget.enterprise);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible d\'ajouter une image, car l\'entreprise est en cours de modification par un autre utilisateur.',
        );
      }
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    late List<XFile?> images;
    if (source == ImageSource.camera) {
      images = [(await ImagePicker().pickImage(source: ImageSource.camera))];
    } else {
      images = await ImagePicker().pickMultiImage();
    }
    if (images.isEmpty) {
      await enterprises.releaseLockForItem(widget.enterprise);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    for (XFile? file in images) {
      if (file == null) continue;
      final Uint8List bytes = ImageHelpers.resizeImage(
        await (kIsWeb ? file.readAsBytes() : File(file.path).readAsBytes()),
        width: null,
        height: 350,
      );

      job.photos.add(Photo(bytes: bytes));
    }

    await enterprises.replaceWithConfirmation(widget.enterprise);
    await enterprises.releaseLockForItem(widget.enterprise);
    if (mounted) {
      showSnackBar(context, message: 'L\'image a été ajoutée');
    }
    setState(() {
      _forceDisabled = false;
    });
    _logger.finer('Image(s) added to job: ${job.specialization.name}');
  }

  void _removeImage(Job job, int index) async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });
    _logger.finer('Removing image from job: ${job.specialization.name}');
    final enterprises = EnterprisesProvider.of(context, listen: false);

    final hasLock = await enterprises.getLockForItem(widget.enterprise);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de supprimer une image, car l\'entreprise est en cours de modification par un autre utilisateur.',
        );
      }
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    job.photos.removeAt(index);

    await enterprises.replaceWithConfirmation(widget.enterprise);
    await enterprises.releaseLockForItem(widget.enterprise);
    if (mounted) {
      showSnackBar(context, message: 'L\'image a été supprimée');
    }
    setState(() {
      _forceDisabled = false;
    });
    _logger.finer('Image removed from job: ${job.specialization.name}');
  }

  void _addSstEvent(Job job) async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });
    _logger.finer('Adding SST event to job: ${job.specialization.name}');
    final enterprises = EnterprisesProvider.of(context, listen: false);

    final hasLock = await enterprises.getLockForItem(widget.enterprise);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible d\'ajouter un événement SST, car l\'entreprise est en cours de modification par un autre utilisateur.',
        );
      }
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AddSstEventDialog(),
    );
    if (result == null) {
      await enterprises.releaseLockForItem(widget.enterprise);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    final incident = Incident(result['description']);
    switch (result['eventType']) {
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
    enterprises[widget.enterprise].jobs.replace(job);
    await enterprises.replaceWithConfirmation(widget.enterprise);
    await enterprises.releaseLockForItem(widget.enterprise);
    if (mounted) {
      showSnackBar(context, message: 'L\'événement SST a été ajouté');
    }
    setState(() {
      _forceDisabled = false;
    });
    _logger.finer('SST event added to job: ${job.specialization.name}');
  }

  void _addComment(Job job) async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });

    _logger.finer('Adding comment to job: ${job.specialization.name}');
    final teacherId =
        TeachersProvider.of(context, listen: false).currentTeacher?.id;
    if (teacherId == null) {
      _logger.warning('No teacher ID found when adding comment to job.');
      showSnackBar(
        context,
        message: 'Vous devez être connecté pour ajouter un commentaire.',
      );
      setState(() {
        _forceDisabled = false;
      });
      return;
    }
    final enterprises = EnterprisesProvider.of(context, listen: false);
    final internship = InternshipsProvider.of(context, listen: false).where(
      (internship) =>
          internship.enterpriseId == widget.enterprise.id &&
          internship.supervisingTeacherIds.contains(teacherId),
    );
    if (internship.isEmpty) {
      _logger.warning(
        'No internship found for teacher ID when adding comment to job: $teacherId',
      );
      showSnackBar(
        context,
        message:
            'Vous devez avoir supervisé au moins un stage dans cette entreprise pour y ajouter un commentaire.',
      );
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    final hasLock = await enterprises.getLockForItem(widget.enterprise);
    if (!hasLock || !mounted) {
      if (mounted) {
        showSnackBar(
          context,
          message:
              'Impossible d\'ajouter un commentaire, car l\'entreprise est en cours de modification par un autre utilisateur.',
        );
      }
      setState(() {
        _forceDisabled = false;
      });
      return;
    }

    final newComment = await showDialog(
      barrierDismissible: false,
      context: context,
      builder:
          (context) => const AddTextDialog(title: 'Ajouter un commentaire'),
    );

    if (newComment == null) {
      await enterprises.releaseLockForItem(widget.enterprise);
      setState(() {
        _forceDisabled = false;
      });
      return;
    }
    job.comments.add(
      JobComment(
        comment: newComment,
        teacherId: teacherId,
        date: DateTime.now(),
      ),
    );
    await enterprises.replaceWithConfirmation(widget.enterprise);
    await enterprises.releaseLockForItem(widget.enterprise);
    if (mounted) {
      showSnackBar(context, message: 'Le commentaire a été ajouté');
    }
    setState(() {
      _forceDisabled = false;
    });
    _logger.finer('Comment added to job: ${job.specialization.name}');
  }

  void _updateSectionsIfNeeded() {
    for (Job job in widget.enterprise.jobs) {
      _cardKey.putIfAbsent(job.id, () => UniqueKey());
      _expandedSections.putIfAbsent(
        job.id,
        () => [false, false, false, false, false, false],
      );
      _prerequisitesFormKeys.putIfAbsent(
        job.id,
        () => GlobalKey<PrerequisitesBodyState>(),
      );
      _isEditingPrerequisites.putIfAbsent(job.id, () => false);
    }
  }

  Future<void> _onClickPrerequisiteEdit(Job job) async {
    if (_forceDisabled) return;
    setState(() {
      _forceDisabled = true;
    });

    // If we have to validate something before switching
    final enterprises = EnterprisesProvider.of(context, listen: false);
    if (_isEditingPrerequisites[job.id]!) {
      final formKey =
          _prerequisitesFormKeys[job.id]!.currentState!.formKey.currentState!;
      if (!formKey.validate()) {
        setState(() {
          _forceDisabled = false;
        });
        return;
      }

      final newJob = job.copyWith(
        minimumAge: _prerequisitesFormKeys[job.id]!.currentState!.minimumAge,
        preInternshipRequests: PreInternshipRequests.fromStrings(
          _prerequisitesFormKeys[job.id]!.currentState!.prerequisites,
        ),
        uniforms: _prerequisitesFormKeys[job.id]!.currentState!.uniforms,
        protections: _prerequisitesFormKeys[job.id]!.currentState!.protections,
      );
      if (job.getDifference(newJob).isNotEmpty) {
        widget.enterprise.jobs.replace(newJob);
        await enterprises.replaceWithConfirmation(widget.enterprise);
      }
      await enterprises.releaseLockForItem(widget.enterprise);

      if (mounted) {
        showSnackBar(context, message: 'Les informations ont été sauvegardées');
      }
    } else {
      final isSuccess = await enterprises.getLockForItem(widget.enterprise);
      if (!isSuccess) {
        if (mounted) {
          showSnackBar(
            context,
            message:
                'Impossible de modifier le poste, car celui-ci est en cours de modification par un autre utilisateur.',
          );
        }
        setState(() {
          _forceDisabled = false;
        });
        return;
      }
    }

    _isEditingPrerequisites[job.id] = !_isEditingPrerequisites[job.id]!;
    setState(() {
      _forceDisabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building JobsPage for enterprise: ${widget.enterprise.id}');

    final authProvider = AuthProvider.of(context, listen: false);

    _updateSectionsIfNeeded();

    final jobs = [...widget.enterprise.jobs];
    final availableJobs = [...widget.enterprise.availablejobs(context)];
    jobs.sort(
      (a, b) => a.specialization.name.toLowerCase().compareTo(
        b.specialization.name.toLowerCase(),
      ),
    );

    return jobs.isEmpty
        ? Center(
          child: Text(
            'Aucun poste disponible pour cette entreprise.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        )
        : ListView.builder(
          itemCount: jobs.length,
          itemBuilder: (context, index) {
            final job = jobs[index];

            final offered =
                job.positionsOffered[authProvider.schoolId ?? ''] ?? 0;
            final occupied = job.positionsOccupied(context, listen: true);

            final status = AvailabilityStatus.fromJob(
              context,
              enterprise: widget.enterprise,
              job: job,
              availableJobs: availableJobs,
            );

            return AnimatedExpandingCard(
              key: _cardKey[job.id],
              header:
                  (ctx, isExpanded) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SubTitle(job.specialization.name, top: 12, bottom: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _AvailablePlace(
                                  positionsOffered: offered,
                                  positionsOccupied: occupied,
                                  status: status,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (widget.enterprise.status ==
                                        EnterpriseStatus.active)
                                      Expanded(
                                        child: _RecrutedBy(
                                          enterprise: widget.enterprise,
                                        ),
                                      ),
                                    if (status ==
                                            AvailabilityStatus.isAvailable ||
                                        status == AvailabilityStatus.isFull)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 8.0,
                                          top: 4.0,
                                          bottom: 4.0,
                                        ),
                                        child: TextButton(
                                          onPressed:
                                              status ==
                                                      AvailabilityStatus
                                                          .isAvailable
                                                  ? () => widget
                                                      .onAddInternshipRequest(
                                                        widget.enterprise,
                                                        job.specialization,
                                                      )
                                                  : null,
                                          style: Theme.of(
                                            context,
                                          ).textButtonTheme.style!.copyWith(
                                            backgroundColor:
                                                WidgetStateProperty.resolveWith<
                                                  Color
                                                >(
                                                  (states) =>
                                                      states.contains(
                                                            WidgetState
                                                                .disabled,
                                                          )
                                                          ? Theme.of(
                                                            context,
                                                          ).disabledColor
                                                          : Theme.of(
                                                            context,
                                                          ).primaryColor,
                                                ),
                                          ),
                                          child: const Text(
                                            'Inscrire un\nstagiaire',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )
                                    else
                                      (SizedBox(height: 100)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
              initialExpandedState: jobs.length == 1,
              child: ExpansionPanelList(
                expansionCallback: (panelIndex, isExpanded) async {
                  if (isEditing) {
                    if (!await ConfirmExitDialog.show(
                      context,
                      content: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(
                              text:
                                  '** Vous quittez la page sans avoir '
                                  'cliqué sur Enregistrer ',
                            ),
                            WidgetSpan(
                              child: SizedBox(
                                height: 22,
                                width: 22,
                                child: Icon(
                                  Icons.save,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            const TextSpan(
                              text:
                                  '. **\n\nToutes vos modifications seront perdues.',
                            ),
                          ],
                        ),
                      ),
                    )) {
                      return;
                    }
                    cancelEditing();
                  }
                  _expandedSections[job.id]![panelIndex] = isExpanded;
                  setState(() {});
                },
                children: [
                  PrerequisitesExpansionPanel(
                    key: _prerequisitesFormKeys[job.id]!,
                    isExpanded: _expandedSections[job.id]![0],
                    isEditing: _isEditingPrerequisites[job.id]!,
                    enterprise: widget.enterprise,
                    job: job,
                    onClickEdit: () => _onClickPrerequisiteEdit(job),
                  ),
                  SstExpansionPanel(
                    isExpanded: _expandedSections[job.id]![1],
                    enterprise: widget.enterprise,
                    job: job,
                    addSstEvent: _addSstEvent,
                  ),
                  IncidentsExpansionPanel(
                    isExpanded: _expandedSections[job.id]![2],
                    enterprise: widget.enterprise,
                    job: job,
                    addSstEvent: _addSstEvent,
                  ),
                  SupervisionExpansionPanel(
                    isExpanded: _expandedSections[job.id]![3],
                    job: job,
                  ),
                  PhotoExpansionPanel(
                    isExpanded: _expandedSections[job.id]![4],
                    job: job,
                    addImage: _addImage,
                    removeImage: _removeImage,
                  ),
                  CommentsExpansionPanel(
                    isExpanded: _expandedSections[job.id]![5],
                    job: job,
                    addComment: _addComment,
                  ),
                ],
              ),
            );
          },
        );
  }
}

class _AvailablePlace extends StatelessWidget {
  const _AvailablePlace({
    required this.positionsOffered,
    required this.positionsOccupied,
    required this.status,
  });

  final int positionsOffered;
  final int positionsOccupied;
  final AvailabilityStatus status;

  @override
  Widget build(BuildContext context) {
    final schoolId = AuthProvider.of(context, listen: true).schoolId;
    if (schoolId == null) {
      return const Center(child: Text('Impossible de charger les stages.'));
    }

    final positionsRemaining = positionsOffered - positionsOccupied;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
      child: Row(
        children: [
          DisponibilityCircle(
            positionsOffered: positionsOffered,
            positionsOccupied: positionsOccupied,
            enabled: status.isEnabled,
          ),
          SizedBox(width: 8.0),
          Flexible(
            child: Text(
              status.message,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          if (status.isEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                '$positionsRemaining / $positionsOffered',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
      ),
    );
  }
}

class _RecrutedBy extends StatelessWidget {
  const _RecrutedBy({required this.enterprise});

  final Enterprise enterprise;

  void _sendEmail(Teacher teacher) {
    final Uri emailLaunchUri = Uri(scheme: 'mailto', path: teacher.email!);
    launchUrl(emailLaunchUri);
  }

  @override
  Widget build(BuildContext context) {
    final teachers = TeachersProvider.of(context);
    final teacher = teachers.fromIdOrNull(enterprise.recruiterId);

    final school = SchoolBoardsProvider.of(context)
        .fromIdOrNull(teacher?.schoolBoardId ?? '')
        ?.schools
        .firstWhereOrNull((school) => school.id == teacher?.schoolId);

    return Padding(
      padding: const EdgeInsets.only(left: 24.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entreprise démarchée pour la 1ère fois pour ce métier par :',
          ),
          teacher == null
              ? Padding(
                padding: const EdgeInsets.only(left: 24.0),
                child: Text(
                  'Enseignant\u00b7e non reconnu\u00b7e.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
              : LayoutBuilder(
                builder: (context, constraints) {
                  return Flex(
                    direction:
                        constraints.maxWidth < 300
                            ? Axis.vertical
                            : Axis.horizontal,
                    children: [
                      GestureDetector(
                        onTap:
                            teacher.email == null
                                ? null
                                : () => _sendEmail(teacher),
                        child: Text(
                          teacher.fullName,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium!.copyWith(
                            decoration:
                                teacher.email == null
                                    ? null
                                    : TextDecoration.underline,
                            color: teacher.email == null ? null : Colors.blue,
                          ),
                        ),
                      ),
                      Text(' - ${school?.name ?? 'École inconnue'}'),
                    ],
                  );
                },
              ),
        ],
      ),
    );
  }
}
