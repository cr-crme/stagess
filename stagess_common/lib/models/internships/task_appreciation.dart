import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';

List<TaskAppreciationLevel> get byTaskAppreciationLevel => [
      TaskAppreciationLevel.autonomous,
      TaskAppreciationLevel.withReminder,
      TaskAppreciationLevel.withHelp,
      TaskAppreciationLevel.withConstantHelp,
      TaskAppreciationLevel.notEvaluated,
    ];

enum TaskAppreciationLevel {
  autonomous,
  withReminder,
  withHelp,
  withConstantHelp,
  notEvaluated,
  // The appreciation level does not apply when evaluating globally, we are
  // only interested to know if the task was evaluated or not
  evaluated;

  @override
  String toString() {
    switch (this) {
      case TaskAppreciationLevel.autonomous:
        return 'De façon autonome';
      case TaskAppreciationLevel.withReminder:
        return 'Avec rappel';
      case TaskAppreciationLevel.withHelp:
        return 'Avec de l\'aide occasionnelle';
      case TaskAppreciationLevel.withConstantHelp:
        return 'Avec de l\'aide constante';
      case TaskAppreciationLevel.notEvaluated:
        return 'Non faite (élève ne fait pas encore la tâche ou cette tâche '
            'n\'est pas offerte dans le milieu)';
      case TaskAppreciationLevel.evaluated:
        return '';
    }
  }

  String abbreviation() {
    switch (this) {
      case TaskAppreciationLevel.autonomous:
        return 'A';
      case TaskAppreciationLevel.withReminder:
        return 'B';
      case TaskAppreciationLevel.withHelp:
        return 'C';
      case TaskAppreciationLevel.withConstantHelp:
        return 'D';
      case TaskAppreciationLevel.notEvaluated:
        return 'NF';
      case TaskAppreciationLevel.evaluated:
        return '';
    }
  }
}

class TaskAppreciation extends ItemSerializable {
  final String title;
  final TaskAppreciationLevel level;

  TaskAppreciation({super.id, required this.title, required this.level});

  TaskAppreciation.fromSerialized(super.map)
      : title = map?['title'] ?? '',
        level = map?['level'] == null
            ? TaskAppreciationLevel.notEvaluated
            : TaskAppreciationLevel.values[map?['level']],
        super.fromSerialized();

  @override
  Map<String, dynamic> serializedMap() =>
      {'id': id, 'title': title, 'level': level.index};

  @override
  String toString() =>
      'TaskAppreciation { id: $id, title: $title, level: $level }';
}
