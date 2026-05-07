import 'package:flutter/material.dart';
import 'package:stagess_common/models/persons/student.dart';
import 'package:stagess_common_flutter/helpers/students_extension.dart';

class StudentCard extends StatelessWidget {
  const StudentCard({
    super.key,
    required this.student,
    required this.onTap,
  });

  final Student student;
  final void Function(Student student) onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 10,
      child: ListTile(
        onTap: () => onTap(student),
        leading: SizedBox(
          height: double.infinity, // This centers the avatar
          child: student.avatar,
        ),
        title: Text(student.fullName),
        subtitle: Text(
          'Groupe ${student.group}',
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}
