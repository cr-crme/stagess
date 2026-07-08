import 'package:shared_preferences/shared_preferences.dart';
import 'package:stagess_common/models/internships/internship_evaluation_skill.dart';
import 'package:stagess_common/models/internships/schedule.dart';

class ConfigurationService {
  static bool _isInitialized = false;
  static Future<void> initializeServices() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await ConfigurationService._fetchDayCycleDefault();
    await ConfigurationService._fetchSkillEvaluationGranularityDefault();
  }

  static const expandingTileDuration = Duration(milliseconds: 300);

  static const showDevelopmentFeatures = bool.fromEnvironment(
      'STAGESS_SHOW_DEVELOPMENT_FEATURES',
      defaultValue: false);

  ///
  /// Day cycle to use
  static late DayCycle _dayCycleDefault;

  static Future<void> _fetchDayCycleDefault() async {
    _dayCycleDefault = await _loadPreference(
      key: 'default_day_cycle',
      defaultValue: DayCycle.weekdaysCycle,
      fromString: DayCycle.fromName,
    );
  }

  static DayCycle get dayCycleDefault {
    _checkInitialized();
    return _dayCycleDefault;
  }

  static set dayCycleDefault(DayCycle value) {
    _dayCycleDefault = value;

    _savePreference(
      key: 'default_day_cycle',
      value: value,
      toString: (d) => d.name,
    );
  }

  ///
  /// Skill evaluation granularity to use
  static late SkillEvaluationGranularity _skillEvaluationGranularityDefault;

  static Future<void> _fetchSkillEvaluationGranularityDefault() async {
    _skillEvaluationGranularityDefault = await _loadPreference(
      key: 'default_skill_evaluation_granularity',
      defaultValue: SkillEvaluationGranularity.global,
      fromString: SkillEvaluationGranularity.values.byName,
    );
  }

  static SkillEvaluationGranularity get skillEvaluationGranularityDefault {
    _checkInitialized();
    return _skillEvaluationGranularityDefault;
  }

  static set skillEvaluationGranularityDefault(
      SkillEvaluationGranularity value) {
    _skillEvaluationGranularityDefault = value;

    _savePreference(
      key: 'default_skill_evaluation_granularity',
      value: value,
      toString: (d) => d.name,
    );
  }
}

void _checkInitialized() {
  if (!ConfigurationService._isInitialized) {
    throw Exception(
      'ConfigurationService must be initialized before accessing.',
    );
  }
}

Future<T> _loadPreference<T>({
  required String key,
  required T defaultValue,
  required T Function(String) fromString,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(key);

  return value == null ? defaultValue : fromString(value);
}

Future<void> _savePreference<T>({
  required String key,
  required T value,
  required String Function(T) toString,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(key, toString(value));
}
