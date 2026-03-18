enum TaskVariety {
  none,
  low,
  mid,
  high;

  double toDouble() {
    switch (this) {
      case TaskVariety.none:
        return -1.0;
      case TaskVariety.low:
        return 0.0;
      case TaskVariety.mid:
        return 0.5;
      case TaskVariety.high:
        return 1.0;
    }
  }

  @override
  String toString() {
    switch (this) {
      case TaskVariety.none:
        return 'Aucune varieté';
      case TaskVariety.low:
        return 'Peu variées';
      case TaskVariety.mid:
        return 'Variées';
      case TaskVariety.high:
        return 'Très variées';
    }
  }
}

enum TrainingPlan {
  none,
  followed,
  notFollowed;

  double toDouble() {
    switch (this) {
      case TrainingPlan.none:
        return -1.0;
      case TrainingPlan.notFollowed:
        return 0.0;
      case TrainingPlan.followed:
        return 1.0;
    }
  }

  @override
  String toString() {
    switch (this) {
      case TrainingPlan.none:
        return 'Non évalué';
      case TrainingPlan.notFollowed:
        return 'Non';
      case TrainingPlan.followed:
        return 'Oui';
    }
  }
}

enum RequiredSkills {
  communicateInWriting,
  communicateInEnglish,
  driveTrolley,
  interactWithCustomers,
  handleMoney;

  @override
  String toString() {
    switch (this) {
      case RequiredSkills.communicateInWriting:
        return 'Communiquer à l\'écrit';
      case RequiredSkills.communicateInEnglish:
        return 'Communiquer en anglais';
      case RequiredSkills.driveTrolley:
        return 'Conduire un chariot (élèves CFER)';
      case RequiredSkills.interactWithCustomers:
        return 'Interagir avec des clients';
      case RequiredSkills.handleMoney:
        return 'Manipuler de l\'argent';
    }
  }
}

enum AbsenceAcceptance {
  low,
  high;

  String get label {
    switch (this) {
      case AbsenceAcceptance.low:
        return 'Grande\ntolérance';
      case AbsenceAcceptance.high:
        return 'Tolérance\ntrès élevée';
    }
  }
}

enum EaseOfCommunication {
  low,
  high;

  String get label {
    switch (this) {
      case EaseOfCommunication.low:
        return 'Rétroaction\ndifficile à\nobtenir';
      case EaseOfCommunication.high:
        return 'Rétroaction\ntrès facile à\nobtenir';
    }
  }
}

enum SupervisionStyle {
  low,
  high;

  String get label {
    switch (this) {
      case SupervisionStyle.low:
        return 'Milieu peu\nencadrant';
      case SupervisionStyle.high:
        return 'Milieu très\nencadrant';
    }
  }
}

enum EfficiencyExpected {
  low,
  high;

  String get label {
    switch (this) {
      case EfficiencyExpected.low:
        return 'Aucun\nrendement\nexigé';
      case EfficiencyExpected.high:
        return 'Élève\nproductif';
    }
  }
}

enum SpecialNeedsAccommodation {
  low,
  high;

  String get label {
    switch (this) {
      case SpecialNeedsAccommodation.low:
        return 'Aucune\nouverture';
      case SpecialNeedsAccommodation.high:
        return 'Grande\nouverture';
    }
  }
}

enum SstSupervision {
  low,
  high;

  String get label {
    switch (this) {
      case SstSupervision.low:
        return 'Insuffisant';
      case SstSupervision.high:
        return 'Rigoureux';
    }
  }
}

enum AutonomyExpected {
  low,
  high;

  String get label {
    switch (this) {
      case AutonomyExpected.low:
        return 'Élève pas\nautonome';
      case AutonomyExpected.high:
        return 'Élève très\nautonome';
    }
  }
}

enum Disabilities {
  autismSpectrumDisorder,
  languageDisorder,
  intellectualDisability,
  physicalDisability,
  mentalHealthDisorder,
  behavioralDifficulties;

  @override
  String toString() {
    switch (this) {
      case Disabilities.autismSpectrumDisorder:
        return 'Un trouble du spectre de l\'autisme (TSA)';
      case Disabilities.languageDisorder:
        return 'Un trouble du langage';
      case Disabilities.intellectualDisability:
        return 'Une déficience intellectuelle';
      case Disabilities.physicalDisability:
        return 'Une déficience physique';
      case Disabilities.mentalHealthDisorder:
        return 'Un trouble de santé mentale';
      case Disabilities.behavioralDifficulties:
        return 'Des difficultés comportementales';
    }
  }

  double toDouble() {
    switch (this) {
      case Disabilities.autismSpectrumDisorder:
      case Disabilities.languageDisorder:
      case Disabilities.intellectualDisability:
      case Disabilities.physicalDisability:
      case Disabilities.mentalHealthDisorder:
      case Disabilities.behavioralDifficulties:
        return 1.0;
    }
  }
}
