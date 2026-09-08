import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AiOcrService {
  /// Scans an image and returns extracted JSON data.
  /// [isOdometer] defines if we are looking for odometer reading or receipt data.
  Future<Map<String, dynamic>?> scanImage(File imageFile, bool isOdometer) async {
    final String apiKey = dotenv.maybeGet('GEMINI_API_KEY') ?? '';
    
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('API Key not configured in .env file');
    }

    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final prompt = isOdometer
          ? 'Extract the current total odometer reading (total kilometers) from this dashboard image. Return ONLY a JSON object: {"odometer_km": value, "confidence": "high"|"low"}.'
          : 'Extract the fuel quantity in liters and the price per liter from this fuel receipt. Return ONLY a JSON object: {"fuel_liters": value, "price_per_liter": value, "confidence": "high"|"low"}.';

      final url = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ],
        "generationConfig": {
          "response_mime_type": "application/json",
        }
      });

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final textResponse = data['candidates'][0]['content']['parts'][0]['text'];
        return jsonDecode(textResponse);
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in AI OCR: $e');
    }
    return null;
  }
}
