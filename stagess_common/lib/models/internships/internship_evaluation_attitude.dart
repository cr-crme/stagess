import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/models/generic/fetchable_fields.dart';
import 'package:stagess_common/models/generic/serializable_elements.dart';
import 'package:stagess_common/models/internships/internship_evaluation.dart';

class AttitudeEvaluation extends ItemSerializable {
  Ponctuality ponctuality;
  Inattendance inattendance;
  QualityOfWork qualityOfWork;
  Productivity productivity;
  TeamCommunication teamCommunication;
  RespectOfAuthority respectOfAuthority;
  CommunicationAboutSst communicationAboutSst;
  SelfControl selfControl;
  TakeInitiative takeInitiative;
  Adaptability adaptability;

  List<String> _fromRequirements(int min, int max) {
    List<String> out = [];
    if (isBetween(ponctuality, min, max)) out.add(Ponctuality._(-1).title);
    if (isBetween(inattendance, min, max)) out.add(Inattendance._(-1).title);
    if (isBetween(qualityOfWork, min, max)) out.add(QualityOfWork._(-1).title);
    if (isBetween(productivity, min, max)) out.add(Productivity._(-1).title);
    return out;
  }

  List<String> get meetsRequirements => _fromRequirements(0, 1);
  List<String> get doesNotMeetRequirements => _fromRequirements(2, 3);

  AttitudeEvaluation({
    super.id,
    required this.ponctuality,
    required this.inattendance,
    required this.qualityOfWork,
    required this.productivity,
    required this.teamCommunication,
    required this.respectOfAuthority,
    required this.communicationAboutSst,
    required this.selfControl,
    required this.takeInitiative,
    required this.adaptability,
  });
  AttitudeEvaluation.fromSerialized(super.map)
      : ponctuality = Ponctuality.fromIndex(map?['ponctuality'] ?? -1),
        inattendance = Inattendance.fromIndex(map?['inattendance'] ?? -1),
        qualityOfWork = QualityOfWork.fromIndex(map?['quality_of_work'] ?? -1),
        productivity = Productivity.fromIndex(map?['productivity'] ?? -1),
        teamCommunication =
            TeamCommunication.fromIndex(map?['team_communication'] ?? -1),
        respectOfAuthority =
            RespectOfAuthority.fromIndex(map?['respect_of_authority'] ?? -1),
        communicationAboutSst = CommunicationAboutSst.fromIndex(
            map?['communication_about_sst'] ?? -1),
        selfControl = SelfControl.fromIndex(map?['self_control'] ?? -1),
        takeInitiative =
            TakeInitiative.fromIndex(map?['take_initiative'] ?? -1),
        adaptability = Adaptability.fromIndex(map?['adaptability'] ?? -1),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'ponctuality': ponctuality.index,
      'inattendance': inattendance.index,
      'quality_of_work': qualityOfWork.index,
      'productivity': productivity.index,
      'team_communication': teamCommunication.index,
      'respect_of_authority': respectOfAuthority.index,
      'communication_about_sst': communicationAboutSst.index,
      'self_control': selfControl.index,
      'take_initiative': takeInitiative.index,
      'adaptability': adaptability.index,
    };
  }

  @override
  String toString() {
    return 'ponctuality: ${ponctuality.name}, '
        'AttitudeEvaluation{inattendance: ${inattendance.name}, '
        'qualityOfWork: ${qualityOfWork.name}, '
        'productivity: ${productivity.name}, '
        'teamCommunication: ${teamCommunication.name}, '
        'respectOfAuthority: ${respectOfAuthority.name}, '
        'communicationAboutSst: ${communicationAboutSst.name}, '
        'selfControl: ${selfControl.name}, '
        'takeInitiative: ${takeInitiative.name}, '
        'adaptability: ${adaptability.name}';
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'ponctuality': FetchableFields.mandatory,
        'inattendance': FetchableFields.mandatory,
        'quality_of_work': FetchableFields.mandatory,
        'productivity': FetchableFields.mandatory,
        'team_communication': FetchableFields.mandatory,
        'respect_of_authority': FetchableFields.mandatory,
        'communication_about_sst': FetchableFields.mandatory,
        'self_control': FetchableFields.mandatory,
        'take_initiative': FetchableFields.mandatory,
        'adaptability': FetchableFields.mandatory,
      });
}

class InternshipEvaluationAttitude extends InternshipEvaluation {
  static const String currentVersion = '1.0.0';

  @override
  DateTime date;

  List<String> presentAtEvaluation;
  AttitudeEvaluation attitude;
  String
      formVersion; // The version of the evaluation form (so data can be parsed properly)

  InternshipEvaluationAttitude({
    super.id,
    required this.date,
    required this.presentAtEvaluation,
    required this.attitude,
    required this.formVersion,
  });
  InternshipEvaluationAttitude.fromSerialized(super.map)
      : date = DateTimeExt.from(map?['date']) ?? DateTime(0),
        presentAtEvaluation =
            (map?['present'] as List?)?.map((e) => e as String).toList() ?? [],
        attitude = AttitudeEvaluation.fromSerialized(map?['attitude'] ?? {}),
        formVersion = map?['form_version'] ?? currentVersion,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'date': date.serialize(),
      'present': presentAtEvaluation,
      'attitude': attitude.serialize(),
      'form_version': formVersion,
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'date': FetchableFields.optional,
        'present': FetchableFields.optional,
        'attitude': FetchableFields.mandatory
          ..addAll(FetchableFields.reference(
              {'*': AttitudeEvaluation.fetchableFields})),
        'form_version': FetchableFields.mandatory,
      });

  @override
  String toString() {
    return 'InternshipEvaluationAttitude(date: $date, '
        'presentAtEvaluation: $presentAtEvaluation, '
        'attitude: $attitude, ';
  }
}

abstract class AttitudeCategoryEnum {
  String get name;
  String get title;
  String get definition;
  int get index;
  String? get extraInformation;
  List<AttitudeCategoryEnum> get validElements;
}

bool isBetween(AttitudeCategoryEnum category, int min, int max) {
  return category.index >= min && category.index <= max;
}

class Ponctuality implements AttitudeCategoryEnum {
  @override
  String get title => 'Ponctualité';

  @override
  String get definition =>
      'Capacité à respecter les horaires de travail et à être prêt à commencer ses tâches';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Est présent à l\'heure prévue à son poste de travail et prêt à travailler';
      case 1:
        return 'Est souvent présent à l\'heure prévue à son poste de travail et prêt à travailler';
      case 2:
        return 'A quelques retards';
      case 3:
        return 'A des retards fréquents';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation =>
      'Moments observables : Heure de début, retour de pauses, \n'
      'Retards justifiés : transport adapté, transport en commun, rendez-vous médical, ...';

  const Ponctuality._(this.index);
  static Ponctuality get notEvaluated => const Ponctuality._(-1);
  static Ponctuality get veryHigh => const Ponctuality._(0);
  static Ponctuality get high => const Ponctuality._(1);
  static Ponctuality get low => const Ponctuality._(2);
  static Ponctuality get insufficient => const Ponctuality._(3);

  static Ponctuality fromIndex(int index) =>
      index < 0 ? Ponctuality.notEvaluated : Ponctuality.values[index];

  static List<Ponctuality> get values => [
        Ponctuality.veryHigh,
        Ponctuality.high,
        Ponctuality.low,
        Ponctuality.insufficient,
      ];

  @override
  List<Ponctuality> get validElements => Ponctuality.values;
}

class Inattendance implements AttitudeCategoryEnum {
  @override
  String get title => 'Assiduité';

  @override
  String get definition =>
      'Être présent de façon régulière à son lieu de travail';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Est présent';
      case 1:
        return 'A quelques absences';
      case 2:
        return 'S\'absente souvent, même avec rappels';
      case 3:
        return 'Ne se présente pas ou ne respecte pas son horaire de travail';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation => null;

  const Inattendance._(this.index);
  static Inattendance get notEvaluated => const Inattendance._(-1);
  static Inattendance get veryHigh => const Inattendance._(0);
  static Inattendance get high => const Inattendance._(1);
  static Inattendance get low => const Inattendance._(2);
  static Inattendance get insufficient => const Inattendance._(3);

  static Inattendance fromIndex(int index) =>
      index < 0 ? Inattendance.notEvaluated : Inattendance.values[index];

  static List<Inattendance> get values => [
        Inattendance.veryHigh,
        Inattendance.high,
        Inattendance.low,
        Inattendance.insufficient,
      ];

  @override
  List<Inattendance> get validElements => Inattendance.values;
}

class QualityOfWork implements AttitudeCategoryEnum {
  @override
  String get title => 'Qualité du travail';

  @override
  String get definition =>
      'L\'accomplissement des tâches requises en tenant compte des exigences associées '
      'à la compétence spécifique, en utilisant les méthodes et les techniques '
      'appropriées et en respectant les dispositions légales et réglementaires';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Respecte les exigences en appliquant les méthodes et techniques requises';
      case 1:
        return 'Persévère malgré quelques erreurs dans l\'application des méthodes et techniques';
      case 2:
        return 'Applique difficilement les méthodes et techniques requises avec le soutien';
      case 3:
        return 'N\'applique pas les méthodes et techniques requises malgré le soutien';

      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation => null;

  const QualityOfWork._(this.index);
  static QualityOfWork get notEvaluated => const QualityOfWork._(-1);
  static QualityOfWork get veryHigh => const QualityOfWork._(0);
  static QualityOfWork get high => const QualityOfWork._(1);
  static QualityOfWork get low => const QualityOfWork._(2);
  static QualityOfWork get insufficient => const QualityOfWork._(3);

  static QualityOfWork fromIndex(int index) =>
      index < 0 ? QualityOfWork.notEvaluated : QualityOfWork.values[index];

  static List<QualityOfWork> get values => [
        QualityOfWork.veryHigh,
        QualityOfWork.high,
        QualityOfWork.low,
        QualityOfWork.insufficient,
      ];

  @override
  List<QualityOfWork> get validElements => QualityOfWork.values;
}

class Productivity implements AttitudeCategoryEnum {
  @override
  String get title => 'Rendement et constance';

  @override
  String get definition =>
      'Capacité de l\'élève à fournir la production attendue tout en adoptant des '
      'comportements sains et sécuritaires (ex. : organisation, sens de la priorisation, '
      'gestion de la pression temporelle...)';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Offre toujours le rendement et le rythme de travail attendus';
      case 1:
        return 'Offre régulièrement le rendement et le rythme de travail attendus';
      case 2:
        return 'Offre avec soutien le rendement et le rythme de travail attendu';
      case 3:
        return 'N\'offre pas le rendement et le rythme de travail attendu malgré le soutien';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation => null;

  const Productivity._(this.index);
  static Productivity get notEvaluated => const Productivity._(-1);
  static Productivity get veryHigh => const Productivity._(0);
  static Productivity get high => const Productivity._(1);
  static Productivity get low => const Productivity._(2);
  static Productivity get insufficient => const Productivity._(3);

  static Productivity fromIndex(int index) =>
      index < 0 ? Productivity.notEvaluated : Productivity.values[index];

  static List<Productivity> get values => [
        Productivity.veryHigh,
        Productivity.high,
        Productivity.low,
        Productivity.insufficient,
      ];

  @override
  List<Productivity> get validElements => Productivity.values;
}

class TeamCommunication implements AttitudeCategoryEnum {
  @override
  String get title => 'Communication avec l\'équipe';

  @override
  String get definition =>
      'Capacité de l\'élève à interagir avec son entourage pour échanger des informations, '
      'pour organiser et coordonner le travail, recevoir des instructions ou prendre '
      'part à d\'autres activités nécessitant des échanges';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Communique de façon claire, précise et adaptée au milieu';
      case 1:
        return 'Communique généralement de façon claire, précise et adaptée au milieu';
      case 2:
        return 'Communique difficilement ou le message est hors contexte';
      case 3:
        return 'Ne communique pas ou communique de façon inadéquate';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation => null;

  const TeamCommunication._(this.index);
  static TeamCommunication get notEvaluated => const TeamCommunication._(-1);
  static TeamCommunication get veryHigh => const TeamCommunication._(0);
  static TeamCommunication get high => const TeamCommunication._(1);
  static TeamCommunication get low => const TeamCommunication._(2);
  static TeamCommunication get insufficient => const TeamCommunication._(3);

  static TeamCommunication fromIndex(int index) => index < 0
      ? TeamCommunication.notEvaluated
      : TeamCommunication.values[index];

  static List<TeamCommunication> get values => [
        TeamCommunication.veryHigh,
        TeamCommunication.high,
        TeamCommunication.low,
        TeamCommunication.insufficient,
      ];

  @override
  List<TeamCommunication> get validElements => TeamCommunication.values;
}

class RespectOfAuthority implements AttitudeCategoryEnum {
  @override
  String get title => 'Respect des personnes en autorité';

  @override
  String get definition =>
      'Adoption d\'une attitude d\'écoute et d\'ouverture à l\'égard des directives '
      'et des explications dans ses échanges avec une personne en autorité';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Exprime ses besoins et démontre de l\'ouverture à recevoir la rétroaction';
      case 1:
        return 'A besoin du support pour exprimer ses besoins tout en démontrant de l\'ouverture à recevoir la rétroaction';
      case 2:
        return 'A de la difficulté à exprimer ses besoins et à accepter la rétroaction';
      case 3:
        return 'N\'exprime pas ses besoins et n\'est pas à l\'écoute de la rétroaction';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation =>
      'S\'il s\'absente ou est en retard, il informe l\'employeur et son superviseur de stage';

  const RespectOfAuthority._(this.index);
  static RespectOfAuthority get notEvaluated => const RespectOfAuthority._(-1);
  static RespectOfAuthority get veryHigh => const RespectOfAuthority._(0);
  static RespectOfAuthority get high => const RespectOfAuthority._(1);
  static RespectOfAuthority get low => const RespectOfAuthority._(2);
  static RespectOfAuthority get insufficient => const RespectOfAuthority._(3);

  static RespectOfAuthority fromIndex(int index) => index < 0
      ? RespectOfAuthority.notEvaluated
      : RespectOfAuthority.values[index];

  static List<RespectOfAuthority> get values => [
        RespectOfAuthority.veryHigh,
        RespectOfAuthority.high,
        RespectOfAuthority.low,
        RespectOfAuthority.insufficient,
      ];

  @override
  List<RespectOfAuthority> get validElements => RespectOfAuthority.values;
}

class CommunicationAboutSst implements AttitudeCategoryEnum {
  @override
  String get title =>
      'Communication au sujet de la santé et sécurité au travail';

  @override
  String get definition =>
      'Capacité de l\'élève à reconnaître les risques et à adopter un comportement sécuritaire';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Identifie toujours les risques et agit de manière préventive en adoptant un comportement sécuritaire';
      case 1:
        return 'Identifie certains risques et agit parfois de manière préventive';
      case 2:
        return 'Identifie les risques et agit avec soutien afin d\'adopter le comportement sécuritaire enseigné';
      case 3:
        return 'N\'identifie pas les risques ou n\'adopte pas le comportement sécuritaire enseigné';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation => null;

  const CommunicationAboutSst._(this.index);
  static CommunicationAboutSst get notEvaluated =>
      const CommunicationAboutSst._(-1);
  static CommunicationAboutSst get veryHigh => const CommunicationAboutSst._(0);
  static CommunicationAboutSst get high => const CommunicationAboutSst._(1);
  static CommunicationAboutSst get low => const CommunicationAboutSst._(2);
  static CommunicationAboutSst get insufficient =>
      const CommunicationAboutSst._(3);

  static CommunicationAboutSst fromIndex(int index) => index < 0
      ? CommunicationAboutSst.notEvaluated
      : CommunicationAboutSst.values[index];

  static List<CommunicationAboutSst> get values => [
        CommunicationAboutSst.veryHigh,
        CommunicationAboutSst.high,
        CommunicationAboutSst.low,
        CommunicationAboutSst.insufficient,
      ];

  @override
  List<CommunicationAboutSst> get validElements => CommunicationAboutSst.values;
}

class SelfControl implements AttitudeCategoryEnum {
  @override
  String get title => 'Maîtrise de soi';

  @override
  String get definition =>
      'L\'action de se contrôler dans un contexte de travail. L\'élève utilise des '
      'stratégies efficaces pour gérer ses émotions dans des situations délicates';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Utilise toujours des stratégies efficaces pour gérer ses émotions';
      case 1:
        return 'Utilise régulièrement des stratégies efficaces pour gérer ses émotions';
      case 2:
        return 'A besoin de soutien pour gérer ses émotions';
      case 3:
        return 'N\'utilise pas ses stratégies malgré le soutien offert';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation => null;

  const SelfControl._(this.index);
  static SelfControl get notEvaluated => const SelfControl._(-1);
  static SelfControl get veryHigh => const SelfControl._(0);
  static SelfControl get high => const SelfControl._(1);
  static SelfControl get low => const SelfControl._(2);
  static SelfControl get insufficient => const SelfControl._(3);

  static SelfControl fromIndex(int index) =>
      index < 0 ? SelfControl.notEvaluated : SelfControl.values[index];

  static List<SelfControl> get values => [
        SelfControl.veryHigh,
        SelfControl.high,
        SelfControl.low,
        SelfControl.insufficient,
      ];

  @override
  List<SelfControl> get validElements => SelfControl.values;
}

class TakeInitiative implements AttitudeCategoryEnum {
  @override
  String get title => 'Prise d\'initiative';

  @override
  String get definition =>
      'Capacité de l\'élève à agir de façon autonome et proactive dans les tâches';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Prend très souvent des initiatives pertinentes selon les situations';
      case 1:
        return 'Prend des initiatives dans certaines situations';
      case 2:
        return 'Prend rarement des initiatives et attend souvent les directives';
      case 3:
        return 'Ne prend pas d\'initiative, n\'agit que sur demande';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation => null;

  const TakeInitiative._(this.index);
  static TakeInitiative get notEvaluated => const TakeInitiative._(-1);
  static TakeInitiative get veryHigh => const TakeInitiative._(0);
  static TakeInitiative get high => const TakeInitiative._(1);
  static TakeInitiative get low => const TakeInitiative._(2);
  static TakeInitiative get insufficient => const TakeInitiative._(3);

  static TakeInitiative fromIndex(int index) =>
      index < 0 ? TakeInitiative.notEvaluated : TakeInitiative.values[index];

  static List<TakeInitiative> get values => [
        TakeInitiative.veryHigh,
        TakeInitiative.high,
        TakeInitiative.low,
        TakeInitiative.insufficient,
      ];

  @override
  List<TakeInitiative> get validElements => TakeInitiative.values;
}

class Adaptability implements AttitudeCategoryEnum {
  @override
  String get title => 'Adaptation aux changements';

  @override
  String get definition =>
      'Utilisation de stratégies favorisant l\'adaptabilité au milieu de travail '
      '(ex : s\'inspirer des bons modèles de travailleurs)';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'S\'ajuste en fonction des changements qui surviennent ou qui lui sont demandés';
      case 1:
        return 'S\'ajuste souvent en fonction des changements qui surviennent ou qui lui sont demandés';
      case 2:
        return 'S\'ajuste avec un soutien ponctuel';
      case 3:
        return 'N\'arrive pas à s\'ajuster';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  @override
  String? get extraInformation =>
      'Nouvelles tâches, changement de tâches, imprévus, changement de travailleur '
      'parrain, changement horaire';

  const Adaptability._(this.index);
  static Adaptability get notEvaluated => const Adaptability._(-1);
  static Adaptability get veryHigh => const Adaptability._(0);
  static Adaptability get high => const Adaptability._(1);
  static Adaptability get low => const Adaptability._(2);
  static Adaptability get insufficient => const Adaptability._(3);

  static Adaptability fromIndex(int index) =>
      index < 0 ? Adaptability.notEvaluated : Adaptability.values[index];

  static List<Adaptability> get values => [
        Adaptability.veryHigh,
        Adaptability.high,
        Adaptability.low,
        Adaptability.insufficient,
      ];

  @override
  List<Adaptability> get validElements => Adaptability.values;
}
