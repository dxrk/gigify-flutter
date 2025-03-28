import 'dart:convert';

import 'package:http/http.dart' as http;

class SpotifyApi {
  static Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile: ${response.body}');
    }
  }

  static Future<List<dynamic>> getTopArtists(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/top/artists?limit=5'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['items'];
    } else {
      throw Exception('Failed to load top artists: ${response.body}');
    }
  }

  static Future<List<dynamic>> getFollowedArtists(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/following/artists?limit=5'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['items'];
    } else {
      throw Exception('Failed to load top artists: ${response.body}');
    }
  }

  static Future<List<dynamic>> getRecentlyPlayed(String accessToken) async {
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/player/recently-played?limit=2'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['items'];
    } else {
      throw Exception('Failed to load recently played: ${response.body}');
    }
  }
}
