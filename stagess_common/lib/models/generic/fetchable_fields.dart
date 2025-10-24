class FetchableFields {
  final bool isReference;
  final bool includeAll;
  final bool isMandatory;
  final Map<String, FetchableFields> _fields;

  ///
  /// Constructor dedicated to the reference [FetchableFields], that is the one
  /// containing all the fields and their subfields, and their mandatory status.
  FetchableFields.reference(Map<String, FetchableFields> fields)
      : isReference = true,
        includeAll = false,
        isMandatory = false,
        _fields = fields {
    // Filters the current fields, but ignore the return. This is useful to
    // make sure that no "includeAll" fields are in the reference.
    filter(FetchableFields.none, keepMandatory: true);
  }

  FetchableFields extractFrom(Iterable fieldNames) {
    final out = FetchableFields.none;
    for (final fieldName in fieldNames) {
      if (fieldName is String) {
        final current = this[fieldName];
        if (current == null) continue;
        out[fieldName] = current;
      } else if (fieldNames is List) {
        out.addAll(extractFrom(fieldName));
      }
    }
    return out;
  }

  FetchableFields(Map<String, FetchableFields> fields)
      : isReference = false,
        _fields = fields,
        includeAll = false,
        isMandatory = false;

  FetchableFields._({
    required this.isReference,
    required this.includeAll,
    required this.isMandatory,
    required Map<String, FetchableFields> fields,
  }) : _fields = fields {
    if (isMandatory && hasSubfields) {
      throw 'A FetchableFields cannot be both mandatory and have subfields';
    }
    if (includeAll && hasSubfields) {
      throw 'A FetchableFields cannot include all fields and have subfields';
    }
    if (includeAll && isMandatory) {
      throw 'A FetchableFields cannot include all fields and be mandatory';
    }
  }

  Iterable<String> get fieldNames => _fields.keys;

  static FetchableFields get mandatory => FetchableFields._(
        isReference: false,
        includeAll: false,
        isMandatory: true,
        fields: {},
      );
  static FetchableFields get optional => FetchableFields._(
        isReference: false,
        includeAll: false,
        isMandatory: false,
        fields: {},
      );

  static FetchableFields get none => FetchableFields._(
        isReference: false,
        includeAll: false,
        isMandatory: false,
        fields: {},
      );
  static FetchableFields get all => FetchableFields._(
        isReference: false,
        includeAll: true,
        isMandatory: false,
        fields: {},
      );

  FetchableFields? operator [](String fieldName) {
    if (includeAll) {
      throw 'Cannot get a field from FetchableFields with includeAll = true';
    }
    return _fields[fieldName];
  }

  void operator []=(String fieldName, FetchableFields value) {
    if (includeAll) {
      throw 'Cannot set a field to FetchableFields with includeAll = true';
    }
    _fields[fieldName] = value;
  }

  FetchableFields filter(FetchableFields other, {bool keepMandatory = false}) {
    final out = FetchableFields.none;

    for (final fieldName in _fields.keys) {
      final current = _fields[fieldName]!;
      final otherCurrent = other[fieldName];

      if (current.includeAll) {
        throw 'The reference [FetchableFields] cannot have includeAll = true for any of its fields';
      } else if (current.isMandatory && keepMandatory) {
        out[fieldName] = current;
      } else if (other.includeAll) {
        out[fieldName] = current;
      } else if (otherCurrent != null) {
        if (current._fields.isEmpty) {
          out[fieldName] = current;
        } else {
          out[fieldName] =
              current.filter(otherCurrent, keepMandatory: keepMandatory);
        }
      } else if (keepMandatory && current.hasSubfields) {
        // We must travers all the local subfields to make sure we keep the mandatory ones
        final filt = current.filter(FetchableFields.none, keepMandatory: true);
        if (filt.hasSubfields) out[fieldName] = filt;
      }
    }
    return out;
  }

  Map<String, dynamic> get serialized {
    if (includeAll) {
      return {'include_all': true};
    }

    final Map<String, dynamic> out = <String, dynamic>{};
    for (final fieldName in _fields.keys) {
      if (_fields[fieldName]!._fields.isEmpty) {
        out[fieldName] = _fields[fieldName]!.isMandatory;
      } else {
        out[fieldName] = _fields[fieldName]!.serialized;
      }
    }
    return out;
  }

  static FetchableFields fromSerialized(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return FetchableFields.none;
    }

    final Map<String, FetchableFields> out = {};
    for (final entry in map.entries) {
      if (entry.key == 'include_all' && entry.value == true) {
        return FetchableFields.all;
      } else if (entry.value is bool) {
        out[entry.key] =
            entry.value ? FetchableFields.mandatory : FetchableFields.optional;
      } else if (entry.value is Map<String, dynamic>) {
        out[entry.key] = FetchableFields.fromSerialized(entry.value);
      } else {
        throw 'Invalid serialized FetchableFields format';
      }
    }

    return FetchableFields(out);
  }

  bool get hasSubfields => _fields.isNotEmpty;
  bool get hasData => hasSubfields || includeAll || isMandatory;
  bool get isEmpty => !hasData;

  FetchableFields getNonIntersectingFieldNames(
    FetchableFields first,
    FetchableFields second,
  ) {
    final FetchableFields out = FetchableFields.none;

    for (final name in fieldNames) {
      final firstField = first.includeAll ? first : first[name];
      final secondField = second.includeAll ? second : second[name];

      if (firstField == null && secondField == null) {
        // Do nothing
      } else if (firstField == null) {
        out[name] = secondField!.includeAll ? this[name]! : secondField;
      } else if (secondField == null) {
        out[name] = firstField.includeAll ? this[name]! : firstField;
      } else if ((firstField.hasSubfields || firstField.includeAll) &&
          (secondField.hasSubfields || secondField.includeAll)) {
        // Check the subfields for potential non-intersecting fields
        final tp =
            this[name]!.getNonIntersectingFieldNames(firstField, secondField);
        if (tp.hasData) out[name] = tp;
      }
    }
    return out;
  }

  bool containsFieldName(String fieldName) {
    if (includeAll) return true;
    return _fields.containsKey(fieldName);
  }

  bool contains(FetchableFields field) {
    if (includeAll) return true;

    for (final key in _fields.keys) {
      final subField = _fields[key];
      if (subField == null) return true;
      return subField.contains(field);
    }

    return false;
  }

  void addAll(FetchableFields other) {
    if (includeAll) return;
    if (other.includeAll) throw 'Not implemented yet';

    for (final entry in other._fields.entries) {
      if (_fields.containsKey(entry.key)) {
        if (entry.value.hasSubfields) {
          _fields[entry.key]?.addAll(entry.value);
        } else if (entry.value.isMandatory) {
          _fields[entry.key] = entry.value;
        }
      } else {
        _fields[entry.key] = entry.value;
      }
    }
  }
}
