import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/router.dart';
import 'package:stagess/screens/ref_sst/home_sst/widgets/sst_main_card.dart';
import 'package:stagess/screens/ref_sst/home_sst/widgets/sst_search_bar.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

final _logger = Logger('HomeSstScreen');

class HomeSstScreen extends StatefulWidget {
  const HomeSstScreen({super.key});

  static const route = '/sst';

  @override
  State<HomeSstScreen> createState() => _HomeSstScreenState();
}

class _HomeSstScreenState extends State<HomeSstScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  bool test = true;

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building HomeSstScreen');

    Widget body;
    body = ListView(
      children: [
        SstMainCard(
          title: 'Fiches de risques SST',
          content: const Text(
            'Principaux risques à la santé et à la sécurité en milieu de travail ',
          ),
          onTap: () => GoRouter.of(context).goNamed(Screens.cardsSst),
        ),
        SstMainCard(
          title: 'Historique d\'accidents et d\'incidents',
          content: const Text(
            'Blessures d\'élèves et incidents en stage rapportés par le personnel enseignant',
          ),
          onTap: () => GoRouter.of(context).goNamed(Screens.incidentHistorySst),
        ),
        SstMainCard(
            title: 'Aperçu des risques SST par métier',
            content: _buildRiskCard(),
            onTap: null),
      ],
    );
    // To refresh the scaffold body after the data are fetched
    return ResponsiveService.scaffoldOf(context,
        appBar: ResponsiveService.appBarOf(
          context,
          title: const Text('Santé et sécurité au PFAE'),
        ),
        smallDrawer: MainDrawer.small,
        mediumDrawer: MainDrawer.medium,
        largeDrawer: MainDrawer.large,
        body: body);
  }

  Widget _buildRiskCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
            'Analyse des risques basée sur la description des compétences '
            'de chaque métier figurant dans le répertoire'),
        const SizedBox(height: 24),
        const SstSearchBar(),
        const SizedBox(height: 24),
        Center(
          child: Text(
            '** Attention, l\'analyse indique \nles risques potentiellement '
            'présents \npour un métier donné, \nsans considérer leur dangerosité! ** ',
            style: Theme.of(context)
                .textTheme
                .titleSmall!
                .copyWith(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
