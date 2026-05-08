import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:stagess_common/models/ref_sst/risk.dart';

abstract class RiskDataFileService {
  static List<Risk> _risks = [];
  static List<Risk> get risks => _risks;

  static Future<void> loadData() async {
    final file = await rootBundle
        .loadString('packages/stagess_common_flutter/assets/risks-data.json');
    final json = jsonDecode(file) as List;

    _risks = List.from(
      json.map((e) => Risk.fromSerialized(e)),
      growable: false,
    );
  }

  static Risk? fromId(String id) {
    return _risks.firstWhereOrNull((risk) => risk.id == id);
  }

  static Risk? fromAbbrv(String abbrv) {
    return _risks.firstWhereOrNull((risk) => risk.abbrv == abbrv);
  }
}
