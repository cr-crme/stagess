import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:stagess/common/widgets/main_drawer.dart';
import 'package:stagess/screens/ref_sst/specialization_list_risks_and_skills/widgets/tile_job_risk.dart';
import 'package:stagess_common/models/ref_sst/risk.dart';
import 'package:stagess_common/services/job_data_file_service.dart';
import 'package:stagess_common_flutter/helpers/responsive_service.dart';
import 'package:stagess_common_flutter/services/risk_data_file_service.dart';
import 'package:stagess_common_flutter/widgets/dialogs/help_dialog.dart';

final _logger = Logger('SpecializationListScreen');

class SpecializationListScreen extends StatelessWidget {
  static const route = '/job-risks';

  final String id;
  const SpecializationListScreen({super.key, required this.id});

  List<Specialization> filledList(BuildContext context) {
    List<Specialization> out = [];
    for (final sector in ActivitySectorsService.activitySectors) {
      for (final specialization in sector.specializations) {
        // If there is no risk, it does not mean this specialization
        // is risk-free, it means it was not evaluated
        var hasRisks = false;
        for (final skill in specialization.skills) {
          if (hasRisks) break;
          hasRisks = skill.risks.isNotEmpty;
        }
        if (hasRisks) out.add(specialization);
      }
    }
    return out;
  }

  List<Risk> _extractAllRisks(Specialization specialization) {
    _logger.finer(
        'Extracting all risks for specialization: ${specialization.name}');

    final out = <String>[];
    for (final skill in specialization.skills) {
      for (final risk in skill.risks) {
        if (!out.contains(risk)) out.add(risk);
      }
    }
    return out.map<Risk>((e) => RiskDataFileService.fromAbbrv(e)!).toList();
  }

  List<Risk> _risksSkillHas(Skill skill, List<Risk> allRisks) {
    final out = <Risk>[];
    for (final risk in skill.risks) {
      final skillRisk = RiskDataFileService.fromAbbrv(risk);
      if (out.contains(skillRisk) || skillRisk == null) continue;
      out.add(skillRisk);
    }
    return out;
  }

  List<Skill> _skillsThatHasThisRisk(Risk risk, List<Skill> skills) {
    final out = <Skill>[];
    for (final skill in skills) {
      if (skill.risks.toList().indexWhere((e) => e == risk.abbrv) < 0) {
        continue;
      }
      out.add(skill);
    }
    return out;
  }

  void _showHelp(BuildContext context) async {
    if (!context.mounted) return;
    _logger.info('Showing help dialog');
    showHelpDialog(
      context,
      title: 'Analyse des risques par compétence',
      content: const Text(
          'L\'analyse indique le nombre de risques potentiellement présents '
          'pour chaque compétence d\'un métier et inversement.\n'
          '\n'
          'Elle a été faite pour les 45 métiers les plus populaires du '
          'répertoire du Ministère de l\'éducation.\n'
          '\n'
          'Elle ne tient pas compte du contexte de chaque milieu de stage.'),
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.finer('Building SpecializationListScreen for ID: $id');

    final specialization = ActivitySectorsService.specialization(id);

    final risks = _extractAllRisks(specialization);
    final skillsAssociatedToRisks = <Risk, List<Skill>>{};
    for (final risk in risks) {
      skillsAssociatedToRisks[risk] =
          _skillsThatHasThisRisk(risk, specialization.skills.toList());
    }
    risks.sort((a, b) =>
        skillsAssociatedToRisks[b]!.length -
        skillsAssociatedToRisks[a]!.length);

    final skills = [...specialization.skills];
    final risksAssociatedToSkill = <Skill, List<Risk>>{};
    for (final skill in skills) {
      risksAssociatedToSkill[skill] = _risksSkillHas(skill, risks).toList();
    }
    skills.sort((a, b) =>
        risksAssociatedToSkill[b]!.length - risksAssociatedToSkill[a]!.length);

    return DefaultTabController(
      length: 2,
      child: ResponsiveService.scaffoldOf(context,
          appBar: ResponsiveService.appBarOf(
            context,
            title: Padding(
              padding: const EdgeInsets.only(top: 5.0, bottom: 5),
              child: AutoSizeText(specialization.name, maxLines: 2),
            ),
            actions: [
              IconButton(
                onPressed: () => _showHelp(context),
                icon: const Icon(Icons.info),
              ),
            ],
            bottom: const TabBar(tabs: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.build_circle_sharp),
                    SizedBox(width: 10),
                    Text(
                      'Affichage par\ncompétence',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning),
                    SizedBox(width: 10),
                    Text(
                      'Affichage par\nrisque',
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ]),
          ),
          smallDrawer: null,
          mediumDrawer: MainDrawer.medium,
          largeDrawer: MainDrawer.large,
          body: TabBarView(children: [
            ListView.separated(
              physics: const ScrollPhysics(),
              shrinkWrap: true,
              itemCount: specialization.skills.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) => Padding(
                padding: i == specialization.skills.length - 1
                    ? EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * 0.5)
                    : const EdgeInsets.only(),
                child: TileJobRisk(
                  title: skills[i].name,
                  elements: risksAssociatedToSkill[skills[i]]!,
                  nbMaximumElements: 1000, // Show all in orange
                  tooltipMessage:
                      'Nombre de compétences possiblement concernées par ce risque',
                ),
              ),
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  color: Colors.grey,
                  height: 16,
                );
              },
            ),
            ListView.separated(
              physics: const ScrollPhysics(),
              shrinkWrap: true,
              itemCount: risks.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) => Padding(
                padding: i == risks.length - 1
                    ? EdgeInsets.only(
                        bottom: MediaQuery.of(context).size.height * 0.5)
                    : const EdgeInsets.only(),
                child: TileJobRisk(
                  title: risks[i].name,
                  elements: skillsAssociatedToRisks[risks[i]]!,
                  nbMaximumElements: 1000, // Show all in orange
                  tooltipMessage:
                      'Nombre de risques potentiellement présents pour cette compétence',
                ),
              ),
              separatorBuilder: (BuildContext context, int index) {
                return const Divider(
                  color: Colors.grey,
                  height: 16,
                );
              },
            )
          ])),
    );
  }
}
