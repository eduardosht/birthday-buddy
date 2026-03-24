import 'package:shared_preferences/shared_preferences.dart';

/// Tracks which people have been "Verificado" (checked) today.
/// The check is valid only for the calendar date it was made.
class CheckedTodayService {
  static String _key(String personId) {
    final today = DateTime.now();
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return 'checked_today_${date}_$personId';
  }

  static Future<bool> isChecked(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(personId)) ?? false;
  }

  static Future<void> markChecked(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(personId), true);
  }
}
