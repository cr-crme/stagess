import 'package:flutter/material.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

Future<void> showHelpDialog(BuildContext context,
    {required String title, required Widget content}) async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: AlertDialog(
        title: Text(title),
        content: ConstrainedBox(
          constraints:
              BoxConstraints(maxWidth: ResponsiveService.maxBodyWidth - 100),
          child: SingleChildScrollView(
            child: content,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      ),
    ),
  );
}
