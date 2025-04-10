import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nextbigthing/models/artist.dart';
import 'package:nextbigthing/utils/api_exception.dart';

class SpotifyApi {
  static const String _baseUrl = 'https://api.spotify.com/v1';
  static const int _requestTimeout = 15;

  static Map<String, String> _createHeaders(String accessToken) {
    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  static T _handleResponse<T>(http.Response response, String endpoint,
      {T Function(Map<String, dynamic>)? fromJson}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (fromJson != null) {
        return fromJson(data);
      } else {
        return data as T;
      }
    } else {
      print('Spotify API error: ${response.statusCode} for $endpoint');

      if (response.statusCode == 401) {
        throw ApiException(
            'Spotify authentication failed. Token may have expired.');
      } else if (response.statusCode == 429) {
        final retryAfter =
            int.tryParse(response.headers['retry-after'] ?? '30') ?? 30;
        throw ApiException(
            'Spotify rate limit exceeded. Try again in $retryAfter seconds.');
      } else {
        Map<String, dynamic> errorBody = {};
        try {
          errorBody = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (_) {}

        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        throw ApiException(
            'Spotify API error (${response.statusCode}): $errorMessage');
      }
    }
  }

  static Future<Map<String, dynamic>> getUserProfile(String accessToken) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/me'),
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<Map<String, dynamic>>(response, '/me');
    } catch (e) {
      print('Error getting user profile');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getUserPreferences(
      String accessToken) async {
    try {
      final profile = await getUserProfile(accessToken);

      final Map<String, dynamic> preferences = {};

      if (profile.containsKey('explicit_content')) {
        preferences['explicit_content_allowed'] =
            !profile['explicit_content']['filter_enabled'];
      }

      if (profile.containsKey('country')) {
        preferences['country'] = profile['country'];
      }

      if (profile.containsKey('product')) {
        preferences['product'] = profile['product'];
      }

      return preferences;
    } catch (e) {
      print('Error getting user preferences');
      return {};
    }
  }

  static Future<List<Artist>> getTopArtists(
    String accessToken, {
    int limit = 50,
    String timeRange = 'medium_term',
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/me/top/artists?limit=$limit&time_range=$timeRange'),
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<List<Artist>>(
        response,
        '/me/top/artists',
        fromJson: (data) {
          final items = data['items'] as List<dynamic>;
          return items
              .map((item) => Artist.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      print('Error getting top artists');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load top artists: $e');
    }
  }

  static Future<List<Artist>> getFollowedArtists(
    String accessToken, {
    int limit = 50,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/me/following?type=artist&limit=$limit'),
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<List<Artist>>(
        response,
        '/me/following',
        fromJson: (data) {
          final items = data['artists']['items'] as List<dynamic>;
          return items
              .map((item) => Artist.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      print('Error getting followed artists');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getRecentlyPlayed(
    String accessToken, {
    int limit = 50,
    String? after,
    String? before,
  }) async {
    try {
      String query = 'limit=$limit';
      if (after != null) query += '&after=$after';
      if (before != null) query += '&before=$before';

      final response = await http
          .get(
            Uri.parse('$_baseUrl/me/player/recently-played?$query'),
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<List<Map<String, dynamic>>>(
        response,
        '/me/player/recently-played',
        fromJson: (data) {
          final items = data['items'] as List<dynamic>;

          final Map<String, int> trackCounts = {};
          final List<Map<String, dynamic>> processedItems = [];

          for (final item in items) {
            final trackId = item['track']['id'] as String;
            trackCounts[trackId] = (trackCounts[trackId] ?? 0) + 1;

            final processedItem =
                Map<String, dynamic>.from(item as Map<String, dynamic>);
            processedItem['play_count'] = trackCounts[trackId];
            processedItems.add(processedItem);
          }

          return processedItems;
        },
      );
    } catch (e) {
      print('Error getting recently played tracks');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load recently played tracks: $e');
    }
  }

  static Future<List<Artist>> getSimilarArtists(
    String accessToken,
    String artistId, {
    int limit = 20,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/artists/$artistId/related-artists'),
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<List<Artist>>(
        response,
        '/artists/$artistId/related-artists',
        fromJson: (data) {
          final items = data['artists'] as List<dynamic>;
          return items
              .map((item) => Artist.fromJson(item as Map<String, dynamic>))
              .take(limit)
              .toList();
        },
      );
    } catch (e) {
      print('Error getting similar artists for $artistId');
      return [];
    }
  }

  static Future<Artist> getArtist(String accessToken, String artistId) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/artists/$artistId'),
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<Artist>(
        response,
        '/artists/$artistId',
        fromJson: (data) => Artist.fromJson(data),
      );
    } catch (e) {
      print('Error getting artist details for $artistId');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load artist details: $e');
    }
  }

  static Future<List<Artist>> searchArtists(
    String accessToken,
    String query, {
    int limit = 20,
  }) async {
    try {
      final encodedQuery = Uri.encodeComponent(query);
      final response = await http
          .get(
            Uri.parse(
                '$_baseUrl/search?q=$encodedQuery&type=artist&limit=$limit'),
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<List<Artist>>(
        response,
        '/search',
        fromJson: (data) {
          final items = data['artists']['items'] as List<dynamic>;
          return items
              .map((item) => Artist.fromJson(item as Map<String, dynamic>))
              .toList();
        },
      );
    } catch (e) {
      print('Error searching for artists: $query');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to search artists: $e');
    }
  }

  static Future<List<String>> getAvailableGenres(String accessToken) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/recommendations/available-genre-seeds'),
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<List<String>>(
        response,
        '/recommendations/available-genre-seeds',
        fromJson: (data) {
          final genres = data['genres'] as List<dynamic>;
          return genres.map((genre) => genre as String).toList();
        },
      );
    } catch (e) {
      print('Error getting available genres');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load available genres: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getArtistTopTracks(
    String accessToken,
    String artistId,
    String market,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/artists/$artistId/top-tracks?market=$market'),
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<List<Map<String, dynamic>>>(
        response,
        '/artists/$artistId/top-tracks',
        fromJson: (data) {
          final tracks = data['tracks'] as List<dynamic>;
          return tracks.map((track) => track as Map<String, dynamic>).toList();
        },
      );
    } catch (e) {
      print('Error getting top tracks for artist $artistId');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load artist top tracks: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getRecommendations(
    String accessToken, {
    List<String> seedArtists = const [],
    List<String> seedGenres = const [],
    List<String> seedTracks = const [],
    int limit = 20,
    Map<String, dynamic> tuneableTrackAttributes = const {},
  }) async {
    try {
      if (seedArtists.isEmpty && seedGenres.isEmpty && seedTracks.isEmpty) {
        throw ApiException(
            'At least one seed (artist, genre, or track) is required');
      }

      if (seedArtists.length + seedGenres.length + seedTracks.length > 5) {
        throw ApiException('Maximum of 5 seeds allowed in total');
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (seedArtists.isNotEmpty) {
        queryParams['seed_artists'] = seedArtists.join(',');
      }

      if (seedGenres.isNotEmpty) {
        queryParams['seed_genres'] = seedGenres.join(',');
      }

      if (seedTracks.isNotEmpty) {
        queryParams['seed_tracks'] = seedTracks.join(',');
      }

      tuneableTrackAttributes.forEach((key, value) {
        queryParams[key] = value.toString();
      });

      final uri =
          Uri.https('api.spotify.com', '/v1/recommendations', queryParams);

      final response = await http
          .get(
            uri,
            headers: _createHeaders(accessToken),
          )
          .timeout(Duration(seconds: _requestTimeout));

      return _handleResponse<List<Map<String, dynamic>>>(
        response,
        '/recommendations',
        fromJson: (data) {
          final tracks = data['tracks'] as List<dynamic>;
          return tracks.map((track) => track as Map<String, dynamic>).toList();
        },
      );
    } catch (e) {
      print('Error getting recommendations');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to load recommendations: $e');
    }
  }
}
