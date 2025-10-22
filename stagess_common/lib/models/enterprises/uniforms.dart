part of 'package:stagess_common/models/enterprises/job.dart';

enum UniformStatus {
  suppliedByEnterprise,
  suppliedByStudent,
  none;

  int _toInt(String version) {
    if (version == '1.0.0') {
      return index;
    }
    throw WrongVersionException(version, '1.0.0');
  }

  static UniformStatus _fromInt(int index, String version) {
    if (version == '1.0.0') {
      return UniformStatus.values[index];
    }
    throw WrongVersionException(version, '1.0.0');
  }

  @override
  String toString() {
    switch (this) {
      case suppliedByEnterprise:
        return 'Fournie par l\'entreprise';
      case suppliedByStudent:
        return 'Fournie par l\'élève';
      case none:
        return 'Aucune';
    }
  }
}

class Uniforms extends ItemSerializable {
  final UniformStatus status;
  final List<String> uniforms;

  Uniforms({super.id, required this.status, List<String>? uniforms})
      : uniforms = uniforms ?? [];

  static Uniforms get empty => Uniforms(
        status: UniformStatus.none,
        uniforms: [],
      );

  Uniforms.fromSerialized(super.map, String version)
      : status = map?['status'] == null
            ? UniformStatus.none
            : UniformStatus._fromInt(map?['status'] as int, version),
        uniforms =
            (map?['uniforms'] as List?)?.map((e) => e as String).toList() ?? [],
        super.fromSerialized();

  Uniforms copyWith({
    String? id,
    UniformStatus? status,
    List<String>? uniforms,
  }) {
    return Uniforms(
      id: id ?? this.id,
      status: status ?? this.status,
      uniforms: uniforms ?? this.uniforms,
    );
  }

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id.serialize(),
        'status': status._toInt(Job._currentVersion),
        'uniforms': uniforms,
      };

  @override
  String toString() {
    return 'Uniforms{status: ${status.name}, uniforms: $uniforms}';
  }
}
