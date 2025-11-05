import 'package:enhanced_containers_foundation/enhanced_containers_foundation.dart';
import 'package:stagess_common/utils.dart';

extension ListExt on List {
  List serialize() {
    return map((e) {
      if (e is String) {
        return e.serialize();
      } else if (e is int) {
        return e.serialize();
      } else if (e is DateTime) {
        return e.serialize();
      } else if (e is ItemSerializable) {
        return e.serialize();
      } else {
        throw ArgumentError(
            'Unsupported type in list: ${e.runtimeType}. Only String, int, '
            'DateTime, and ItemSerializable are supported.');
      }
    }).toList();
  }

  static List<T>? from<T>(List? elements,
      {required T Function(dynamic) deserializer}) {
    if (elements == null) return null;
    return elements.map((e) => deserializer(e)).toList();
  }

  static List<T> mergeWithData<T extends ItemSerializable>(
    List<T> original,
    List? elements, {
    required T Function(T original, dynamic serialized) copyWithData,
    required T Function(dynamic serialized) deserializer,
  }) {
    final out = from(elements, deserializer: (serialized) {
          final e = original.firstWhereOrNull((e) => e.id == serialized?['id']);
          return e == null
              ? deserializer(serialized)
              : copyWithData(e, serialized);
        }) ??
        [];

    final outIds = out.map((s) => s.id).toSet();
    for (final element in original) {
      if (outIds.contains(element.id)) continue;
      out.add(element);
    }
    return out;
  }
}

extension MapExt<T> on Map<String, T> {
  Map<String, dynamic> serialize() {
    return map((key, value) {
      if (value is String) {
        return MapEntry(key, value.serialize());
      } else if (value is int) {
        return MapEntry(key, value.serialize());
      } else if (value is DateTime) {
        return MapEntry(key, value.serialize());
      } else if (value is ItemSerializable) {
        return MapEntry(key, value.serialize());
      } else {
        throw ArgumentError(
            'Unsupported type in map: ${value.runtimeType}. Only String, int, '
            'DateTime, and ItemSerializable are supported.');
      }
    });
  }

  static Map<String, T>? from<T>(Map? elements,
      {required T Function(dynamic) deserializer}) {
    if (elements == null) return null;
    return {
      for (var entry in elements.entries) entry.key: deserializer(entry.value),
    };
  }
}

extension StringExt on String {
  String serialize() => this;

  static String? from(dynamic element) => element?.toString();
}

extension BoolExt on bool {
  bool serialize() => this;

  static bool? from(dynamic element) {
    if (element is bool) {
      return element;
    } else if (element is int) {
      return element != 0;
    } else {
      return null;
    }
  }
}

extension IntExt on int {
  int serialize() => this;

  static int? from(dynamic element) {
    if (element is int) {
      return element;
    } else if (element is String) {
      return int.tryParse(element);
    } else {
      return null;
    }
  }
}

extension DateTimeExt on DateTime {
  int serialize() => millisecondsSinceEpoch;

  static DateTime? from(dynamic element) {
    if (element == null) return null;
    try {
      final date = DateTime.fromMillisecondsSinceEpoch(element as int);
      // We take an arbitrary small date to account for the rounding error
      // that are introduced when storing the date as an int. DateTime(2000)
      // is still way before any realistic useful date.
      return date.isBefore(DateTime(2000)) ? DateTime(0) : date;
    } catch (e) {
      return null;
    }
  }
}
