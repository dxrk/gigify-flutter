import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nextbigthing/models/concert.dart';

class TicketmasterAPI {
  static const String baseUrl = 'https://app.ticketmaster.com/discovery/v2';
  final String apiKey;

  TicketmasterAPI({required this.apiKey});

  static TicketmasterAPI? _instance;

  static Future<TicketmasterAPI> initialize() async {
    if (_instance == null) {
      final apiKey = dotenv.env['TICKETMASTER_API_KEY'];
      if (apiKey == null) {
        throw Exception('Ticketmaster API key not found in .env file');
      }
      _instance = TicketmasterAPI(apiKey: apiKey);
    }
    return _instance!;
  }

  Future<List<Map<String, dynamic>>> searchEvents({
    required String artistName,
    String? city,
    int radius = 50,
    int size = 10,
  }) async {
    try {
      final queryParams = {
        'keyword': artistName,
        'apikey': apiKey,
      };

      // if (city != null) {
      //   queryParams['city'] = city;
      //   queryParams['radius'] = radius.toString();
      //   queryParams['unit'] = 'miles';
      // }

      final uri = Uri.parse('$baseUrl/events.json')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['_embedded'] != null && data['_embedded']['events'] != null) {
          final events =
              List<Map<String, dynamic>>.from(data['_embedded']['events']);

          // Process images to ensure we have the best quality
          for (var event in events) {
            if (event.containsKey('images')) {
              final images = event['images'] as List<dynamic>;
              if (images.isNotEmpty) {
                // Sort images by width to get the highest quality
                images.sort(
                    (a, b) => (b['width'] as int).compareTo(a['width'] as int));
                // Use the first (highest quality) image
                event['imageUrl'] = images[0]['url'];
              }
            }
          }

          return events;
        }
      }
      return [];
    } catch (e) {
      print('Error searching events: $e');
      return [];
    }
  }

  Future<List<Concert>> getArtistEvents({
    required String artistName,
    String? city,
    int radius = 50,
  }) async {
    final rawEvents = await searchEvents(
      artistName: artistName,
      city: city,
      radius: radius,
    );

    return rawEvents.map((e) => Concert.fromJson(e)).toList();
  }
}
