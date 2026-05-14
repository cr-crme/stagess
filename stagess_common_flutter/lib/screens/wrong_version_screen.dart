import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

final _logger = Logger('WrongVersionScreen');

class WrongVersionScreen extends StatelessWidget {
  const WrongVersionScreen({super.key});

  static const route = '/wrong_version';

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building WrongVersionScreen');

    return ResponsiveService.scaffoldOf(
      context,
      appBar: AppBar(title: const Text('Version incorrecte de Stagess')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Center(
          child: Text(
            'La version de Stagess que vous utilisez est incompatible avec le serveur. '
            'Veuillez rafraichir la page pour mettre à jour votre application.\n\n'
            'Si le problème persiste, il est possible qu\'il faille vider le cache de '
            'votre navigateur ou attendre quelques minutes pour que les mises à jour soient propagées.\n\n',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
