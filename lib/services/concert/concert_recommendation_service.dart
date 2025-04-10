// TODO: Fix images not loading once cached
// TODO: "Recommended" stops displaying after you click on the other tabs
// TODO: Location services (including on TicketMaster's end) aren't fully functional
//       - Figure out why TicketMaster isn't taking the location data
//       - Pull location when doing the query in the al
// TODO: Need to remove unnecessary code
// TODO: Fine tune the algorithm
// TODO: Update the stats on the profile page – allow users to "follow artists" and "add concerts"

import 'package:nextbigthing/services/spotify/spotify_api.dart';
import 'package:nextbigthing/services/ticketmaster/ticketmaster_api.dart';
import 'package:nextbigthing/services/cache/cache_service.dart';
import 'package:nextbigthing/models/artist.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:nextbigthing/models/genre.dart';
import 'package:nextbigthing/utils/date_utils.dart';

class ConcertRecommendationService {
  final SpotifyApi _spotifyApi;
  final TicketmasterAPI _ticketmasterApi;
  final CacheService _cacheService;

  static const int _cacheDurationHours = 24;
  static const int _maxConcurrencyLimit = 5;
  static const double _priceSensitivityDefault = 0.5;
  static const int _defaultSearchLookAheadDays = 180;

  ConcertRecommendationService._({
    required SpotifyApi spotifyApi,
    required TicketmasterAPI ticketmasterApi,
    required CacheService cacheService,
  })  : _spotifyApi = spotifyApi,
        _ticketmasterApi = ticketmasterApi,
        _cacheService = cacheService;

  static ConcertRecommendationService? _instance;

  static Future<ConcertRecommendationService> initialize() async {
    _instance ??= ConcertRecommendationService._(
      spotifyApi: SpotifyApi(),
      ticketmasterApi: await TicketmasterAPI.initialize(),
      cacheService: await CacheService.initialize(),
    );
    return _instance!;
  }

  Future<Map<String, List<Concert>>> getConcertRecommendations({
    required String accessToken,
    required Map<String, String> location,
    int radius = 50,
    int searchPeriod = _defaultSearchLookAheadDays,
    int limit = 20,
    double priceSensitivity = _priceSensitivityDefault,
    bool includeSimilarArtists = false,
    List<String> excludeGenres = const [],
    List<String> preferredVenues = const [],
  }) async {
    try {
      print(
          'Starting concert recommendation process for location: ${location['city']}');

      final String cacheKey = _generateCacheKey(
        accessToken: accessToken,
        location: location,
        radius: radius,
        searchPeriod: searchPeriod,
      );

      final rawCache = await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (rawCache != null) {
        print('Returning cached concert recommendations');
        final parsed =
            rawCache.map<String, List<Concert>>((category, concerts) {
          final concertList = (concerts as List)
              .map((c) => Concert.fromJson(c as Map<String, dynamic>))
              .toList();
          return MapEntry(category, concertList);
        });
        return parsed;
      }

      final results = await Future.wait([
        SpotifyApi.getTopArtists(accessToken, limit: 50),
        SpotifyApi.getFollowedArtists(accessToken, limit: 50),
        SpotifyApi.getRecentlyPlayed(accessToken, limit: 50),
        SpotifyApi.getUserPreferences(accessToken),
      ]);

      final topArtists = results[0] as List<Artist>;
      final followedArtists = results[1] as List<Artist>;
      final recentlyPlayed = results[2] as List<Map<String, dynamic>>;
      final userPreferences = results[3] as Map<String, dynamic>;

      final Map<String, double> genreWeights = _extractGenreWeights(
        topArtists: topArtists,
        followedArtists: followedArtists,
        recentlyPlayed: recentlyPlayed,
        userPreferences: userPreferences,
      );

      for (final genre in excludeGenres) {
        genreWeights.remove(genre);
      }

      final Map<String, double> artistScores = {};

      for (var artist in topArtists) {
        artistScores[artist.id] = _calculateArtistScore(
          artist: artist,
          position: topArtists.indexOf(artist),
          listSize: topArtists.length,
          baseWeight: 10.0,
          playCount: 1,
        );
      }

      for (var artist in followedArtists) {
        final existingScore = artistScores[artist.id] ?? 0.0;
        artistScores[artist.id] = existingScore +
            _calculateArtistScore(
              artist: artist,
              position: followedArtists.indexOf(artist),
              listSize: followedArtists.length,
              baseWeight: 7.0,
              playCount: 1,
            );
      }

      for (var item in recentlyPlayed) {
        final artist = Artist.fromJson(item['track']['artists'][0]);
        final existingScore = artistScores[artist.id] ?? 0.0;
        artistScores[artist.id] = existingScore +
            _calculateArtistScore(
              artist: artist,
              position: recentlyPlayed.indexOf(item),
              listSize: recentlyPlayed.length,
              baseWeight: 5.0,
              playCount: item['play_count'] ?? 1,
            );
      }

      final Map<String, List<Artist>> artistBuckets = _categorizeArtists(
        artistScores: artistScores,
        topArtists: topArtists,
        followedArtists: followedArtists,
      );

      final Map<String, List<Concert>> concertResults = {
        'mustSee': [],
        'recommended': [],
        'discovery': [],
      };

      final endDate = DateTime.now().add(Duration(days: searchPeriod));

      for (final entry in artistBuckets.entries) {
        final String category = entry.key;
        final List<Artist> artists = entry.value;

        print(
            'Fetching concerts for $category category (${artists.length} artists)');

        for (int i = 0; i < artists.length; i += _maxConcurrencyLimit) {
          final batch = artists.skip(i).take(_maxConcurrencyLimit);

          final concertFutures = batch.map((artist) async {
            try {
              final results = await _ticketmasterApi.getArtistEvents(
                artistName: artist.name,
                city: location['city'],
                radius: radius,
              );

              return results;
            } catch (e) {
              print('Failed to get concerts for ${artist.name}: $e');
              return <Concert>[];
            }
          });

          final results = await Future.wait(concertFutures);

          for (final concerts in results) {
            if (category == 'mustSee') {
              concertResults['mustSee']!.addAll(concerts);
            } else if (category == 'recommended') {
              concertResults['recommended']!.addAll(concerts);
            } else if (category == 'discovery') {
              concertResults['discovery']!.addAll(concerts);
            }
          }
        }
      }

      final processedResults = await _processResults(
        concertResults: concertResults,
        priceSensitivity: priceSensitivity,
        preferredVenues: preferredVenues,
        genreWeights: genreWeights,
        limit: limit,
      );

      await _cacheService.set(
        cacheKey,
        processedResults.map((key, value) =>
            MapEntry(key, value.map((c) => c.toJson()).toList())),
        Duration(hours: _cacheDurationHours),
      );

      print('Concert recommendation process completed successfully');
      return processedResults;
    } catch (e) {
      print('Error getting concert recommendations: $e');
      throw Exception('Failed to get concert recommendations: $e');
    }
  }

  Map<String, List<Artist>> _categorizeArtists({
    required Map<String, double> artistScores,
    required List<Artist> topArtists,
    required List<Artist> followedArtists,
  }) {
    final Map<String, List<Artist>> buckets = {
      'mustSee': [],
      'recommended': [],
      'discovery': [],
    };

    final mustSeeArtists = artistScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recommendedEntries = artistScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recommendedArtists = recommendedEntries.skip(5).take(15).map((e) {
      return topArtists.firstWhere(
        (a) => a.id == e.key,
        orElse: () => followedArtists.firstWhere(
          (a) => a.id == e.key,
          orElse: () =>
              Artist(id: e.key, name: 'Unknown', popularity: 0, genres: []),
        ),
      );
    }).toList();

    final sortedEntries = artistScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final discoveryArtists = sortedEntries.skip(20).map((entry) {
      return topArtists.firstWhere(
        (a) => a.id == entry.key,
        orElse: () => followedArtists.firstWhere(
          (a) => a.id == entry.key,
          orElse: () => Artist(
            id: entry.key,
            name: 'Unknown',
            popularity: 0,
            genres: [],
          ),
        ),
      );
    }).toList();

    buckets['mustSee'] = mustSeeArtists.map((e) {
      return topArtists.firstWhere(
        (a) => a.id == e.key,
        orElse: () => followedArtists.firstWhere(
          (a) => a.id == e.key,
          orElse: () =>
              Artist(id: e.key, name: 'Unknown', popularity: 0, genres: []),
        ),
      );
    }).toList();

    buckets['recommended'] = recommendedArtists;
    buckets['discovery'] = discoveryArtists;

    return buckets;
  }

  Future<Map<String, List<Concert>>> _processResults({
    required Map<String, List<Concert>> concertResults,
    required double priceSensitivity,
    required List<String> preferredVenues,
    required Map<String, double> genreWeights,
    required int limit,
  }) async {
    final now = DateTime.now();
    final Map<String, List<Concert>> processed = {};

    for (final category in concertResults.keys) {
      List<Concert> concerts = concertResults[category]!;

      concerts = concerts.where((c) => c.startDateTime.isAfter(now)).toList();

      concerts = _removeDuplicates(concerts);

      if (preferredVenues.isNotEmpty) {
        concerts = concerts.map((concert) {
          if (preferredVenues.contains(concert.venue.id)) {
            concert.score += 2.0;
          }
          return concert;
        }).toList();
      }

      if (priceSensitivity < 1.0) {
        concerts = _applyPriceSensitivity(concerts, priceSensitivity);
      }

      concerts = _applyGenreScoring(concerts, genreWeights);

      concerts.sort((a, b) => b.score.compareTo(a.score));

      processed[category] = concerts.take(limit).toList();
    }

    return processed;
  }

  List<Concert> _applyGenreScoring(
    List<Concert> concerts,
    Map<String, double> genreWeights,
  ) {
    return concerts.map((concert) {
      double genreScore = 0;

      for (final genre in concert.genres) {
        if (genreWeights.containsKey(genre)) {
          genreScore += genreWeights[genre]!;
        }
      }

      if (genreScore > 0) {
        final normalizedScore =
            (genreScore / genreWeights.values.reduce((a, b) => a > b ? a : b)) *
                3;
        concert.score += normalizedScore;
      }

      return concert;
    }).toList();
  }

  List<Concert> _applyPriceSensitivity(
      List<Concert> concerts, double sensitivity) {
    if (concerts.isEmpty) return concerts;

    final prices = concerts
        .where((c) => c.minPrice != null && c.minPrice! > 0)
        .map((c) => c.minPrice!)
        .toList();

    if (prices.isEmpty) return concerts;

    prices.sort();
    final minPrice = prices.first;
    final maxPrice = prices.last;
    final priceRange = maxPrice - minPrice;

    if (priceRange <= 0) return concerts;

    final threshold = minPrice + (priceRange * sensitivity);

    return concerts.map((concert) {
      if (concert.minPrice != null && concert.minPrice! > 0) {
        final priceScore =
            5 * (1 - ((concert.minPrice! - minPrice) / priceRange));
        concert.score += priceScore;

        if (sensitivity < 0.3 && concert.minPrice! > threshold) {
          concert.score -= 5;
        }
      }
      return concert;
    }).toList();
  }

  List<Concert> _removeDuplicates(List<Concert> concerts) {
    final Map<String, Concert> uniqueConcerts = {};

    for (final concert in concerts) {
      final key =
          '${concert.artist.id}_${concert.venue.id}_${DateUtils.formatDate(concert.startDateTime, 'yyyy-MM-dd')}';

      if (!uniqueConcerts.containsKey(key) ||
          concert.score > uniqueConcerts[key]!.score) {
        uniqueConcerts[key] = concert;
      }
    }

    return uniqueConcerts.values.toList();
  }

  double _calculateArtistScore({
    required Artist artist,
    required int position,
    required int listSize,
    required double baseWeight,
    required int playCount,
  }) {
    final positionWeight = 1.0 - (position / listSize);

    final popularityWeight = artist.popularity / 100.0;

    final playCountWeight = playCount > 1 ? (playCount / 10) : 0.1;

    return baseWeight *
        positionWeight *
        (0.7 + (0.3 * popularityWeight)) *
        playCountWeight;
  }

  Map<String, double> _extractGenreWeights({
    required List<Artist> topArtists,
    required List<Artist> followedArtists,
    required List<Map<String, dynamic>> recentlyPlayed,
    required Map<String, dynamic> userPreferences,
  }) {
    final Map<String, double> genreWeights = {};

    for (var artist in topArtists) {
      for (var genre in artist.genres) {
        final existingWeight = genreWeights[genre] ?? 0.0;
        final position = topArtists.indexOf(artist);
        final positionWeight = 1.0 - (position / topArtists.length);
        genreWeights[genre] = existingWeight + (3.0 * positionWeight);
      }
    }

    for (var artist in followedArtists) {
      for (var genre in artist.genres) {
        final existingWeight = genreWeights[genre] ?? 0.0;
        genreWeights[genre] = existingWeight + 1.0;
      }
    }

    for (var item in recentlyPlayed) {
      try {
        final artist = Artist.fromJson(item['track']['artists'][0]);
        for (var genre in artist.genres) {
          final existingWeight = genreWeights[genre] ?? 0.0;
          genreWeights[genre] = existingWeight + 0.5;
        }
      } catch (e) {}
    }

    if (userPreferences.containsKey('genres')) {
      final preferredGenres = userPreferences['genres'] as List<dynamic>;
      for (var genre in preferredGenres) {
        final existingWeight = genreWeights[genre] ?? 0.0;
        genreWeights[genre] = existingWeight + 4.0;
      }
    }

    return genreWeights;
  }

  String _generateCacheKey({
    required String accessToken,
    required Map<String, String> location,
    required int radius,
    required int searchPeriod,
  }) {
    final locationString =
        location.entries.map((e) => '${e.key}:${e.value}').join('_');

    final tokenPrefix = accessToken.substring(0, 8);

    return 'concert_recommendations_${tokenPrefix}_${locationString}_${radius}_$searchPeriod';
  }
}
