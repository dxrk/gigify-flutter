import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:path/path.dart' as p;

class TicketmasterImageCacheManager extends CacheManager {
  static const key = 'ticketmasterImages';
  static const Duration maxAge = Duration(days: 7);

  static final TicketmasterImageCacheManager _instance =
      TicketmasterImageCacheManager._();

  factory TicketmasterImageCacheManager() {
    return _instance;
  }

  TicketmasterImageCacheManager._()
      : super(Config(
          key,
          stalePeriod: maxAge,
          maxNrOfCacheObjects: 100,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ));
}

class CacheService {
  static CacheService? _instance;
  late final SharedPreferences _prefs;
  final DefaultCacheManager _cacheManager = DefaultCacheManager();
  final TicketmasterImageCacheManager _imageCacheManager =
      TicketmasterImageCacheManager();

  static const String _locationKey = 'user_location';
  static const String _locationTypeKey = 'location_type';
  static const String _maxDistanceKey = 'max_distance';

  CacheService._({required SharedPreferences prefs}) : _prefs = prefs;

  static Future<CacheService> initialize() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = CacheService._(prefs: prefs);
    }
    return _instance!;
  }

  Future<void> saveLocationSettings({
    required String locationType,
    required Map<String, dynamic> location,
    required double maxDistance,
  }) async {
    await _prefs.setString(_locationTypeKey, locationType);
    await _prefs.setString(_locationKey, location['details'] ?? '');
    if (location['latitude'] != null && location['longitude'] != null) {
      await _prefs.setDouble('${_locationKey}_lat', location['latitude']);
      await _prefs.setDouble('${_locationKey}_lng', location['longitude']);
    }
    await _prefs.setDouble(_maxDistanceKey, maxDistance);
  }

  Future<Map<String, dynamic>> getLocationSettings() async {
    final locationString = _prefs.getString(_locationKey) ?? '';
    final latitude = _prefs.getDouble('${_locationKey}_lat');
    final longitude = _prefs.getDouble('${_locationKey}_lng');

    Map<String, dynamic> locationData = {
      'details': locationString,
      'latitude': latitude,
      'longitude': longitude,
    };

    return {
      'locationType': _prefs.getString(_locationTypeKey) ?? 'Current Location',
      'location': locationData,
      'maxDistance': _prefs.getDouble(_maxDistanceKey) ?? 50.0,
    };
  }

  Future<T?> get<T>(String key) async {
    final expiryKey = '${key}_expiry';
    if (!_prefs.containsKey(key) || !_prefs.containsKey(expiryKey)) {
      return null;
    }

    final expiryTimestamp = _prefs.getInt(expiryKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (now > expiryTimestamp) {
      await _prefs.remove(key);
      await _prefs.remove(expiryKey);
      return null;
    }

    final jsonString = _prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final dynamic decoded = json.decode(jsonString);

      if (T == String) {
        return decoded as T;
      } else if (T == int) {
        return decoded as T;
      } else if (T == double) {
        return decoded as T;
      } else if (T == bool) {
        return decoded as T;
      } else if (T == Map<String, List<dynamic>>) {
        return decoded as T;
      } else if (T == Map<String, dynamic>) {
        return decoded as T;
      } else if (T == List<dynamic>) {
        return decoded as T;
      } else if (T == Map<String, List<Concert>>) {
        final result = <String, List<Concert>>{};
        final Map<String, dynamic> map = decoded as Map<String, dynamic>;

        for (final entry in map.entries) {
          final List<dynamic> concertList = entry.value as List<dynamic>;
          result[entry.key] = concertList
              .map((concertJson) =>
                  Concert.fromJson(concertJson as Map<String, dynamic>))
              .toList();
        }

        return result as T;
      }

      return decoded as T;
    } catch (e) {
      print('Error deserializing cached data: $e');
      return null;
    }
  }

  Future<bool> set<T>(String key, T value, Duration expiryDuration) async {
    try {
      final expiryTimestamp =
          DateTime.now().add(expiryDuration).millisecondsSinceEpoch;

      await _prefs.setInt('${key}_expiry', expiryTimestamp);

      final jsonString = json.encode(value);
      return await _prefs.setString(key, jsonString);
    } catch (e) {
      print('Error caching data: $e');
      return false;
    }
  }

  Future<bool> remove(String key) async {
    try {
      await _prefs.remove('${key}_expiry');
      return await _prefs.remove(key);
    } catch (e) {
      print('Error removing cached data: $e');
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      await _cacheManager.emptyCache();
      await _imageCacheManager.emptyCache();
      return await _prefs.clear();
    } catch (e) {
      print('Error clearing cache: $e');
      return false;
    }
  }

  Future<String?> cacheFile(String url, String key) async {
    try {
      final fileInfo = await _cacheManager.downloadFile(
        url,
        key: key,
      );
      return fileInfo.file.path;
    } catch (e) {
      print('Error caching file: $e');
      return null;
    }
  }

  Future<String?> cacheImage(String url) async {
    try {
      final fileInfo = await _imageCacheManager.downloadFile(
        url,
        key: p.basename(url),
      );
      return fileInfo.file.path;
    } catch (e) {
      print('Error caching image: $e');
      return null;
    }
  }

  Future<bool> containsKey(String key) async {
    if (!_prefs.containsKey(key)) return false;

    final expiryKey = '${key}_expiry';
    if (!_prefs.containsKey(expiryKey)) return false;

    final expiryTimestamp = _prefs.getInt(expiryKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    return now <= expiryTimestamp;
  }

  Future<bool> isImageCached(String url) async {
    try {
      final file = await _imageCacheManager.getFileFromCache(p.basename(url));
      return file != null;
    } catch (e) {
      return false;
    }
  }

  Future<bool> clearRecommendations() async {
    try {
      final keys = _prefs.getKeys();

      final recommendationKeys = keys.where((key) =>
          key.contains('recommendations') ||
          key.contains('concert_recommendations'));

      for (final key in recommendationKeys) {
        await _prefs.remove(key);
      }

      await _cacheManager.emptyCache();
      await _imageCacheManager.emptyCache();

      return true;
    } catch (e) {
      print('Error clearing recommendations: $e');
      return false;
    }
  }

  Future<bool> clearCache() async {
    try {
      await _cacheManager.emptyCache();
      await _imageCacheManager.emptyCache();
      return await _prefs.clear();
    } catch (e) {
      print('Error clearing cache: $e');
      return false;
    }
  }
}
