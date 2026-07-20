import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class DeliveryService {
  static const _baseUrl = 'https://tracking.libyapost.ly:7040/api/govems';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {'Authorization': 'Bearer $token'};
  }

  static Future<Map<String, dynamic>> submitDelivery({
    required String itemId,
    required String officeCd,
    required String signatoryName,
    required File proofImage,
    String? signatureBase64,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/deliver.php'));
      request.headers.addAll(await _authHeaders());
      request.followRedirects = false; // ← don't follow 302 redirects

      request.fields['item_id'] = itemId.toUpperCase();
      request.fields['delivery_status'] = 'delivered';
      request.fields['signatory_name'] = signatoryName;
      request.fields['office_cd'] = officeCd;
      if (signatureBase64 != null) {
        request.fields['sign_image_data'] = signatureBase64;
      }
      request.files.add(await http.MultipartFile.fromPath('sign_image', proofImage.path));

      final response = await request.send().timeout(const Duration(seconds: 30));

      // 200 = JSON success from our app path
      // 302 = redirect means the web path ran but data was saved successfully
      if (response.statusCode == 200 || response.statusCode == 302) {
        return {'success': true};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'message': 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى', 'relogin': true};
      }
      return {'success': false, 'message': 'خطأ في الخادم: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'تعذّر الاتصال بالخادم'};
    }
  }

  static Future<Map<String, dynamic>> submitNonDelivery({
    required String itemId,
    required String officeCd,
    required String reason,
    required String measure,
    String? otherReason,
    File? failPhoto,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/deliver.php'));
      request.headers.addAll(await _authHeaders());
      request.followRedirects = false; // ← don't follow 302 redirects

      request.fields['item_id'] = itemId.toUpperCase();
      request.fields['delivery_status'] = 'not_delivered';
      request.fields['office_cd'] = officeCd;
      request.fields['non_delivery_reason'] = reason;
      request.fields['non_delivery_measure'] = measure;
      if (otherReason != null) request.fields['other_reason'] = otherReason;
      if (failPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath('fail_image', failPhoto.path));
      }

      final response = await request.send().timeout(const Duration(seconds: 30));

      // 200 = JSON success, 302 = web redirect but data saved OK
      if (response.statusCode == 200 || response.statusCode == 302) {
        return {'success': true};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'message': 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى', 'relogin': true};
      }
      return {'success': false, 'message': 'خطأ في الخادم: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'تعذّر الاتصال بالخادم'};
    }
  }

  static Future<List<Map<String, dynamic>>> getLastItems() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/deliver.php?ajax=last_items'),
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          ...await _authHeaders(),
        },
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (data['ok'] == true) {
        return List<Map<String, dynamic>>.from(data['items']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
