import 'package:nextbigthing/services/cache/cache_service.dart';
import 'package:nextbigthing/models/artist.dart';
import 'package:nextbigthing/models/concert.dart';

class FavoritesService {
  final CacheService _cacheService;
  static const String _favoriteArtistsKey = 'favorite_artists';
  static const String _favoriteConcertsKey = 'favorite_concerts';

  FavoritesService._({required CacheService cacheService})
      : _cacheService = cacheService;

  static FavoritesService? _instance;

  static Future<FavoritesService> initialize() async {
    if (_instance == null) {
      final cacheService = await CacheService.initialize();
      _instance = FavoritesService._(cacheService: cacheService);
    }
    return _instance!;
  }

  Future<List<Artist>> getFavoriteArtists() async {
    final artists = await _cacheService.get<List<dynamic>>(_favoriteArtistsKey);
    if (artists == null) return [];
    return artists
        .map((a) => Artist.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<List<Concert>> getFavoriteConcerts() async {
    final concerts = await _cacheService.get<List<dynamic>>(
      _favoriteConcertsKey,
    );
    if (concerts == null) return [];
    return concerts
        .map((c) => Concert.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleFavoriteArtist(Artist artist) async {
    final favorites = await getFavoriteArtists();
    final exists = favorites.any((a) => a.id == artist.id);

    if (exists) {
      favorites.removeWhere((a) => a.id == artist.id);
    } else {
      favorites.add(artist);
    }

    await _cacheService.set(
      _favoriteArtistsKey,
      favorites.map((a) => a.toJson()).toList(),
      const Duration(days: 365),
    );
  }

  Future<void> toggleFavoriteConcert(Concert concert) async {
    final favorites = await getFavoriteConcerts();
    final exists = favorites.any((c) => c.id == concert.id);

    if (exists) {
      favorites.removeWhere((c) => c.id == concert.id);
    } else {
      favorites.add(concert);
    }

    await _cacheService.set(
      _favoriteConcertsKey,
      favorites.map((c) => c.toJson()).toList(),
      const Duration(days: 365),
    );
  }

  Future<bool> isArtistFavorited(String artistId) async {
    final favorites = await getFavoriteArtists();
    return favorites.any((a) => a.id == artistId);
  }

  Future<bool> isConcertFavorited(String concertId) async {
    final favorites = await getFavoriteConcerts();
    return favorites.any((c) => c.id == concertId);
  }

  Future<Map<String, int>> getFavoriteStats() async {
    final favoriteArtists = await getFavoriteArtists();
    final favoriteConcerts = await getFavoriteConcerts();

    final genres = <String>{};
    for (final artist in favoriteArtists) {
      genres.addAll(artist.genres);
    }

    return {
      'favoriteArtists': favoriteArtists.length,
      'favoriteConcerts': favoriteConcerts.length,
      'favoriteGenres': genres.length,
    };
  }
}
