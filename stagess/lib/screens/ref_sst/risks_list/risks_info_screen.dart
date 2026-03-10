import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/misc/risk_data_file_service.dart';
import 'package:stagess/screens/ref_sst/risk_card/risk_card_screen.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';

final _logger = Logger('RisksInfoScreen');

class SstInfoCardsScreen extends StatefulWidget {
  const SstInfoCardsScreen({super.key, required this.initialTabIndex});

  static const route = '/info-cards-sst';
  final int initialTabIndex;

  @override
  State<SstInfoCardsScreen> createState() => _SstInfoCardsScreenState();
}

class _SstInfoCardsScreenState extends State<SstInfoCardsScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(
      vsync: this,
      length: RiskDataFileService.risks.length,
      animationDuration: const Duration(milliseconds: 500));

  @override
  void initState() {
    super.initState();
    _tabController.index = widget.initialTabIndex;
    _tabController.animation!.addListener(() {
      if (_tabController.animation!.value.round() != _tabController.index) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
  }

  void _onTapBack() {
    _logger.finer(
        'Back button tapped, current tab index: ${_tabController.index}');
    Navigator.of(context).pop();
  }

  Widget _appBarBuilder(int index) {
    return AutoSizeText(
      '${index + 1}. ${RiskDataFileService.risks[index].nameHeader}',
      maxLines: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer(
        'Building SstInfoCardsScreen with tab index: ${_tabController.index}');

    return ResponsiveService.scaffoldOf(
      context,
      appBar: ResponsiveService.appBarOf(
        context,
        title: _appBarBuilder(_tabController.animation!.value.round()),
        leading: IconButton(
            onPressed: _onTapBack, icon: const Icon(Icons.arrow_back)),
      ),
      smallDrawer: null,
      mediumDrawer: MainDrawer.medium,
      largeDrawer: MainDrawer.large,
      body: TabBarView(
        controller: _tabController,
        children: [
          ...RiskDataFileService.risks
              .map<Widget>((risk) => RisksCardsScreen(id: risk.id)),
        ],
      ),
    );
  }
}
