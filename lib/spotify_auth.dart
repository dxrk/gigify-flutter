import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// --- Spotify Credentials ---
const String clientId = '3f5f5da98be44de99b22e24005c0fe08';
const String clientSecret = '18c06394174b482ab6ba6df0c0b12c60';
const String redirectUri = 'nextbigthing://callback';
const String authEndpoint = 'https://accounts.spotify.com/authorize';
const String tokenEndpoint = 'https://accounts.spotify.com/api/token';

// Scopes define what permissions your app requests
const String scopes = 'user-read-email user-read-private';

// Secure storage for access tokens
final storage = FlutterSecureStorage();

// --- Function to Generate Authentication URL ---
String generateAuthUrl() {
  return '$authEndpoint?client_id=$clientId'
      '&response_type=code'
      '&redirect_uri=$redirectUri'
      '&scope=$scopes'
      '&state=randomstring123'; // Used for security
}

// --- Function to Authenticate User with Spotify ---
Future<String?> authenticateWithSpotify() async {
  final authUrl = generateAuthUrl();

  try {
    final result = await FlutterWebAuth.authenticate(
      url: authUrl,
      callbackUrlScheme: 'nextbigthing',
    );

    // Extract the authorization code from the redirect URL
    final code = Uri.parse(result).queryParameters['code'];
    return code;
  } catch (e) {
    print('Error during authentication: $e');
    return null;
  }
}

// --- Function to Exchange Authorization Code for Access Token ---
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
    print('Failed to get access token: ${response.body}');
    return null;
  }
}

// --- Function to Store Access Token Securely ---
Future<void> saveAccessToken(String token) async {
  await storage.write(key: 'spotify_access_token', value: token);
}

// --- Function to Retrieve Stored Access Token ---
Future<String?> getStoredAccessToken() async {
  return await storage.read(key: 'spotify_access_token');
}

// --- Function to Logout (Clear Token) ---
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
    return data['items']; // List of top artists
  } else {
    throw Exception('Failed to load top artists: ${response.body}');
  }
}
