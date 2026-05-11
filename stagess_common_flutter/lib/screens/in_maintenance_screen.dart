import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

final _logger = Logger('InMaintenanceScreen');

class InMaintenanceScreen extends StatelessWidget {
  const InMaintenanceScreen({super.key});

  static const route = '/in_maintenance';

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building InMaintenanceScreen');

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(title: const Text('Maintenance de Stagess')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Text(
            'Stagess est actuellement en maintenance. Nous nous excusons pour le '
            'désagrément et travaillons à rétablir le service le plus rapidement possible.\n\n'
            'Merci de votre patience et de votre compréhension.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
