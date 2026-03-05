enum Transportation {
  walk,
  publicTransport,
  adaptedTransport;

  @override
  String toString() {
    switch (this) {
      case Transportation.walk:
        return 'Marche';
      case Transportation.publicTransport:
        return 'Transport en commun';
      case Transportation.adaptedTransport:
        return 'Transport adapté';
    }
  }

  static Transportation deserialize(dynamic index) {
    if (index is int) {
      if (index < 0 || index >= Transportation.values.length) {
        return Transportation.walk;
      }
      return Transportation.values[index];
    } else if (index is String) {
      return Transportation.values.firstWhere(
        (e) => e.toString().toLowerCase() == index.toLowerCase(),
        orElse: () => Transportation.walk,
      );
    }
    return Transportation.walk;
  }

  int serialize() => index;
}
