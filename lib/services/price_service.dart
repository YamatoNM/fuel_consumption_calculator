import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

class PriceService {
  static const String _cacheKeyPrefix = 'cached_price_';
  static const String _cacheTimePrefix = 'cached_price_time_';

  /// Fetches the live fuel price from ANRE.
  /// [fuelType] should be "Motorină" or "Benzină".
  Future<double?> getLivePrice(String fuelType) async {
    final cachedPrice = await _getCachedPrice(fuelType);
    if (cachedPrice != null) return cachedPrice;

    try {
      final String url = fuelType == 'Motorină'
          ? 'https://anre.md/motorina-3-3'
          : 'https://anre.md/benzina-95-3-2';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final document = html_parser.parse(response.body);
        
        // ANRE prices are usually in a table. We look for the first table row after header.
        // This is a simplified scraper; structure might need adjustment if ANRE changes.
        final table = document.querySelector('table');
        if (table != null) {
          final rows = table.querySelectorAll('tr');
          if (rows.length > 1) {
            // Usually the first row after header contains the latest price.
            // We assume the price is in the last column.
            final cells = rows[1].querySelectorAll('td');
            if (cells.isNotEmpty) {
              final priceText = cells.last.text.trim();
              // Handle Moldovan format "33,23"
              final normalizedPrice = priceText.replaceAll(',', '.');
              final price = double.tryParse(normalizedPrice);
              
              if (price != null) {
                await _cachePrice(fuelType, price);
                return price;
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching price: $e');
    }

    return await _getCachedPrice(fuelType, ignoreExpiry: true);
  }

  Future<void> _cachePrice(String fuelType, double price) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_cacheKeyPrefix}$fuelType', price);
    await prefs.setInt('${_cacheTimePrefix}$fuelType', DateTime.now().millisecondsSinceEpoch);
  }

  Future<double?> _getCachedPrice(String fuelType, {bool ignoreExpiry = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final price = prefs.getDouble('${_cacheKeyPrefix}$fuelType');
    final time = prefs.getInt('${_cacheTimePrefix}$fuelType');

    if (price != null && time != null) {
      if (ignoreExpiry) return price;
      
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(time);
      if (DateTime.now().difference(cacheTime).inHours < 24) {
        return price;
      }
    }
    return null;
  }
}
