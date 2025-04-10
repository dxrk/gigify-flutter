import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:nextbigthing/models/concert.dart';

class CacheService {
  static CacheService? _instance;
  late final SharedPreferences _prefs;
  final DefaultCacheManager _cacheManager = DefaultCacheManager();

  CacheService._({required SharedPreferences prefs}) : _prefs = prefs;

  static Future<CacheService> initialize() async {
    if (_instance == null) {
      final prefs = await SharedPreferences.getInstance();
      _instance = CacheService._(prefs: prefs);
    }
    return _instance!;
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

  Future<bool> containsKey(String key) async {
    if (!_prefs.containsKey(key)) return false;

    final expiryKey = '${key}_expiry';
    if (!_prefs.containsKey(expiryKey)) return false;

    final expiryTimestamp = _prefs.getInt(expiryKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    return now <= expiryTimestamp;
  }
}
