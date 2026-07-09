import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiNotificationClassifier {
  static const String _model = 'gemini-2.5-flash-lite';
  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1/models';

  /// Fallback-queries Gemini to parse incomplete/complex notifications.
  static Future<Map<String, dynamic>?> classifyNotification(String rawMessage) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    if (apiKey.isEmpty || apiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      debugPrint("[AI CLASSIFIER] Gemini API key not found in .env, skipping AI classification.");
      return null;
    }

    final prompt = "Analyze this payment notification and extract the following details. "
        "Respond STRICTLY with a valid JSON object containing exactly these keys: "
        "\"amount\" (number, the monetary value), "
        "\"merchant\" (string, name of receiver or sender), "
        "\"type\" (string, either \"debit\" or \"credit\"), "
        "\"category\" (string, choose only from: \"Food\", \"Shopping\", \"Bills\", \"Entertainment\", \"Transport\", \"Healthcare\", \"Education\", \"Travel\", \"Investment\", \"Others\").\n\n"
        "Notification text: \"$rawMessage\"\n\n"
        "Do not include any pre-text, post-text, markdown syntax formatting except the JSON. "
        "JSON Response:";

    final requestBody = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'maxOutputTokens': 150
      }
    };

    final requestUrl = Uri.parse('$_baseUrl/$_model:generateContent?key=$apiKey');

    try {
      if (kDebugMode) {
        debugPrint("[AI CLASSIFIER] Querying Gemini for notification parsing...");
      }

      final response = await http.post(
        requestUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint("[AI CLASSIFIER] Gemini API error: ${response.statusCode} - ${response.body}");
        return null;
      }

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = responseJson['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return null;

      final content = candidates[0]['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      if (parts == null || parts.isEmpty) return null;

      final text = parts[0]['text'] as String? ?? '';
      final cleanedJsonText = _extractJson(text);

      if (kDebugMode) {
        debugPrint("[AI CLASSIFIER] Gemini parsed output: $cleanedJsonText");
      }

      final result = jsonDecode(cleanedJsonText) as Map<String, dynamic>;
      return {
        'amount': (result['amount'] as num?)?.toDouble() ?? 0.0,
        'merchant': result['merchant'] as String? ?? 'Unknown Merchant',
        'type': result['type'] as String? ?? 'debit',
        'category': result['category'] as String? ?? 'Others',
      };
    } catch (e) {
      debugPrint("[AI CLASSIFIER] Failed parsing notification via Gemini: $e");
      return null;
    }
  }

  static String _extractJson(String text) {
    String cleaned = text.trim();
    if (cleaned.contains('```json')) {
      final startIndex = cleaned.indexOf('```json') + 7;
      final endIndex = cleaned.lastIndexOf('```');
      if (endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex).trim();
      }
    } else if (cleaned.contains('```')) {
      final startIndex = cleaned.indexOf('```') + 3;
      final endIndex = cleaned.lastIndexOf('```');
      if (endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex).trim();
      }
    }
    return cleaned;
  }
}
