part of 'package:stagess_common/models/enterprises/job.dart';

enum ProtectionsStatus {
  suppliedByEnterprise,
  suppliedBySchool,
  none;

  int _toInt(String version) {
    if (version == '1.0.0') {
      return index;
    }
    throw WrongVersionException(version, '1.0.0');
  }

  static ProtectionsStatus _fromInt(int index, String version) {
    if (version == '1.0.0') {
      return ProtectionsStatus.values[index];
    }
    throw WrongVersionException(version, '1.0.0');
  }

  @override
  String toString() {
    switch (this) {
      case ProtectionsStatus.suppliedByEnterprise:
        return 'Oui et l\'entreprise les fournit';
      case ProtectionsStatus.suppliedBySchool:
        return 'Oui mais l\'entreprise ne les fournit pas';
      case ProtectionsStatus.none:
        return 'Non';
    }
  }
}

enum ProtectionsType {
  steelToeShoes,
  nonSlipSoleShoes,
  safetyGlasses,
  earProtection,
  mask,
  helmet,
  gloves;

  @override
  String toString() {
    switch (this) {
      case ProtectionsType.steelToeShoes:
        return 'Chaussures à cap d\'acier';
      case ProtectionsType.nonSlipSoleShoes:
        return 'Chaussures à semelles antidérapantes';
      case ProtectionsType.safetyGlasses:
        return 'Lunettes de sécurité';
      case ProtectionsType.earProtection:
        return 'Protections auditives';
      case ProtectionsType.mask:
        return 'Masque';
      case ProtectionsType.helmet:
        return 'Casque';
      case ProtectionsType.gloves:
        return 'Gants';
    }
  }
}

class Protections extends ItemSerializable {
  ProtectionsStatus status;
  List<String> protections;

  Protections({super.id, required this.status, List<String>? protections})
      : protections = protections ?? [];

  static Protections get empty => Protections(
        status: ProtectionsStatus.none,
        protections: [],
      );

  Protections.fromSerialized(super.map)
      : status = map?['status'] == null
            ? ProtectionsStatus.none
            : ProtectionsStatus._fromInt(
                map?['status'] as int, map?['version'] ?? Job._currentVersion),
        protections =
            (map?['protections'] as List? ?? []).map<String>((e) => e).toList(),
        super.fromSerialized();

  Protections copyWith({
    String? id,
    ProtectionsStatus? status,
    List<String>? protections,
  }) {
    return Protections(
      id: id ?? this.id,
      status: status ?? this.status,
      protections: protections ?? this.protections,
    );
  }

  @override
  Map<String, dynamic> serializedMap() => {
        'id': id,
        'status': status._toInt(Job._currentVersion),
        'protections': protections,
      };

  @override
  String toString() {
    return 'Protections{status: ${status.name}, protections: $protections}';
  }
}
