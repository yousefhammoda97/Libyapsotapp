import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _baseUrl = 'https://tracking.libyapost.ly:7040/api/govems';
  static const _keyToken = 'api_token';
  static const _keyUserId = 'user_id';
  static const _keyUsername = 'username';
  static const _keyRole = 'role';
  static const _keyOffice = 'office_cd';
  static const _keyRemember = 'remember_me';
  static const _keySavedUser = 'saved_username';
  static const _keySavedPass = 'saved_password';

  static Future<Map<String, dynamic>> login(String username, String password, {bool rememberMe = false}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api_login.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, data['token']);
        await prefs.setString(_keyUserId, data['user_id'].toString());
        await prefs.setString(_keyUsername, data['username'] ?? username);
        await prefs.setString(_keyRole, data['role'] ?? 'delivery');
        await prefs.setString(_keyOffice, data['post_office_code'] ?? '');

        await prefs.setBool(_keyRemember, rememberMe);
        if (rememberMe) {
          await prefs.setString(_keySavedUser, username);
          await prefs.setString(_keySavedPass, password);
        } else {
          await prefs.remove(_keySavedUser);
          await prefs.remove(_keySavedPass);
        }
        return {'success': true};
      }
      return {'success': false, 'message': data['message'] ?? 'فشل تسجيل الدخول'};
    } catch (e) {
      return {'success': false, 'message': 'تعذّر الاتصال بالخادم'};
    }
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken) != null;
  }

  static Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRemember) ?? false;
    if (!remember) return null;
    final user = prefs.getString(_keySavedUser);
    final pass = prefs.getString(_keySavedPass);
    if (user == null || pass == null) return null;
    return {'username': user, 'password': pass};
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? '';
  }

  static Future<String> getOffice() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyOffice) ?? '';
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool(_keyRemember) ?? false;
    final savedUser = prefs.getString(_keySavedUser);
    final savedPass = prefs.getString(_keySavedPass);

    await prefs.clear();

    // Preserve remembered credentials across logout if "remember me" was checked
    if (remember && savedUser != null && savedPass != null) {
      await prefs.setBool(_keyRemember, true);
      await prefs.setString(_keySavedUser, savedUser);
      await prefs.setString(_keySavedPass, savedPass);
    }
  }
}
