import 'package:nextbigthing/models/artist.dart';
import 'package:nextbigthing/services/cache/cache_service.dart';
import 'package:nextbigthing/utils/date_utils.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class Concert {
  final String id;
  final Artist artist;
  final String name;
  final DateTime startDateTime;
  final DateTime? endDateTime;
  final String venue;
  final String? imageUrl;
  final double? minPrice;
  final double? maxPrice;
  final String? ticketUrl;
  final List<String> genres;
  final String? description;
  final bool isSoldOut;
  final int? ageRestriction;
  String? _cachedImagePath;
  bool _isCachingImage = false;

  double score;

  Concert({
    required this.id,
    required this.artist,
    required this.name,
    required this.startDateTime,
    this.endDateTime,
    required this.venue,
    this.imageUrl,
    this.minPrice,
    this.maxPrice,
    this.ticketUrl,
    this.genres = const [],
    this.description,
    this.isSoldOut = false,
    this.ageRestriction,
    this.score = 0.0,
  });

  Future<String?> getCachedImagePath() async {
    if (_cachedImagePath != null) return _cachedImagePath;
    if (imageUrl == null) return null;
    if (_isCachingImage) return null;

    _isCachingImage = true;
    try {
      final cacheService = await CacheService.initialize();
      _cachedImagePath = await cacheService.cacheImage(imageUrl!);
      return _cachedImagePath;
    } finally {
      _isCachingImage = false;
    }
  }

  Future<bool> isImageCached() async {
    if (imageUrl == null) return false;
    if (_cachedImagePath != null) return true;

    final cacheService = await CacheService.initialize();
    return await cacheService.isImageCached(imageUrl!);
  }

  Future<ImageProvider> getImageProvider() async {
    if (imageUrl == null) {
      return const NetworkImage('https://placehold.co/400x400.png');
    }

    final cachedPath = await getCachedImagePath();
    if (cachedPath != null) {
      return FileImage(File(cachedPath));
    }

    return NetworkImage(imageUrl!);
  }

  factory Concert.fromJson(Map<String, dynamic> json) {
    final startDate = json.containsKey('dates') &&
            json['dates'].containsKey('start') &&
            json['dates']['start'].containsKey('dateTime')
        ? DateTime.parse(json['dates']['start']['dateTime'] as String)
        : json.containsKey('startDateTime')
            ? DateTime.parse(json['startDateTime'] as String)
            : DateTime.now();

    final endDate = json.containsKey('dates') &&
            json['dates'].containsKey('end') &&
            json['dates']['end'].containsKey('dateTime')
        ? DateTime.parse(json['dates']['end']['dateTime'] as String)
        : null;

    double? minPrice;
    double? maxPrice;
    if (json.containsKey('priceRanges') &&
        (json['priceRanges'] as List<dynamic>).isNotEmpty) {
      final priceRange = json['priceRanges'][0] as Map<String, dynamic>;
      minPrice = priceRange.containsKey('min')
          ? (priceRange['min'] as num).toDouble()
          : null;
      maxPrice = priceRange.containsKey('max')
          ? (priceRange['max'] as num).toDouble()
          : null;
    }

    final venue = json.containsKey('_embedded') &&
            json['_embedded'].containsKey('venues') &&
            (json['_embedded']['venues'] as List<dynamic>).isNotEmpty
        ? (json['_embedded']['venues'][0] as Map<String, dynamic>)['name']
            .toString()
        : json.containsKey('venue')
            ? json['venue'].toString()
            : 'Unknown Venue';

    final artistData = json.containsKey('_embedded') &&
            json['_embedded'].containsKey('attractions') &&
            (json['_embedded']['attractions'] as List<dynamic>).isNotEmpty
        ? json['_embedded']['attractions'][0] as Map<String, dynamic>
        : {'id': 'unknown', 'name': json['name'] ?? 'Unknown Artist'};

    Artist artist;
    if (json.containsKey('artist') && json['artist'] is Map<String, dynamic>) {
      artist = Artist.fromJson(json['artist'] as Map<String, dynamic>);
    } else {
      final List<String> genres = [];
      if (json.containsKey('classifications')) {
        for (final classification in json['classifications'] as List<dynamic>) {
          if (classification.containsKey('genre') &&
              classification['genre'].containsKey('name') &&
              classification['genre']['name'] != 'Undefined') {
            genres.add(classification['genre']['name'] as String);
          }
          if (classification.containsKey('subGenre') &&
              classification['subGenre'].containsKey('name') &&
              classification['subGenre']['name'] != 'Undefined') {
            genres.add(classification['subGenre']['name'] as String);
          }
        }
      }

      artist = Artist(
        id: artistData['id']?.toString() ?? 'unknown',
        name: artistData['name']?.toString() ?? 'Unknown Artist',
        popularity: 0,
        genres: genres,
        imageUrl: artistData.containsKey('images') &&
                (artistData['images'] as List<dynamic>).isNotEmpty
            ? (artistData['images'] as List<dynamic>)[0]['url'] as String
            : null,
      );
    }

    String? ticketUrl;
    if (json.containsKey('url')) {
      ticketUrl = json['url'] as String;
    } else if (json.containsKey('_links') &&
        json['_links'].containsKey('self') &&
        json['_links']['self'].containsKey('href')) {
      ticketUrl = json['_links']['self']['href'] as String;
    }

    String? imageUrl;
    if (json.containsKey('imageUrl')) {
      imageUrl = json['imageUrl'] as String;
    } else if (json.containsKey('images') &&
        (json['images'] as List<dynamic>).isNotEmpty) {
      final images = List<Map<String, dynamic>>.from(
        json['images'] as List<dynamic>,
      );
      images.sort((a, b) => (b['width'] as int).compareTo(a['width'] as int));
      imageUrl = images[0]['url'] as String;
    }

    bool isSoldOut = false;
    if (json.containsKey('dates') &&
        json['dates'].containsKey('status') &&
        json['dates']['status'].containsKey('code')) {
      isSoldOut = (json['dates']['status']['code'] as String) == 'offsale';
    }

    int? ageRestriction;
    if (json.containsKey('ageRestrictions') &&
        json['ageRestrictions'].containsKey('legalAgeEnforced') &&
        json['ageRestrictions']['legalAgeEnforced'] == true) {
      ageRestriction = 21;
    } else if (json.containsKey('info')) {
      final info = json['info'] as String;
      if (info.contains('18+')) {
        ageRestriction = 18;
      } else if (info.contains('21+')) {
        ageRestriction = 21;
      }
    }

    final List<String> genres = [];
    if (json.containsKey('classifications')) {
      for (final classification in json['classifications'] as List<dynamic>) {
        if (classification.containsKey('genre') &&
            classification['genre'].containsKey('name') &&
            classification['genre']['name'] != 'Undefined') {
          genres.add(classification['genre']['name'] as String);
        }
        if (classification.containsKey('subGenre') &&
            classification['subGenre'].containsKey('name') &&
            classification['subGenre']['name'] != 'Undefined') {
          genres.add(classification['subGenre']['name'] as String);
        }
      }
    }

    final allGenres = {...artist.genres, ...genres}.toList();

    return Concert(
      id: json['id']?.toString() ?? 'unknown_id',
      artist: artist,
      name: json['name']?.toString() ?? 'Untitled Concert',
      startDateTime: startDate,
      endDateTime: endDate,
      venue: venue,
      imageUrl: imageUrl,
      minPrice: minPrice,
      maxPrice: maxPrice,
      ticketUrl: ticketUrl,
      genres: allGenres,
      description: json['info']?.toString(),
      isSoldOut: isSoldOut,
      ageRestriction: ageRestriction,
      score:
          json.containsKey('score') ? (json['score'] as num).toDouble() : 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'artist': artist.toJson(),
      'name': name,
      'startDateTime': startDateTime.toIso8601String(),
      'endDateTime': endDateTime?.toIso8601String(),
      'venue': venue,
      'imageUrl': imageUrl,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'ticketUrl': ticketUrl,
      'genres': genres,
      'description': description,
      'isSoldOut': isSoldOut,
      'ageRestriction': ageRestriction,
      'score': score,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Concert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Concert(id: $id, name: $name, artist: ${artist.name})';

  String getFormattedStartTimeTruncated() {
    return ConcertDateUtils.getFormattedStartTimeTruncated(startDateTime);
  }

  String getFormattedStartTime() {
    return ConcertDateUtils.getFormattedStartTime(startDateTime);
  }
}
