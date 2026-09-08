import 'dart:io';
import 'package:http/http.dart' as http;

/// Script de verificare rapidă (Smoke Check)
/// Se rulează manual cu: dart test/smoke_check.dart
void main() async {
  print('--- ÎNCEPERE VERIFICARE DISPONIBILITATE ---');

  // 1. Verificare .env
  print('\n[1/3] Verificare fișier .env...');
  final envFile = File('.env');
  if (envFile.existsSync()) {
    final content = await envFile.readAsString();
    if (content.contains('GEMINI_API_KEY') && !content.contains('YOUR_API_KEY_HERE')) {
      print('✅ Fișierul .env este configurat corect.');
    } else {
      print('❌ Fișierul .env există, dar cheia GEMINI_API_KEY pare să fie invalidă sau placeholder.');
    }
  } else {
    print('❌ Fișierul .env lipsește din rădăcina proiectului.');
  }

  // 2. Verificare Conexiune ANRE
  print('\n[2/3] Verificare conexiune site ANRE (Scraper)...');
  try {
    final response = await http.get(Uri.parse('https://anre.md/motorina-3-3')).timeout(Duration(seconds: 10));
    if (response.statusCode == 200) {
      print('✅ Site-ul ANRE este accesibil.');
      if (response.body.contains('<table')) {
        print('✅ Structura paginii ANRE conține tabele (Scraper-ul ar trebui să funcționeze).');
      } else {
        print('⚠️ Site-ul ANRE a răspuns, dar nu a fost găsit niciun tabel. Posibilă schimbare de design.');
      }
    } else {
      print('❌ Site-ul ANRE a returnat codul: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Eroare de rețea la accesarea ANRE: $e');
  }

  // 3. Verificare Google Gemini API
  print('\n[3/3] Verificare disponibilitate Google Gemini API...');
  try {
    final response = await http.get(Uri.parse('https://generativelanguage.googleapis.com/v1beta/models')).timeout(Duration(seconds: 10));
    // 403/401 e OK (înseamnă că serverul e viu, dar vrea cheie)
    if (response.statusCode == 200 || response.statusCode == 403 || response.statusCode == 401) {
      print('✅ Endpoint-ul Google Gemini este online.');
    } else {
      print('❌ Endpoint-ul Gemini a răspuns neașteptat: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Nu se poate contacta Gemini API (verifică internetul): $e');
  }

  print('\n--- VERIFICARE FINALIZATĂ ---');
}
