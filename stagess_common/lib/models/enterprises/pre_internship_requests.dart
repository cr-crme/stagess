part of 'package:stagess_common/models/enterprises/job.dart';

enum PreInternshipRequestTypes {
  soloInterview,
  judiciaryBackgroundCheck;

  @override
  String toString() {
    switch (this) {
      case soloInterview:
        return 'Une entrevue de recrutement de l\'élève en solo';
      case judiciaryBackgroundCheck:
        return 'Une vérification des antécédents judiciaires pour les élèves majeurs';
    }
  }

  static PreInternshipRequestTypes? fromString(String value) {
    for (final type in PreInternshipRequestTypes.values) {
      if (type.toString() == value) {
        return type;
      }
    }
    return null;
  }

  int _toInt(String version) {
    if (version == '1.0.0') {
      return index;
    }
    throw WrongVersionException(version, '1.0.0');
  }

  static PreInternshipRequestTypes _fromInt(int index, String version) {
    if (version == '1.0.0') {
      return PreInternshipRequestTypes.values[index];
    }
    throw WrongVersionException(version, '1.0.0');
  }
}

class PreInternshipRequests extends ItemSerializable {
  final List<PreInternshipRequestTypes> requests;
  final String? other;
  final bool isApplicable;

  PreInternshipRequests({
    super.id,
    required this.requests,
    required this.other,
    required this.isApplicable,
  });

  static PreInternshipRequests get empty => PreInternshipRequests(
        requests: [],
        other: null,
        isApplicable: true,
      );

  factory PreInternshipRequests.fromStrings(List<String> values, {String? id}) {
    final requests = <PreInternshipRequestTypes>[];
    bool isApplicable = true;
    String? other;
    for (final e in values) {
      if (e == '__NOT_APPLICABLE_INTERNAL__') {
        isApplicable = false;
        continue;
      }
      final asNum = int.tryParse(e);
      if (asNum == null) {
        final type = PreInternshipRequestTypes.fromString(e);
        if (type == null) {
          other = e;
        } else {
          requests.add(type);
        }
      } else {
        final type =
            PreInternshipRequestTypes._fromInt(asNum, Job._currentVersion);
        requests.add(type);
      }
    }

    return PreInternshipRequests(
        id: id, requests: requests, other: other, isApplicable: isApplicable);
  }

  PreInternshipRequests copyWith({
    String? id,
    List<PreInternshipRequestTypes>? requests,
    String? other,
    bool? isApplicable,
  }) {
    return PreInternshipRequests(
      id: id ?? this.id,
      requests: requests ?? this.requests,
      other: other ?? this.other,
      isApplicable: isApplicable ?? this.isApplicable,
    );
  }

  @override
  Map<String, dynamic> serializedMap() {
    return {
      'requests': requests.map((e) => e._toInt(Job._currentVersion)).toList(),
      'other': other,
      'is_applicable': isApplicable,
    };
  }

  static FetchableFields get fetchableFields => FetchableFields.reference({
        'id': FetchableFields.mandatory,
        'requests': FetchableFields.optional,
        'other': FetchableFields.optional,
        'is_applicable': FetchableFields.optional,
      });

  static PreInternshipRequests fromSerialized(
    Map<String, dynamic> map,
    String version,
  ) {
    return PreInternshipRequests(
      id: map['id'] as String?,
      requests: ((map['requests'] as List<dynamic>?) ?? [])
          .map((e) => PreInternshipRequestTypes._fromInt(e, version))
          .toList(),
      other: map['other'] as String?,
      isApplicable: map['is_applicable'] as bool? ?? true,
    );
  }
}
