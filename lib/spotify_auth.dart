import 'dart:math';

import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
String get clientSecret => dotenv.env['SPOTIFY_CLIENT_SECRET'] ?? '';
String get redirectUri => dotenv.env['SPOTIFY_REDIRECT_URI'] ?? '';

const String authEndpoint = 'https://accounts.spotify.com/authorize';
const String tokenEndpoint = 'https://accounts.spotify.com/api/token';

const String scopes =
    'user-read-email user-read-private user-top-read user-read-recently-played user-read-currently-playing user-read-playback-state';

final storage = FlutterSecureStorage();

String generateAuthUrl() {
  final encodedScopes = Uri.encodeFull(scopes);
  return '$authEndpoint?client_id=$clientId'
      '&response_type=code'
      '&redirect_uri=$redirectUri'
      '&scope=$encodedScopes'
      '&state=randomstring123${Random().nextInt(1000)}';
}

Future<String?> authenticateWithSpotify() async {
  final authUrl = generateAuthUrl();

  try {
    final result = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: 'nextbigthing',
    );

    final uri = Uri.parse(result);

    var code = uri.queryParameters['code'];

    if (code == null && uri.fragment.isNotEmpty) {
      final fragmentParams = Uri.splitQueryString(uri.fragment);
      code = fragmentParams['code'];
    }

    if (code == null) {
      return throw Exception('Failed to extract code from redirect');
    }

    return code;
  } catch (e) {
    return throw Exception('Failed to authenticate with Spotify: $e');
  }
}

Future<String?> getAccessToken(String code) async {
  final response = await http.post(
    Uri.parse(tokenEndpoint),
    headers: {
      'Authorization':
          'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': redirectUri,
    },
  );

  if (response.statusCode == 200) {
    final jsonResponse = jsonDecode(response.body);
    final accessToken = jsonResponse['access_token'];
    await saveAccessToken(accessToken);
    return accessToken;
  } else {
    return throw Exception('Failed to get access token: ${response.body}');
  }
}

Future<void> saveAccessToken(String token) async {
  await storage.write(key: 'spotify_access_token', value: token);
}

Future<String?> getStoredAccessToken() async {
  return await storage.read(key: 'spotify_access_token');
}

Future<void> logout() async {
  await storage.delete(key: 'spotify_access_token');
}

Future<List<dynamic>> getTopArtists(String accessToken) async {
  final url = Uri.parse('https://api.spotify.com/v1/me/top/artists?limit=10');

  final response = await http.get(
    url,
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
