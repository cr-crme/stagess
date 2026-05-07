import 'package:flutter/material.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/enterprise_status.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common_flutter/helpers/job_extension.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';

enum AvailabilityStatus {
  isClosed,
  isBanned,
  isNewForThatSchool,
  isReserved,
  isFull,
  isAvailable;

  static AvailabilityStatus fromJob(BuildContext context,
      {required Enterprise enterprise,
      required Job job,
      required List<Job> availableJobs}) {
    if (enterprise.status == EnterpriseStatus.noLongerAcceptingInternships) {
      return AvailabilityStatus.isClosed;
    } else if (enterprise.status ==
        EnterpriseStatus.bannedFromAcceptingInternships) {
      return AvailabilityStatus.isBanned;
    }

    final isUnavailable =
        availableJobs.every((availableJob) => availableJob.id != job.id);
    if (isUnavailable) return AvailabilityStatus.isReserved;

    final schoolId = AuthProvider.of(context, listen: false).schoolId ?? '';
    final offered = job.positionsOffered[schoolId] ?? 0;

    if (offered == 0) return AvailabilityStatus.isNewForThatSchool;

    final occupied = job.positionsOccupied(context, listen: true);
    final remaining = offered - occupied;
    if (remaining <= 0) return AvailabilityStatus.isFull;

    return AvailabilityStatus.isAvailable;
  }

  bool get isEnabled {
    switch (this) {
      case AvailabilityStatus.isClosed:
      case AvailabilityStatus.isBanned:
      case AvailabilityStatus.isReserved:
      case AvailabilityStatus.isNewForThatSchool:
        return false;
      case AvailabilityStatus.isFull:
      case AvailabilityStatus.isAvailable:
        return true;
    }
  }

  String get message {
    switch (this) {
      case AvailabilityStatus.isClosed:
        return 'Cette entreprise n\'accepte plus d\'élèves en stage.';
      case AvailabilityStatus.isBanned:
        return 'Cette entreprise n\'est plus autorisée à accueillir de stagiaires.';
      case AvailabilityStatus.isReserved:
        return 'Stage réservé à un\u00b7e enseignant\u00b7e\n'
            'Aucun autre stagiaire ne sera accepté';
      case AvailabilityStatus.isNewForThatSchool:
        return 'Cette entreprise n\'accueille pas de stagiaires de votre école pour ce métier.\n'
            'Contacter l\'enseignant qui a fait le démarchage et votre administrateur au '
            'CSS pour ouvrir la possibilité d\'y inscrire des élèves.';
      case AvailabilityStatus.isFull:
        return 'Aucune place de stage disponible';
      case AvailabilityStatus.isAvailable:
        return 'Nombre de places de stages disponibles';
    }
  }

  String get shortMessage {
    switch (this) {
      case AvailabilityStatus.isClosed:
        return 'Entreprise fermée';
      case AvailabilityStatus.isBanned:
        return 'Entreprise bannie';
      case AvailabilityStatus.isReserved:
        return 'Stage réservé';
      case AvailabilityStatus.isNewForThatSchool:
        return 'Nouveau pour cette école';
      case AvailabilityStatus.isFull:
        return 'Stage complet';
      case AvailabilityStatus.isAvailable:
        return 'Stage disponible';
    }
  }
}
