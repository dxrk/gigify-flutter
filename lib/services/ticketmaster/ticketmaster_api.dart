import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:georange/georange.dart';

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
    Map<String, dynamic>? location,
    int radius = 50,
    int size = 10,
  }) async {
    try {
      if (artistName == 'Unknown' || location == null) {
        return [];
      }

      final queryParams = {
        'keyword': artistName,
        'apikey': apiKey,
        'radius': radius.toString(),
        'unit': 'miles',
      };

      if (location['latitude'] != null && location['longitude'] != null) {
        GeoRange georange = GeoRange();

        var encoded = georange.encode(
          location['latitude'] as double,
          location['longitude'] as double,
        );

        queryParams['geoPoint'] = encoded;
      }

      final uri = Uri.parse(
        '$baseUrl/events.json',
      ).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['_embedded'] != null && data['_embedded']['events'] != null) {
          final events = List<Map<String, dynamic>>.from(
            data['_embedded']['events'],
          );

          for (var event in events) {
            if (event.containsKey('images')) {
              final images = event['images'] as List<dynamic>;
              if (images.isNotEmpty) {
                images.sort(
                  (a, b) => (b['width'] as int).compareTo(a['width'] as int),
                );
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
    Map<String, dynamic>? location,
    int radius = 50,
  }) async {
    final rawEvents = await searchEvents(
      artistName: artistName,
      location: location,
      radius: radius,
    );

    return rawEvents.map((e) => Concert.fromJson(e)).toList();
  }
}
