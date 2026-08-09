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
      request.followRedirects = false;

      request.fields['item_id'] = itemId.toUpperCase();
      request.fields['delivery_status'] = 'delivered';
      request.fields['signatory_name'] = signatoryName.isEmpty ? '.' : signatoryName;
      request.fields['office_cd'] = officeCd;
      if (signatureBase64 != null) {
        request.fields['sign_image_data'] = signatureBase64;
      }
      request.files.add(await http.MultipartFile.fromPath(
        'sign_image',
        proofImage.path,
        filename: 'proof.jpg',
      ));

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();

      // 302 = web redirect = data saved successfully via web flow
      if (streamed.statusCode == 302) return {'success': true};

      // Try to parse JSON response
      if (body.isNotEmpty) {
        try {
          final data = jsonDecode(body);
          if (data['success'] == true) return {'success': true};
          return {'success': false, 'message': data['message'] ?? 'خطأ في الخادم'};
        } catch (_) {}
      }

      if (streamed.statusCode == 200) return {'success': true};
      if (streamed.statusCode == 401) return {'success': false, 'message': 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى', 'relogin': 'true'};
      return {'success': false, 'message': 'خطأ في الخادم: ${streamed.statusCode}\n$body'};
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
      request.followRedirects = false;

      request.fields['item_id'] = itemId.toUpperCase();
      request.fields['delivery_status'] = 'not_delivered';
      request.fields['office_cd'] = officeCd;
      request.fields['non_delivery_reason'] = reason;
      request.fields['non_delivery_measure'] = measure;
      request.fields['signatory_name'] = '.';
      if (otherReason != null) request.fields['other_reason'] = otherReason;
      if (failPhoto != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'fail_image',
          failPhoto.path,
          filename: 'fail.jpg',
        ));
      }

      final streamed = await request.send().timeout(const Duration(seconds: 30));
      final body = await streamed.stream.bytesToString();

      if (streamed.statusCode == 302) return {'success': true};

      if (body.isNotEmpty) {
        try {
          final data = jsonDecode(body);
          if (data['success'] == true) return {'success': true};
          return {'success': false, 'message': data['message'] ?? 'خطأ في الخادم'};
        } catch (_) {}
      }

      if (streamed.statusCode == 200) return {'success': true};
      if (streamed.statusCode == 401) return {'success': false, 'message': 'انتهت الجلسة، يرجى تسجيل الدخول مرة أخرى', 'relogin': 'true'};
      return {'success': false, 'message': 'خطأ في الخادم: ${streamed.statusCode}\n$body'};
    } catch (e) {
      return {'success': false, 'message': 'تعذّر الاتصال بالخادم'};
    }
  }

  static Future<List<Map<String, dynamic>>> getLastItems() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/deliver.php?ajax=last_items'),
        headers: {'X-Requested-With': 'XMLHttpRequest', ...await _authHeaders()},
      ).timeout(const Duration(seconds: 15));
      final data = jsonDecode(response.body);
      if (data['ok'] == true) return List<Map<String, dynamic>>.from(data['items']);
      return [];
    } catch (e) {
      return [];
    }
  }
}
