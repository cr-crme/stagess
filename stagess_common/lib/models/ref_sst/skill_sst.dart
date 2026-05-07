class SkillSst {
  const SkillSst({
    required this.name,
    required this.code,
    required this.criterias,
    required this.tasks,
    required this.risks, //There are sometimes no risks
  });

  final String name;
  final int code;
  final List<String> criterias;
  final List<String> tasks;
  final Map<String, bool> risks;

  @override
  String toString() {
    return '{Skill #$code: $name}';
  }
}
