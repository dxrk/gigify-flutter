import 'package:nextbigthing/services/spotify/spotify_api.dart';
import 'package:nextbigthing/services/ticketmaster/ticketmaster_api.dart';
import 'package:nextbigthing/services/cache/cache_service.dart';
import 'package:nextbigthing/models/artist.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:nextbigthing/utils/date_utils.dart';

class ConcertRecommendationService {
  final TicketmasterAPI _ticketmasterApi;
  final CacheService _cacheService;

  static const int _cacheDurationHours = 24;
  static const int _maxConcurrencyLimit = 5;
  static const int _defaultSearchLookAheadDays = 180;

  ConcertRecommendationService._({
    required TicketmasterAPI ticketmasterApi,
    required CacheService cacheService,
  })  : _ticketmasterApi = ticketmasterApi,
        _cacheService = cacheService;

  static ConcertRecommendationService? _instance;

  static Future<ConcertRecommendationService> initialize() async {
    _instance ??= ConcertRecommendationService._(
      ticketmasterApi: await TicketmasterAPI.initialize(),
      cacheService: await CacheService.initialize(),
    );
    return _instance!;
  }

  Future<Map<String, List<Concert>>> getConcertRecommendations({
    required String accessToken,
    required Map<String, dynamic> location,
    int radius = 50,
    int searchPeriod = _defaultSearchLookAheadDays,
    int limit = 20,
    bool includeSimilarArtists = false,
    List<String> excludeGenres = const [],
  }) async {
    try {
      print(
          'Starting concert recommendation process for location: ${location['details']}');

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
        SpotifyAPI.getTopArtists(accessToken, limit: 50),
        SpotifyAPI.getFollowedArtists(accessToken, limit: 50),
        SpotifyAPI.getRecentlyPlayed(accessToken, limit: 50),
        SpotifyAPI.getUserPreferences(accessToken),
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
        final playCount = item['play_count'] ?? 1;
        final position = recentlyPlayed.indexOf(item);

        final recencyWeight = 1.0 - (position / recentlyPlayed.length);
        artistScores[artist.id] = existingScore +
            _calculateArtistScore(
                  artist: artist,
                  position: position,
                  listSize: recentlyPlayed.length,
                  baseWeight: 8.0,
                  playCount: playCount,
                ) *
                (1.0 + recencyWeight);
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
                location: location,
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
        genreWeights: genreWeights,
        limit: limit,
      );

      final cacheData = processedResults.map((key, value) {
        final concerts = value.map((concert) {
          final json = concert.toJson();
          if (concert.venue != 'Unknown Venue') {
            json['venue'] = concert.venue;
          }
          if (concert.ticketUrl != null) {
            json['url'] = concert.ticketUrl;
          }
          return json;
        }).toList();
        return MapEntry(key, concerts);
      });

      await _cacheService.set(
        cacheKey,
        cacheData,
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

    final sortedEntries = artistScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    buckets['mustSee'] = sortedEntries.take(5).map((e) {
      return topArtists.firstWhere(
        (a) => a.id == e.key,
        orElse: () => followedArtists.firstWhere(
          (a) => a.id == e.key,
          orElse: () =>
              Artist(id: e.key, name: 'Unknown', popularity: 0, genres: []),
        ),
      );
    }).toList();

    buckets['recommended'] = sortedEntries.skip(5).take(15).map((e) {
      return topArtists.firstWhere(
        (a) => a.id == e.key,
        orElse: () => followedArtists.firstWhere(
          (a) => a.id == e.key,
          orElse: () =>
              Artist(id: e.key, name: 'Unknown', popularity: 0, genres: []),
        ),
      );
    }).toList();

    buckets['discovery'] = sortedEntries.skip(20).map((e) {
      return topArtists.firstWhere(
        (a) => a.id == e.key,
        orElse: () => followedArtists.firstWhere(
          (a) => a.id == e.key,
          orElse: () =>
              Artist(id: e.key, name: 'Unknown', popularity: 0, genres: []),
        ),
      );
    }).toList();

    return buckets;
  }

  Future<Map<String, List<Concert>>> _processResults({
    required Map<String, List<Concert>> concertResults,
    required Map<String, double> genreWeights,
    required int limit,
  }) async {
    final now = DateTime.now();
    final Map<String, List<Concert>> processed = {};

    for (final category in concertResults.keys) {
      List<Concert> concerts = concertResults[category]!;

      concerts = concerts.where((c) => c.startDateTime.isAfter(now)).toList();

      concerts = _removeDuplicates(concerts);

      concerts = _applyGenreScoring(concerts, genreWeights);

      concerts = _applyTimeBasedScoring(concerts);

      concerts.sort((a, b) => b.score.compareTo(a.score));

      processed[category] = concerts.take(limit).toList();
    }

    return processed;
  }

  List<Concert> _applyTimeBasedScoring(List<Concert> concerts) {
    final now = DateTime.now();
    return concerts.map((concert) {
      final daysUntilConcert = concert.startDateTime.difference(now).inDays;

      if (daysUntilConcert <= 30) {
        final timeScore = 1.0 - (daysUntilConcert / 30.0);
        concert.score += timeScore * 2.0;
      }

      return concert;
    }).toList();
  }

  List<Concert> _applyGenreScoring(
    List<Concert> concerts,
    Map<String, double> genreWeights,
  ) {
    return concerts.map((concert) {
      double genreScore = 0;
      int matchingGenres = 0;

      for (final genre in concert.genres) {
        if (genreWeights.containsKey(genre)) {
          genreScore += genreWeights[genre]!;
          matchingGenres++;
        }
      }

      if (matchingGenres > 0) {
        final normalizedScore = (genreScore / matchingGenres) * 3;
        concert.score += normalizedScore;
      }

      return concert;
    }).toList();
  }

  List<Concert> _removeDuplicates(List<Concert> concerts) {
    final Map<String, Concert> uniqueConcerts = {};

    for (final concert in concerts) {
      final key =
          '${concert.artist.id}_${concert.venue}_${DateUtils.formatDate(concert.startDateTime, 'yyyy-MM-dd')}';

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
    required Map<String, dynamic> location,
    required int radius,
    required int searchPeriod,
  }) {
    final locationString =
        '${location['details']}_${location['latitude']}_${location['longitude']}';
    final tokenPrefix = accessToken.substring(0, 8);
    return 'concert_recommendations_${tokenPrefix}_${locationString}_${radius}_$searchPeriod';
  }

  Future<Concert?> getFeaturedConcert({
    required String accessToken,
    required Map<String, dynamic> location,
    int radius = 50,
    int searchPeriod = _defaultSearchLookAheadDays,
  }) async {
    try {
      print('Finding featured concert for location: ${location['details']}');

      final String cacheKey = 'featured_concert_${_generateCacheKey(
        accessToken: accessToken,
        location: location,
        radius: radius,
        searchPeriod: searchPeriod,
      )}';

      final cachedConcert =
          await _cacheService.get<Map<String, dynamic>>(cacheKey);
      if (cachedConcert != null) {
        print('Returning cached featured concert');
        return Concert.fromJson(cachedConcert);
      }

      final results = await Future.wait([
        SpotifyAPI.getTopArtists(accessToken, limit: 50),
        SpotifyAPI.getUserPreferences(accessToken),
      ]);

      final topArtists = results[0] as List<Artist>;
      final userPreferences = results[1] as Map<String, dynamic>;

      final Set<String> userGenres = {};
      for (var artist in topArtists) {
        userGenres.addAll(artist.genres);
      }
      if (userPreferences.containsKey('genres')) {
        userGenres.addAll(
            (userPreferences['genres'] as List<dynamic>).cast<String>());
      }

      final events = await _ticketmasterApi.searchEvents(
        artistName: '',
        location: location,
        radius: radius,
      );

      if (events.isEmpty) {
        return null;
      }

      final now = DateTime.now();
      final concerts = events
          .map((e) => Concert.fromJson(e))
          .where((c) => c.startDateTime.isAfter(now))
          .toList();

      if (concerts.isEmpty) {
        return null;
      }

      for (var concert in concerts) {
        double differenceScore = 0.0;

        for (final genre in concert.genres) {
          if (!userGenres.contains(genre)) {
            differenceScore += 1.0;
          }
        }

        if (concert.genres.isNotEmpty) {
          concert.score = (differenceScore / concert.genres.length) * 5.0;
        }

        final daysUntilConcert = concert.startDateTime.difference(now).inDays;
        if (daysUntilConcert <= 30) {
          concert.score += (1.0 - (daysUntilConcert / 30.0)) * 2.0;
        }
      }

      concerts.sort((a, b) => b.score.compareTo(a.score));
      final featuredConcert = concerts.first;

      await _cacheService.set(
        cacheKey,
        featuredConcert.toJson(),
        Duration(hours: _cacheDurationHours),
      );

      return featuredConcert;
    } catch (e) {
      print('Error getting featured concert: $e');
      return null;
    }
  }
}
