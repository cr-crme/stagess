import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';

class VisaEvaluation extends ItemSerializable {
  Inattendance inattendance;
  Ponctuality ponctuality;
  Sociability sociability;
  Politeness politeness;
  Motivation motivation;
  DressCode dressCode;
  QualityOfWork qualityOfWork;
  Productivity productivity;
  Autonomy autonomy;
  Cautiousness cautiousness;
  GeneralAppreciation generalAppreciation;

  List<String> _fromRequirements(int min, int max) {
    List<String> out = [];
    if (isBetween(inattendance, min, max)) out.add(Inattendance.title);
    if (isBetween(ponctuality, min, max)) out.add(Ponctuality.title);
    if (isBetween(sociability, min, max)) out.add(Sociability.title);
    if (isBetween(politeness, min, max)) out.add(Politeness.title);
    if (isBetween(motivation, min, max)) out.add(Motivation.title);
    if (isBetween(dressCode, min, max)) out.add(DressCode.title);
    if (isBetween(qualityOfWork, min, max)) out.add(QualityOfWork.title);
    if (isBetween(productivity, min, max)) out.add(Productivity.title);
    if (isBetween(autonomy, min, max)) out.add(Autonomy.title);
    if (isBetween(cautiousness, min, max)) out.add(Cautiousness.title);
    return out;
  }

  List<String> get meetsRequirements => _fromRequirements(0, 1);
  List<String> get doesNotMeetRequirements => _fromRequirements(2, 3);

  VisaEvaluation({
    super.id,
    required this.inattendance,
    required this.ponctuality,
    required this.sociability,
    required this.politeness,
    required this.motivation,
    required this.dressCode,
    required this.qualityOfWork,
    required this.productivity,
    required this.autonomy,
    required this.cautiousness,
    required this.generalAppreciation,
  });
  VisaEvaluation.fromSerialized(super.map)
      : inattendance = Inattendance.fromIndex(map?['inattendance'] ?? -1),
        ponctuality = Ponctuality.fromIndex(map?['ponctuality'] ?? -1),
        sociability = Sociability.fromIndex(map?['sociability'] ?? -1),
        politeness = Politeness.fromIndex(map?['politeness'] ?? -1),
        motivation = Motivation.fromIndex(map?['motivation'] ?? -1),
        dressCode = DressCode.fromIndex(map?['dressCode'] ?? -1),
        qualityOfWork = QualityOfWork.fromIndex(map?['quality_of_work'] ?? -1),
        productivity = Productivity.fromIndex(map?['productivity'] ?? -1),
        autonomy = Autonomy.fromIndex(map?['autonomy'] ?? -1),
        cautiousness = Cautiousness.fromIndex(map?['cautiousness'] ?? -1),
        generalAppreciation =
            GeneralAppreciation.fromIndex(map?['general_appreciation'] ?? -1),
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'inattendance': inattendance.index,
      'ponctuality': ponctuality.index,
      'sociability': sociability.index,
      'politeness': politeness.index,
      'motivation': motivation.index,
      'dressCode': dressCode.index,
      'quality_of_work': qualityOfWork.index,
      'productivity': productivity.index,
      'autonomy': autonomy.index,
      'cautiousness': cautiousness.index,
      'general_appreciation': generalAppreciation.index,
    };
  }

  @override
  String toString() {
    return 'VisaEvaluation{inattendance: ${inattendance.name}, '
        'ponctuality: ${ponctuality.name}, '
        'sociability: ${sociability.name}, '
        'politeness: ${politeness.name}, '
        'motivation: ${motivation.name}, '
        'dressCode: ${dressCode.name}, '
        'qualityOfWork: ${qualityOfWork.name}, '
        'productivity: ${productivity.name}, '
        'autonomy: ${autonomy.name}, '
        'cautiousness: ${cautiousness.name}, '
        'generalAppreciation: ${generalAppreciation.name}}';
  }
}

class InternshipEvaluationVisa extends ItemSerializable {
  static const String currentVersion = '1.0.0';

  DateTime date;
  VisaEvaluation form;
  String
      formVersion; // The version of the evaluation form (so data can be parsed properly)

  InternshipEvaluationVisa({
    super.id,
    required this.date,
    required this.form,
    required this.formVersion,
  });
  InternshipEvaluationVisa.fromSerialized(super.map)
      : date = map?['date'] == null
            ? DateTime(0)
            : DateTime.fromMillisecondsSinceEpoch(map!['date']),
        form = VisaEvaluation.fromSerialized(map?['form'] ?? {}),
        formVersion = map?['form_version'] ?? currentVersion,
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'id': id,
      'date': date.millisecondsSinceEpoch,
      'form': form.serialize(),
      'form_version': formVersion,
    };
  }

  @override
  String toString() {
    return 'InternshipEvaluationVisa(date: $date, '
        'form: $form.toString(), ';
  }
}

abstract class VisaCategoryEnum {
  String get name;
  int get index;
}

bool isBetween(VisaCategoryEnum category, int min, int max) {
  return category.index >= min && category.index <= max;
}

class Inattendance implements VisaCategoryEnum {
  static String get title => 'Assiduité';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Aucune absence';
      case 1:
        return 'S\'absente rarement et avise';
      case 2:
        return 'Quelques absences injustifiées';
      case 3:
        return 'Absences fréquentes et injustifiées';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const Inattendance._(this.index);
  static Inattendance get notEvaluated => const Inattendance._(-1);
  static Inattendance get never => const Inattendance._(0);
  static Inattendance get rarely => const Inattendance._(1);
  static Inattendance get sometime => const Inattendance._(2);
  static Inattendance get frequently => const Inattendance._(3);

  static Inattendance fromIndex(int index) =>
      index < 0 ? Inattendance.notEvaluated : Inattendance.values[index];

  static List<Inattendance> get values => [
        Inattendance.never,
        Inattendance.rarely,
        Inattendance.sometime,
        Inattendance.frequently,
      ];
}

class Ponctuality implements VisaCategoryEnum {
  static String get title => 'Ponctualité';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Toujours à l\'heure';
      case 1:
        return 'Quelques retards justifiés';
      case 2:
        return 'Quelques retards injustifiés';
      case 3:
        return 'Retards fréquents et injustifiés';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const Ponctuality._(this.index);
  static Ponctuality get notEvaluated => const Ponctuality._(-1);
  static Ponctuality get highly => const Ponctuality._(0);
  static Ponctuality get mostly => const Ponctuality._(1);
  static Ponctuality get sometimeLate => const Ponctuality._(2);
  static Ponctuality get frequentlyLate => const Ponctuality._(3);

  static Ponctuality fromIndex(int index) =>
      index < 0 ? Ponctuality.notEvaluated : Ponctuality.values[index];

  static List<Ponctuality> get values => [
        Ponctuality.highly,
        Ponctuality.mostly,
        Ponctuality.sometimeLate,
        Ponctuality.frequentlyLate,
      ];
}

class Sociability implements VisaCategoryEnum {
  static String get title => 'Sociabilité';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Très sociable';
      case 1:
        return 'Sociable';
      case 2:
        return 'Établit très peu de contacts';
      case 3:
        return 'Pas d\'intégration à l\'équipe de travail';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const Sociability._(this.index);
  static Sociability get notEvaluated => const Sociability._(-1);
  static Sociability get veryHigh => const Sociability._(0);
  static Sociability get high => const Sociability._(1);
  static Sociability get low => const Sociability._(2);
  static Sociability get veryLow => const Sociability._(3);

  static Sociability fromIndex(int index) =>
      index < 0 ? Sociability.notEvaluated : Sociability.values[index];

  static List<Sociability> get values => [
        Sociability.veryHigh,
        Sociability.high,
        Sociability.low,
        Sociability.veryLow,
      ];
}

class Politeness implements VisaCategoryEnum {
  static String get title => 'Politesse et langage';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Langage exemplaire en tout temps';
      case 1:
        return 'Langage convenable en tout temps';
      case 2:
        return 'Langage convenable la plupart du temps';
      case 3:
        return 'Langage inapproprié';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const Politeness._(this.index);
  static Politeness get notEvaluated => const Politeness._(-1);
  static Politeness get exemplary => const Politeness._(0);
  static Politeness get alwaysSuitable => const Politeness._(1);
  static Politeness get mostlySuitable => const Politeness._(2);
  static Politeness get inappropriate => const Politeness._(3);

  static Politeness fromIndex(int index) =>
      index < 0 ? Politeness.notEvaluated : Politeness.values[index];

  static List<Politeness> get values => [
        Politeness.exemplary,
        Politeness.alwaysSuitable,
        Politeness.mostlySuitable,
        Politeness.inappropriate,
      ];
}

class Motivation implements VisaCategoryEnum {
  static String get title => 'Motivation';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Très grand intérêt pour son travail';
      case 1:
        return 'Intérêt marqué';
      case 2:
        return 'Peu d\'intérêt';
      case 3:
        return 'Aucun intérêt';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const Motivation._(this.index);
  static Motivation get notEvaluated => const Motivation._(-1);
  static Motivation get veryHigh => const Motivation._(0);
  static Motivation get high => const Motivation._(1);
  static Motivation get low => const Motivation._(2);
  static Motivation get none => const Motivation._(3);

  static Motivation fromIndex(int index) =>
      index < 0 ? Motivation.notEvaluated : Motivation.values[index];

  static List<Motivation> get values => [
        Motivation.veryHigh,
        Motivation.high,
        Motivation.low,
        Motivation.none,
      ];
}

class DressCode implements VisaCategoryEnum {
  static String get title => 'Tenue vestimentaire';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Très soignée, très propre';
      case 1:
        return 'Soignée et propre';
      case 2:
        return 'Négligée';
      case 3:
        return 'Très négligée, malpropre';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const DressCode._(this.index);
  static DressCode get notEvaluated => const DressCode._(-1);
  static DressCode get highlyAppropriate => const DressCode._(0);
  static DressCode get appropriate => const DressCode._(1);
  static DressCode get poorlyAppropriate => const DressCode._(2);
  static DressCode get notAppropriate => const DressCode._(3);

  static DressCode fromIndex(int index) =>
      index < 0 ? DressCode.notEvaluated : DressCode.values[index];

  static List<DressCode> get values => [
        DressCode.highlyAppropriate,
        DressCode.appropriate,
        DressCode.poorlyAppropriate,
        DressCode.notAppropriate,
      ];
}

class QualityOfWork implements VisaCategoryEnum {
  static String get title => 'Qualité du travail';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'S\'applique et travail avec précision';
      case 1:
        return 'Commet quelques erreurs, mais persévère';
      case 2:
        return 'Manque d\'application et/ou exige une supervision';
      case 3:
        return 'Comment souvent des erreurs et néglige les méthodes de travail';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const QualityOfWork._(this.index);
  static QualityOfWork get notEvaluated => const QualityOfWork._(-1);
  static QualityOfWork get veryHigh => const QualityOfWork._(0);
  static QualityOfWork get high => const QualityOfWork._(1);
  static QualityOfWork get low => const QualityOfWork._(2);
  static QualityOfWork get negligent => const QualityOfWork._(3);

  static QualityOfWork fromIndex(int index) =>
      index < 0 ? QualityOfWork.notEvaluated : QualityOfWork.values[index];

  static List<QualityOfWork> get values => [
        QualityOfWork.veryHigh,
        QualityOfWork.high,
        QualityOfWork.low,
        QualityOfWork.negligent,
      ];
}

class Productivity implements VisaCategoryEnum {
  static String get title => 'Rendement et constance';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Rendement et rythme de travail excellents';
      case 1:
        return 'Rendement et rythme de travail bons et constants';
      case 2:
        return 'Difficulté à maintenir le rythme de travail';
      case 3:
        return 'Rendement insuffisant';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

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
}

class Autonomy implements VisaCategoryEnum {
  static String get title => 'Autonomie et sens de l\'initiative';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Prend très souvent de bonnes initiatives';
      case 1:
        return 'Prend souvent de bonnes initiatives';
      case 2:
        return 'Peu d\'initiative';
      case 3:
        return 'Aucune initiative';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const Autonomy._(this.index);
  static Autonomy get notEvaluated => const Autonomy._(-1);
  static Autonomy get veryHigh => const Autonomy._(0);
  static Autonomy get high => const Autonomy._(1);
  static Autonomy get low => const Autonomy._(2);
  static Autonomy get none => const Autonomy._(3);

  static Autonomy fromIndex(int index) =>
      index < 0 ? Autonomy.notEvaluated : Autonomy.values[index];

  static List<Autonomy> get values => [
        Autonomy.veryHigh,
        Autonomy.high,
        Autonomy.low,
        Autonomy.none,
      ];
}

class Cautiousness implements VisaCategoryEnum {
  static String get title =>
      'Respect des règles de santé et de sécurité du travail (SST)';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Toujours';
      case 1:
        return 'Souvent';
      case 2:
        return 'Parfois';
      case 3:
        return 'Rarement';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const Cautiousness._(this.index);
  static Cautiousness get notEvaluated => const Cautiousness._(-1);
  static Cautiousness get always => const Cautiousness._(0);
  static Cautiousness get mostly => const Cautiousness._(1);
  static Cautiousness get sometime => const Cautiousness._(2);
  static Cautiousness get rarely => const Cautiousness._(3);

  static Cautiousness fromIndex(int index) =>
      index < 0 ? Cautiousness.notEvaluated : Cautiousness.values[index];

  static List<Cautiousness> get values => [
        Cautiousness.always,
        Cautiousness.mostly,
        Cautiousness.sometime,
        Cautiousness.rarely,
      ];
}

class GeneralAppreciation implements VisaCategoryEnum {
  static String get title => 'Appréciation générale du ou de la stagiaire';

  @override
  final int index;

  @override
  String get name {
    switch (index) {
      case -1:
        return 'Non évalué';
      case 0:
        return 'Dépasse les attentes';
      case 1:
        return 'Répond aux attentes';
      case 2:
        return 'Répond minimalement aux attentes';
      case 3:
        return 'Ne répond pas aux attentes';
      default:
        // This should be unreachable code
        throw 'Wrong choice of $title'; // coverage:ignore-line
    }
  }

  const GeneralAppreciation._(this.index);
  static GeneralAppreciation get notEvaluated =>
      const GeneralAppreciation._(-1);
  static GeneralAppreciation get veryHigh => const GeneralAppreciation._(0);
  static GeneralAppreciation get good => const GeneralAppreciation._(1);
  static GeneralAppreciation get passable => const GeneralAppreciation._(2);
  static GeneralAppreciation get failed => const GeneralAppreciation._(3);

  static GeneralAppreciation fromIndex(int index) => index < 0
      ? GeneralAppreciation.notEvaluated
      : GeneralAppreciation.values[index];

  static List<GeneralAppreciation> get values => [
        GeneralAppreciation.veryHigh,
        GeneralAppreciation.good,
        GeneralAppreciation.passable,
        GeneralAppreciation.failed,
      ];
}
