enum VisitingPriority {
  low,
  mid,
  high,
  notApplicable,
  school;

  VisitingPriority get next => switch (this) {
        VisitingPriority.notApplicable ||
        VisitingPriority.school =>
          VisitingPriority.mid,
        _ => VisitingPriority.values[(index + 1) % 3]
      };

  int serialize() => index;

  static VisitingPriority? deserialize(dynamic element) {
    if (element == null) return null;
    try {
      return VisitingPriority.values[element as int];
    } catch (e) {
      return null;
    }
  }
}
