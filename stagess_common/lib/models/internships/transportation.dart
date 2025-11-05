enum Transportation {
  none,
  yes,
  ticket,
  pass;

  @override
  String toString() {
    switch (this) {
      case Transportation.none:
        return 'Non';
      case Transportation.yes:
        return 'Oui';
      case Transportation.ticket:
        return 'Billet';
      case Transportation.pass:
        return 'Passe';
    }
  }

  static Transportation deserialize(dynamic index) {
    if (index is int) {
      if (index < 0 || index >= Transportation.values.length) {
        return Transportation.none;
      }
      return Transportation.values[index];
    } else if (index is String) {
      return Transportation.values.firstWhere(
        (e) => e.toString().toLowerCase() == index.toLowerCase(),
        orElse: () => Transportation.none,
      );
    }
    return Transportation.none;
  }

  int serialize() => index;
}
