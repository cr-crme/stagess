import 'package:flutter/material.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/providers/internships_provider.dart';

extension StudentsExtension on Student {
  bool hasActiveInternship(BuildContext context) {
    final internships = InternshipsProvider.of(context, listen: false);
    for (final internship in internships) {
      if (internship.isActive && internship.studentId == id) return true;
    }
    return false;
  }

  Widget get avatar {
    final color = int.tryParse(photo);
    if (color == null) {
      throw Exception('Avatar cannot be created from photo: $photo. ');
    }

    return CircleAvatar(
        backgroundColor: Color(int.parse(photo)).withAlpha(255),
        child: Text(initials));
  }
}
