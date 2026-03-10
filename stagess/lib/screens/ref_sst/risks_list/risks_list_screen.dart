import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/misc/risk_data_file_service.dart';
import 'package:stagess/router.dart';
import 'package:stagess/screens/ref_sst/risks_list/widgets/clickable_risk_tile.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

final _logger = Logger('RisksListScreen');

class SstCardsScreen extends StatefulWidget {
  const SstCardsScreen({super.key});

  static const route = '/cards';

  @override
  State<SstCardsScreen> createState() => _SstCardsScreenState();
}

class _SstCardsScreenState extends State<SstCardsScreen> {
  @override
  Widget build(BuildContext context) {
    _logger.finer('Building SstCardsScreen');

    return ResponsiveService.scaffoldOf(
      context,
      appBar: ResponsiveService.appBarOf(
        context,
        title: Text('Fiches de risques SST'),
      ),
      smallDrawer: null,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: _MenuRisksFormScreen(
          navigate: (tabIndex) => GoRouter.of(context).goNamed(
              Screens.infoCardsSst,
              queryParameters: {'tabIndex': tabIndex.toString()})),
    );
  }
}

class _MenuRisksFormScreen extends StatelessWidget {
  const _MenuRisksFormScreen({required this.navigate});

  final Function(int) navigate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: RiskDataFileService.risks
          .map((e) =>
              ClickableRiskTile(e, onTap: (risk) => navigate(risk.number - 1)))
          .toList(),
    );
  }
}
