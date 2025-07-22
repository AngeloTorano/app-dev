import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_connection/api_connection.dart';

class ActivityLogger {
  static Future<void> log({
    required int? userId,
    required String actionType,
    required String description,
    String status = 'Success',
  }) async {
    try {
      final body = {
        'UserID': userId?.toString() ?? '',  // Send empty string if null
        'ActionType': actionType,
        'Description': description,
        'Status': status,
      };

      final response = await http.post(
        Uri.parse(ApiConnection.insertActivityLog),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: body,
      );

      print('📡 Activity Log Request:');
      print('URL: ${ApiConnection.insertActivityLog}');
      print('Payload: $body');
      print('🔁 Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is Map && data['success'] == true) {
            print('✅ Activity logged: $actionType ($status)');
          } else {
            print('⚠️ Logging failed: ${data['message'] ?? 'Unknown error'}');
          }
        } catch (e) {
          print('❌ JSON decode error: ${response.body}');
        }
      } else {
        print('❌ Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Exception during activity logging: $e');
    }
  }
}
