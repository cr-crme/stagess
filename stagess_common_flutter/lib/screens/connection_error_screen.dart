import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

final _logger = Logger('ConnectionErrorScreen');

class ConnectionErrorScreen extends StatelessWidget {
  const ConnectionErrorScreen({super.key});

  static const route = '/connection_error';

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building ConnectionErrorScreen');

    return ResponsiveService.scaffoldOf(
      context,
      appBar:
          AppBar(title: const Text('Impossible de se connecter au serveur')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Text(
            'Impossible de se connecter au serveur. '
            'Veuillez vérifier votre connexion Internet et réessayer.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
