import 'package:shared_preferences/shared_preferences.dart';
import 'package:stagess_common/models/internships/schedule.dart';

class ConfigurationService {
  static bool _isInitialized = false;
  static Future<void> initializeServices() async {
    if (_isInitialized) return;
    _isInitialized = true;
    await ConfigurationService._fetchDayCycleDefault();
  }

  static const expandingTileDuration = Duration(milliseconds: 300);

  static DayCycle? _dayCycleDefault;
  static Future<void> _fetchDayCycleDefault() async {
    final preferences = await SharedPreferences.getInstance();

    final defaultDayCycle = preferences.getString('default_day_cycle');
    _dayCycleDefault = defaultDayCycle == null
        ? DayCycle.weekdaysCycle
        : DayCycle.fromName(defaultDayCycle);
  }

  static DayCycle get dayCycleDefault {
    if (!_isInitialized) {
      throw Exception(
          'ConfigurationService must be initialized before accessing. '
          'Call ConfigurationService.initializeServices() before using the service.');
    }

    return _dayCycleDefault!;
  }

  static set dayCycleDefault(DayCycle dayCycle) {
    _dayCycleDefault = dayCycle;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('default_day_cycle', dayCycle.name);
    });
  }
}
