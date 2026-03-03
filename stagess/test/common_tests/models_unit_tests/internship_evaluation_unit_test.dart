import 'package:flutter_test/flutter_test.dart';
import 'package:stagess_common/models/internships/internship_evaluation_attitude.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/post_internship_enterprise_evaluation.dart';

import '../utils.dart';

void main() {
  group('InternshipEvaluation', () {
    group('Attitude', () {
      test('"Ponctuality" shows the right things', () {
        expect(Ponctuality.notEvaluated.title, 'Ponctualité');
        expect(Ponctuality.veryHigh.name,
            'Est présent à l\'heure prévue à son poste de travail et prêt à travailler');
        expect(Ponctuality.high.name,
            'Est souvent présent à l\'heure prévue à son poste de travail et prêt à travailler');
        expect(Ponctuality.low.name, 'A quelques retards');
        expect(Ponctuality.insufficient.name, 'A des retards fréquents');
        expect(Ponctuality.values.length, 4);

        expect(Ponctuality.veryHigh.index, 0);
        expect(Ponctuality.high.index, 1);
        expect(Ponctuality.low.index, 2);
        expect(Ponctuality.insufficient.index, 3);
      });

      test('"Inattendance" shows the right things', () {
        expect(Inattendance.notEvaluated.title, 'Assiduité');
        expect(Inattendance.veryHigh.name, 'Est présent');
        expect(Inattendance.high.name, 'A quelques absences');
        expect(Inattendance.low.name, 'S\'absente souvent, même avec rappels');
        expect(Inattendance.insufficient.name,
            'Ne se présente pas ou ne respecte pas son horaire de travail');
        expect(Inattendance.values.length, 4);

        expect(Inattendance.veryHigh.index, 0);
        expect(Inattendance.high.index, 1);
        expect(Inattendance.low.index, 2);
        expect(Inattendance.insufficient.index, 3);
      });

      test('"QualityOfWork" shows the right things', () {
        expect(QualityOfWork.notEvaluated.title, 'Qualité du travail');
        expect(QualityOfWork.veryHigh.name,
            'Respecte les exigences en appliquant les méthodes et techniques requises');
        expect(QualityOfWork.high.name,
            'Persévère malgré quelques erreurs dans l\'application des méthodes et techniques');
        expect(QualityOfWork.low.name,
            'Applique difficilement les méthodes et techniques requises avec le soutien');
        expect(QualityOfWork.insufficient.name,
            'N\'applique pas les méthodes et techniques requises malgré le soutien');
        expect(QualityOfWork.values.length, 4);

        expect(QualityOfWork.veryHigh.index, 0);
        expect(QualityOfWork.high.index, 1);
        expect(QualityOfWork.low.index, 2);
        expect(QualityOfWork.insufficient.index, 3);
      });

      test('"Productivity" shows the right things', () {
        expect(Productivity.notEvaluated.title, 'Productivité');
        expect(Productivity.veryHigh.name,
            'Offre toujours le rendement et le rythme de travail attendus');
        expect(Productivity.high.name,
            'Offre régulièrement le rendement et le rythme de travail attendus');
        expect(Productivity.low.name,
            'Offre avec soutien le rendement et le rythme de travail attendu');
        expect(Productivity.insufficient.name,
            'N\'offre pas le rendement et le rythme de travail attendu malgré le soutien');
        expect(Productivity.values.length, 4);

        expect(Productivity.veryHigh.index, 0);
        expect(Productivity.high.index, 1);
        expect(Productivity.low.index, 2);
        expect(Productivity.insufficient.index, 3);
      });

      test('"TeamCommunication" shows the right things', () {
        expect(TeamCommunication.notEvaluated.title, 'Communication en équipe');
        expect(TeamCommunication.veryHigh.name,
            'Communique de façon claire, précise et adaptée au milieu');
        expect(TeamCommunication.high.name,
            'Communique généralement de façon claire, précise et adaptée au milieu');
        expect(TeamCommunication.low.name,
            'Communique difficilement ou le message est hors contexte');
        expect(TeamCommunication.insufficient.name,
            'Ne communique pas ou communique de façon inadéquate');
        expect(TeamCommunication.values.length, 4);

        expect(TeamCommunication.veryHigh.index, 0);
        expect(TeamCommunication.high.index, 1);
        expect(TeamCommunication.low.index, 2);
        expect(TeamCommunication.insufficient.index, 3);
      });

      test('"RespectOfAuthority" shows the right things', () {
        expect(RespectOfAuthority.notEvaluated.title, 'Respect de l\'autorité');
        expect(RespectOfAuthority.veryHigh.name,
            'Exprime ses besoins et démontre de l\'ouverture à recevoir la rétroaction');
        expect(RespectOfAuthority.high.name,
            'A besoin du support pour exprimer ses besoins tout en démontrant de l\'ouverture à recevoir la rétroaction');
        expect(RespectOfAuthority.low.name,
            'A de la difficulté à exprimer ses besoins et à accepter la rétroaction');
        expect(RespectOfAuthority.insufficient.name,
            'N\'exprime pas ses besoins et n\'est pas à l\'écoute de la rétroaction');
        expect(RespectOfAuthority.values.length, 4);

        expect(RespectOfAuthority.veryHigh.index, 0);
        expect(RespectOfAuthority.high.index, 1);
        expect(RespectOfAuthority.low.index, 2);
        expect(RespectOfAuthority.insufficient.index, 3);
      });

      test('"CommunicationAboutSst" shows the right things', () {
        expect(CommunicationAboutSst.notEvaluated.title,
            'Communication sur la SST');
        expect(CommunicationAboutSst.veryHigh.name,
            'Identifie toujours les risques et agit de manière préventive en adoptant un comportement sécuritaire');
        expect(CommunicationAboutSst.high.name,
            'Identifie certains risques et agit parfois de manière préventive');
        expect(CommunicationAboutSst.low.name,
            'Identifie les risques et agit avec soutien afin d\'adopter le comportement sécuritaire enseigné');
        expect(CommunicationAboutSst.insufficient.name,
            'N\'identifie pas les risques ou n\'adopte pas le comportement sécuritaire enseigné');
        expect(CommunicationAboutSst.values.length, 4);

        expect(CommunicationAboutSst.veryHigh.index, 0);
        expect(CommunicationAboutSst.high.index, 1);
        expect(CommunicationAboutSst.low.index, 2);
        expect(CommunicationAboutSst.insufficient.index, 3);
      });

      test('"SelfControl" shows the right things', () {
        expect(SelfControl.notEvaluated.title, 'Rendement et constance');
        expect(SelfControl.veryHigh.name,
            'Utilise toujours des stratégies efficaces pour gérer ses émotions');
        expect(SelfControl.high.name,
            'Utilise régulièrement des stratégies efficaces pour gérer ses émotions');
        expect(SelfControl.low.name,
            'A besoin de soutien pour gérer ses émotions');
        expect(SelfControl.insufficient.name,
            'N\'utilise pas ses stratégies malgré le soutien offert');
        expect(SelfControl.values.length, 4);

        expect(SelfControl.veryHigh.index, 0);
        expect(SelfControl.high.index, 1);
        expect(SelfControl.low.index, 2);
        expect(SelfControl.insufficient.index, 3);
      });

      test('"TakeInitiative" shows the right things', () {
        expect(TakeInitiative.notEvaluated.title,
            'Autonomie et sens de l\'initiative');
        expect(TakeInitiative.veryHigh.name,
            'Prend très souvent des initiatives pertinentes selon les situations');
        expect(TakeInitiative.high.name,
            'Prend des initiatives dans certaines situations');
        expect(TakeInitiative.low.name,
            'Prend rarement des initiatives et attend souvent les directives');
        expect(TakeInitiative.insufficient.name,
            'Ne prend pas d\'initiative, n\'agit que sur demande');
        expect(TakeInitiative.values.length, 4);

        expect(TakeInitiative.veryHigh.index, 0);
        expect(TakeInitiative.high.index, 1);
        expect(TakeInitiative.low.index, 2);
        expect(TakeInitiative.insufficient.index, 3);
      });

      test('"Adaptability" shows the right things', () {
        expect(Adaptability.notEvaluated.title,
            'Respect des règles de santé et de sécurité du travail (SST)');
        expect(Adaptability.veryHigh.name,
            'S\'ajuste en fonction des changements qui surviennent ou qui lui sont demandés');
        expect(Adaptability.high.name,
            'S\'ajuste souvent en fonction des changements qui surviennent ou qui lui sont demandés');
        expect(Adaptability.low.name, 'S\'ajuste avec un soutien ponctuel');
        expect(Adaptability.insufficient.name, 'N\'arrive pas à s\'ajuster');
        expect(Adaptability.values.length, 4);

        expect(Adaptability.veryHigh.index, 0);
        expect(Adaptability.high.index, 1);
        expect(Adaptability.low.index, 2);
        expect(Adaptability.insufficient.index, 3);
      });

      test('"meetsRequirements" behaves properly', () {
        final attitude = dummyAttitudeEvaluation();

        expect(attitude.meetsRequirements.length, 4);
        expect(attitude.doesNotMeetRequirements.length, 6);
      });

      test('"Attitude" serialization and deserialization works', () {
        final attitude = dummyAttitudeEvaluation();
        final serialized = attitude.serialize();
        final deserialized = AttitudeEvaluation.fromSerialized(serialized);

        expect(serialized, {
          'id': 'attitudeEvaluationId',
          'ponctuality': 1,
          'inattendance': 2,
          'quality_of_work': 3,
          'productivity': 1,
          'team_communication': 2,
          'respect_of_authority': 3,
          'communication_about_sst': 1,
          'self_control': 2,
          'take_initiative': 3,
          'adaptability': 1,
        });

        expect(deserialized.id, 'attitudeEvaluationId');
        expect(deserialized.ponctuality, Ponctuality.values[1]);
        expect(deserialized.inattendance, Inattendance.values[2]);
        expect(deserialized.qualityOfWork, QualityOfWork.values[3]);
        expect(deserialized.productivity, Productivity.values[1]);
        expect(deserialized.teamCommunication, TeamCommunication.values[2]);
        expect(deserialized.respectOfAuthority, RespectOfAuthority.values[3]);
        expect(deserialized.communicationAboutSst,
            CommunicationAboutSst.values[1]);
        expect(deserialized.selfControl, SelfControl.values[2]);
        expect(deserialized.takeInitiative, TakeInitiative.values[3]);
        expect(deserialized.adaptability, Adaptability.values[1]);

        // Test for empty deserialize to make sure it doesn't crash
        final emptyDeserialized =
            AttitudeEvaluation.fromSerialized({'id': 'emptyId'});
        expect(emptyDeserialized.id, 'emptyId');
        expect(emptyDeserialized.ponctuality, Ponctuality.notEvaluated);
        expect(emptyDeserialized.inattendance, Inattendance.notEvaluated);
        expect(emptyDeserialized.qualityOfWork, QualityOfWork.notEvaluated);
        expect(emptyDeserialized.productivity, Productivity.notEvaluated);
        expect(emptyDeserialized.teamCommunication,
            TeamCommunication.notEvaluated);
        expect(emptyDeserialized.respectOfAuthority,
            RespectOfAuthority.notEvaluated);
        expect(emptyDeserialized.communicationAboutSst,
            CommunicationAboutSst.notEvaluated);
        expect(emptyDeserialized.selfControl, SelfControl.notEvaluated);
        expect(emptyDeserialized.takeInitiative, TakeInitiative.notEvaluated);
        expect(emptyDeserialized.adaptability, Adaptability.notEvaluated);
      });

      test(
          '"InternshipEvaluationAttitude" serialization and deserialization works',
          () {
        final attitude = dummyInternshipEvaluationAttitude();
        final serialized = attitude.serialize();
        final deserialized =
            InternshipEvaluationAttitude.fromSerialized(serialized);

        expect(serialized, {
          'id': 'internshipEvaluationAttitudeId',
          'date': attitude.date.millisecondsSinceEpoch,
          'present': attitude.presentAtEvaluation,
          'attitude': attitude.attitude.serialize(),
          'form_version': attitude.formVersion,
        });

        expect(deserialized.id, 'internshipEvaluationAttitudeId');
        expect(deserialized.date.toString(), attitude.date.toString());
        expect(deserialized.presentAtEvaluation, attitude.presentAtEvaluation);
        expect(deserialized.attitude.id, attitude.attitude.id);
        expect(deserialized.formVersion, attitude.formVersion);

        // Test for empty deserialize to make sure it doesn't crash
        final emptyEvaluation =
            InternshipEvaluationAttitude.fromSerialized({'id': 'emptyId'});
        expect(emptyEvaluation.id, 'emptyId');
        expect(emptyEvaluation.date, DateTime(0));
        expect(emptyEvaluation.presentAtEvaluation, []);
        expect(emptyEvaluation.attitude.ponctuality, Ponctuality.notEvaluated);
        expect(
            emptyEvaluation.attitude.inattendance, Inattendance.notEvaluated);
        expect(
            emptyEvaluation.attitude.qualityOfWork, QualityOfWork.notEvaluated);
        expect(
            emptyEvaluation.attitude.productivity, Productivity.notEvaluated);
        expect(emptyEvaluation.attitude.teamCommunication,
            TeamCommunication.notEvaluated);
        expect(emptyEvaluation.attitude.respectOfAuthority,
            RespectOfAuthority.notEvaluated);
        expect(emptyEvaluation.attitude.communicationAboutSst,
            CommunicationAboutSst.notEvaluated);
        expect(emptyEvaluation.attitude.selfControl, SelfControl.notEvaluated);
        expect(emptyEvaluation.attitude.takeInitiative,
            TakeInitiative.notEvaluated);
        expect(
            emptyEvaluation.attitude.adaptability, Adaptability.notEvaluated);

        expect(emptyEvaluation.formVersion, '1.0.0');
      });
    });

    group('Skill', () {
      test('"SkillAppreciation" is shown properly', () {
        expect(SkillAppreciation.acquired.name, 'Réussie');
        expect(SkillAppreciation.toPursuit.name, 'À poursuivre');
        expect(SkillAppreciation.failed.name, 'Non réussie');
        expect(SkillAppreciation.notApplicable.name, 'Non applicable');
        expect(SkillAppreciation.notSelected.name, '');
        expect(SkillAppreciation.values.length, 5);
      });

      test('"skillGranularity" is shown properly', () {
        expect(SkillEvaluationGranularity.global.toString(),
            'Évaluation globale de la compétence');
        expect(SkillEvaluationGranularity.byTask.toString(),
            'Évaluation tâche par tâche');
        expect(SkillEvaluationGranularity.values.length, 2);
      });

      test('"SkillEvaluation" serialization and deserialization works', () {
        final skill = dummySkillEvaluation();
        final serialized = skill.serialize();
        final deserialized = SkillEvaluation.fromSerialized(serialized);

        expect(serialized, {
          'id': 'skillEvaluationId',
          'job_id': 'specializationId',
          'skill': 'skillName',
          'tasks': skill.tasks.map((e) => e.serialize()).toList(),
          'appreciation': skill.appreciation.index,
          'comments': skill.comments,
        });

        expect(deserialized.id, 'skillEvaluationId');
        expect(deserialized.specializationId, 'specializationId');
        expect(deserialized.skillName, 'skillName');
        expect(deserialized.tasks.length, skill.tasks.length);
        expect(deserialized.appreciation, skill.appreciation);
        expect(deserialized.comments, skill.comments);

        // Test for empty deserialize to make sure it doesn't crash
        final emptyDeserialized =
            SkillEvaluation.fromSerialized({'id': 'emptyId'});
        expect(emptyDeserialized.id, 'emptyId');
        expect(emptyDeserialized.specializationId, '');
        expect(emptyDeserialized.skillName, '');
        expect(emptyDeserialized.tasks.length, 0);
        expect(emptyDeserialized.appreciation, SkillAppreciation.notSelected);
        expect(emptyDeserialized.comments, '');
      });

      test(
          '"InternshipEvaluationSkill" serialization and deserialization works',
          () {
        final skill = dummyInternshipEvaluationSkill();
        final serialized = skill.serialize();
        final deserialized =
            InternshipEvaluationSkill.fromSerialized(serialized);

        expect(serialized, {
          'id': 'internshipEvaluationSkillId',
          'date': skill.date.millisecondsSinceEpoch,
          'skill_granularity': skill.skillGranularity.index,
          'present': skill.presentAtEvaluation,
          'skills': skill.skills.map((e) => e.serialize()).toList(),
          'comments': skill.comments,
          'form_version': skill.formVersion,
        });

        expect(deserialized.id, 'internshipEvaluationSkillId');
        expect(deserialized.date.toString(), skill.date.toString());
        expect(deserialized.skillGranularity, skill.skillGranularity);
        expect(deserialized.presentAtEvaluation, skill.presentAtEvaluation);
        expect(deserialized.skills.length, skill.skills.length);
        expect(deserialized.comments, skill.comments);
        expect(deserialized.formVersion, skill.formVersion);

        // Test for empty deserialize to make sure it doesn't crash
        final emptyEvaluation =
            InternshipEvaluationSkill.fromSerialized({'id': 'emptyId'});
        expect(emptyEvaluation.id, 'emptyId');
        expect(emptyEvaluation.date, DateTime(0));
        expect(emptyEvaluation.skillGranularity,
            SkillEvaluationGranularity.global);
        expect(emptyEvaluation.presentAtEvaluation, []);
        expect(emptyEvaluation.skills.length, 0);
        expect(emptyEvaluation.comments, '');
        expect(emptyEvaluation.formVersion, '1.0.0');
      });
    });
  });

  group('PostInternshipEnterpriseEvaluation', () {
    test('serialization and deserialization works', () {
      final evaluation = dummyPostInternshipEnterpriseEvaluation();
      final serialized = evaluation.serialize();
      final deserialized =
          PostInternshipEnterpriseEvaluation.fromSerialized(serialized);

      expect(serialized, {
        'id': evaluation.id,
        'internship_id': evaluation.internshipId,
        'skills_required': evaluation.skillsRequired,
        'task_variety': evaluation.taskVariety,
        'training_plan_respect': evaluation.trainingPlanRespect,
        'autonomy_expected': evaluation.autonomyExpected,
        'efficiency_expected': evaluation.efficiencyExpected,
        'special_needs_accommodation': evaluation.specialNeedsAccommodation,
        'supervision_style': evaluation.supervisionStyle,
        'ease_of_communication': evaluation.easeOfCommunication,
        'absence_acceptance': evaluation.absenceAcceptance,
        'sst_management': evaluation.sstManagement,
      });

      expect(deserialized.id, evaluation.id);
      expect(deserialized.internshipId, evaluation.internshipId);
      expect(deserialized.skillsRequired, evaluation.skillsRequired);
      expect(deserialized.taskVariety, evaluation.taskVariety);
      expect(deserialized.trainingPlanRespect, evaluation.trainingPlanRespect);
      expect(deserialized.autonomyExpected, evaluation.autonomyExpected);
      expect(deserialized.efficiencyExpected, evaluation.efficiencyExpected);
      expect(deserialized.specialNeedsAccommodation,
          evaluation.specialNeedsAccommodation);
      expect(deserialized.supervisionStyle, evaluation.supervisionStyle);
      expect(deserialized.easeOfCommunication, evaluation.easeOfCommunication);
      expect(deserialized.absenceAcceptance, evaluation.absenceAcceptance);
      expect(deserialized.sstManagement, evaluation.sstManagement);

      // Test for empty deserialize to make sure it doesn't crash
      final emptyDeserialized =
          PostInternshipEnterpriseEvaluation.fromSerialized({'id': 'emptyId'});
      expect(emptyDeserialized.id, 'emptyId');
      expect(emptyDeserialized.internshipId, '');
      expect(emptyDeserialized.skillsRequired, []);
      expect(emptyDeserialized.taskVariety, 0);
      expect(emptyDeserialized.trainingPlanRespect, 0);
      expect(emptyDeserialized.autonomyExpected, 0);
      expect(emptyDeserialized.efficiencyExpected, 0);
      expect(emptyDeserialized.specialNeedsAccommodation, 0);
      expect(emptyDeserialized.supervisionStyle, 0);
      expect(emptyDeserialized.easeOfCommunication, 0);
      expect(emptyDeserialized.absenceAcceptance, 0);
      expect(emptyDeserialized.sstManagement, 0);
    });
  });
}
