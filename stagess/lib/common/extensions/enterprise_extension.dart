import 'package:flutter/widgets.dart';
import 'package:stagess/common/extensions/job_extension.dart';
import 'package:stagess_common/models/enterprises/enterprise.dart';
import 'package:stagess_common/models/enterprises/job.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common_flutter/providers/auth_provider.dart';
import 'package:stagess_common_flutter/providers/enterprises_provider.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

extension EnterprisesProviderExtension on EnterprisesProvider {
  static List<Enterprise> availableEnterprisesOf(
    BuildContext context, {
    bool listen = true,
  }) {
    final authProvider = AuthProvider.of(context, listen: false);
    final currentSchoolId = authProvider.schoolId;
    final currentTeacherId = authProvider.teacherId;
    if (currentSchoolId == null || currentTeacherId == null) {
      return [];
    }

    return [...EnterprisesProvider.of(context, listen: listen)];
  }
}

extension EnterpriseExtension on Enterprise {
  List<Internship> internships(BuildContext context, {listen = true}) =>
      InternshipsProvider.of(context, listen: listen)
          .mapRemoveNull<Internship>(
            (Internship e) => e.enterpriseId == id ? e : null,
          )
          .toList();

  Iterable<Job> availablejobs(BuildContext context) {
    // Remove the jobs which are visible to certain users only
    final authProvider = AuthProvider.of(context, listen: false);
    final currentSchoolId = authProvider.schoolId!;
    final currentTeacherId = authProvider.teacherId!;
    return [...jobs]..removeWhere(
      (job) =>
          job.reservedForId.isNotEmpty &&
          job.reservedForId != currentSchoolId &&
          job.reservedForId != currentTeacherId,
    );
  }

  Iterable<Job> withRemainingPositions(
    context, {
    required String schoolId,
    bool listen = false,
  }) {
    return jobs.where(
      (job) =>
          (job.positionsOffered[schoolId] ?? 0) -
              job.positionsOccupied(context, listen: listen) >
          0,
    );
  }
}
