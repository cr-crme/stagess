enum AccessLevel {
  invalid,
  teacher,
  admin,
  superAdmin;

  bool operator >=(AccessLevel other) {
    return index >= other.index;
  }

  bool operator >(AccessLevel other) {
    return index > other.index;
  }

  bool operator <=(AccessLevel other) {
    return index <= other.index;
  }

  bool operator <(AccessLevel other) {
    return index < other.index;
  }

  int serialize() {
    return index;
  }

  static AccessLevel fromSerialized(dynamic value) {
    if (value == null) return AccessLevel.invalid;
    if (value < 0 || value >= AccessLevel.values.length) {
      throw ArgumentError('Invalid access level value: $value');
    }
    return AccessLevel.values[value];
  }
}
