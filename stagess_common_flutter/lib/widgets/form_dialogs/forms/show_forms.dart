import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common/models/internships/internship.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common/utils.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';
import 'package:stagess_common_flutter/providers/students_provider.dart';
import 'package:stagess_common_flutter/widgets/show_snackbar.dart';

final _logger = Logger('InternshipEvaluationCard');

Future<void> showInternshipEvaluationFormDialog(
  BuildContext context, {
  required String internshipId,
  String? evaluationId,
  required Future<Internship?> Function(BuildContext,
          {required String internshipId, String? evaluationId})
      showEvaluationDialog,
}) async {
  final editMode = evaluationId == null;
  _logger.info(
      'Showing InternshipEvaluationFormDialog for internship: $internshipId, editMode: $editMode');
  final internships = InternshipsProvider.of(context, listen: false);
  final internship = internships.fromId(internshipId);

  if (editMode) {
    final hasLock = await internships.getLockForItem(internship);
    if (!hasLock || !context.mounted) {
      if (context.mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de modifier ce stage, car il est en cours de modification par un autre utilisateur.',
        );
      }
      return;
    }
  }

  final newInternship = await showEvaluationDialog(context,
      internshipId: internshipId, evaluationId: evaluationId);
  if (!editMode) return;

  if (newInternship == null) {
    await internships.releaseLockForItem(internship);
    return;
  }

  await internships.replaceWithConfirmation(newInternship);
  if (context.mounted) {
    showSnackBar(context, message: 'Le stage a été mis à jour');
  }
  await internships.releaseLockForItem(internship);
}

Future<void> showStudentEvaluationFormDialog(
  BuildContext context, {
  required String studentId,
  String? evaluationId,
  required bool canModify,
  required Future<Student?> Function(BuildContext,
          {required String studentId,
          String? evaluationId,
          required bool canModify})
      showEvaluationDialog,
}) async {
  _logger.info(
      'Showing StudentEvaluationFormDialog for student: $studentId, canModify: $canModify');
  final students = StudentsProvider.of(context, listen: false);
  final student = students.fromId(studentId);

  if (canModify) {
    final hasLock = await students.getLockForItem(student);
    if (!hasLock || !context.mounted) {
      if (context.mounted) {
        showSnackBar(
          context,
          message:
              'Impossible de modifier cet étudiant, car il est en cours de modification par un autre utilisateur.',
        );
      }
      return;
    }
  }

  final lastEvaluation =
      !canModify || student.allVisa.isEmpty ? null : student.allVisa.last;
  final newStudent = await showEvaluationDialog(context,
      studentId: studentId, evaluationId: evaluationId, canModify: canModify);
  if (!canModify) return;
  final newEvaluation =
      (newStudent?.allVisa.isEmpty ?? true) ? null : newStudent!.allVisa.last;

  final isDifferent = newStudent != null &&
      (newEvaluation
                  ?.getDifference(lastEvaluation, ignoreKeys: ['id', 'date']) ??
              [])
          .isNotEmpty;
  if (!isDifferent) {
    await students.releaseLockForItem(student);
    return;
  }

  await students.replaceWithConfirmation(newStudent);
  if (context.mounted) {
    showSnackBar(context, message: 'L\'étudiant a été mis à jour');
  }
  await students.releaseLockForItem(student);
}
