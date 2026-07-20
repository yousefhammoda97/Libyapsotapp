import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores today's processed shipments locally on the device.
/// Automatically resets when the date changes (new day = empty history).
class DailyHistoryService {
  static const _keyDate = 'history_date';
  static const _keyItems = 'history_items';

  static String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Call this once when the app loads a screen that shows history.
  /// Wipes stored items automatically if the date has rolled over.
  static Future<void> _ensureFreshDay(SharedPreferences prefs) async {
    final storedDate = prefs.getString(_keyDate);
    final todayStr = _today();
    if (storedDate != todayStr) {
      await prefs.setString(_keyDate, todayStr);
      await prefs.setStringList(_keyItems, []);
    }
  }

  static Future<void> addEntry({
    required String itemId,
    required String officeCd,
    required bool delivered,
    String? reason,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureFreshDay(prefs);

    final entry = {
      'item_id': itemId,
      'office_cd': officeCd,
      'status': delivered ? 'delivered' : 'not_delivered',
      'reason': reason,
      'time': DateTime.now().toIso8601String(),
    };

    final items = prefs.getStringList(_keyItems) ?? [];
    items.insert(0, jsonEncode(entry)); // newest first
    await prefs.setStringList(_keyItems, items);
  }

  static Future<List<Map<String, dynamic>>> getTodayEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureFreshDay(prefs);
    final items = prefs.getStringList(_keyItems) ?? [];
    return items.map((e) => Map<String, dynamic>.from(jsonDecode(e))).toList();
  }

  static Future<Map<String, int>> getTodayCounts() async {
    final entries = await getTodayEntries();
    final delivered = entries.where((e) => e['status'] == 'delivered').length;
    final notDelivered = entries.where((e) => e['status'] == 'not_delivered').length;
    return {'delivered': delivered, 'not_delivered': notDelivered};
  }
}
