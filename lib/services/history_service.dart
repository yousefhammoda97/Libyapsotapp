import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class HistoryService {
  static const _baseUrl = 'https://tracking.libyapost.ly:7040/api/govems';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {'Authorization': 'Bearer $token'};
  }

  static Future<List<Map<String, dynamic>>> getTodayHistory() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api_history.php?action=today'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> checkDuplicate(String itemId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api_history.php?action=check&item_id=${Uri.encodeComponent(itemId)}'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      return {
        'already_exists': data['already_exists'] ?? false,
        'status': data['status'] ?? '',
        'message': data['message'] ?? '',
      };
    } catch (e) {
      return {'already_exists': false, 'status': '', 'message': ''};
    }
  }

  static Future<Map<String, dynamic>> getMonthlyStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api_monthly_stats.php'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 10));
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {
          'express_count':    data['express_count'] ?? 0,
          'registered_count': data['registered_count'] ?? 0,
          'other_count':      data['other_count'] ?? 0,
          'total':            data['total'] ?? 0,
          'year_month':       data['year_month'] ?? '',
        };
      }
      return {'express_count': 0, 'registered_count': 0, 'other_count': 0, 'total': 0, 'year_month': ''};
    } catch (e) {
      return {'express_count': 0, 'registered_count': 0, 'other_count': 0, 'total': 0, 'year_month': ''};
    }
  }
}
