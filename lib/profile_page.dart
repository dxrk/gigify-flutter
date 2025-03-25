import 'package:flutter/material.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();

  static const routeName = '/profile';

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => const ProfilePage(),
    );
  }

  static Route onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => const ProfilePage(),
    );
  }
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic> _profileData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<String?> authenticateUser() async {
    final clientId = "3f5f5da98be44de99b22e24005c0fe08";
    final redirectUri = "com.example.nextbigthing://callback";
    final scope = "user-top-read";

    final url = "https://accounts.spotify.com/authorize"
        "?client_id=$clientId"
        "&response_type=token"
        "&redirect_uri=$redirectUri"
        "&scope=$scope";

    final result = await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme: "com.example.nextbigthing",
    );

    // Extract token from redirect URI
    return Uri.parse(result).fragment
        .split("&")
        .firstWhere((e) => e.startsWith("access_token="))
        .split("=")[1];
  }

  Future<List<String>> fetchTopArtists(String accessToken) async {
    const url = "https://api.spotify.com/v1/me/top/artists?limit=10";

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Authorization": "Bearer $accessToken",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['items'] as List).map((artist) => artist['name'] as String).toList();
    } else {
      throw Exception("Failed to load top artists");
    }
  }

  void getTopArtists() async {
    final token = await authenticateUser();
    if (token != null) {
      final artists = await fetchTopArtists(token);
      print("User's Top Artists: $artists");
    } else {
      print("Authentication failed");
    }
  }

  Future<void> _loadProfileData() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    getTopArtists();

    setState(() {
      _profileData = {
        'name': 'Johnny Appleseed',
        'email': 'jappleseed@umd.edu',
        'avatarUrl': 'https://placehold.co/100x100.png',
        'stats': {
          'concerts': 12,
          'upcoming': 5,
          'artists': 8,
        },
        'favoriteArtists': [
          {
            'name': 'Taylor Swift',
            'genre': 'Pop',
            'imageUrl': 'https://placehold.co/100x100.png'
          },
          {
            'name': 'The Weeknd',
            'genre': 'R&B',
            'imageUrl': 'https://placehold.co/100x100.png'
          },
          {
            'name': 'Coldplay',
            'genre': 'Rock',
            'imageUrl': 'https://placehold.co/100x100.png'
          }
        ],
        'concertHistory': [
          {
            'artistName': 'Ed Sheeran',
            'venue': 'Madison Square Garden',
            'date': '2024-01-15',
            'imageUrl': 'https://placehold.co/100x100.png'
          },
          {
            'artistName': 'Drake',
            'venue': 'O2 Arena',
            'date': '2023-12-20',
            'imageUrl': 'https://placehold.co/100x100.png'
          }
        ]
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Gigify.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(_profileData['avatarUrl']),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _profileData['name'],
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _profileData['email'],
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Colors.purpleAccent,
                      ),
                      label: const Text(
                        'Edit Profile',
                        style: TextStyle(
                          color: Colors.purpleAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF272727),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(
                            _profileData['stats']['concerts'].toString(),
                            'Concerts',
                          ),
                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey[700],
                          ),
                          _buildStatColumn(
                            _profileData['stats']['artists'].toString(),
                            'Artists',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildProfileSection(
                            context,
                            Icons.favorite_border,
                            'Favorite Artists',
                            'Check your followed artists',
                          ),
                          _buildProfileSection(
                            context,
                            Icons.history,
                            'Concert History',
                            'Browse your concert history',
                          ),
                          _buildProfileSection(
                            context,
                            Icons.help_outline,
                            'Help & Support',
                            'Contact us or read FAQs',
                          ),
                          _buildProfileSection(
                            context,
                            Icons.logout,
                            'Log Out',
                            'Sign out from your account',
                            isDestructive: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Column _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileSection(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? Colors.redAccent : Colors.purpleAccent,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? Colors.redAccent : Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
        trailing: isDestructive
            ? null
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {},
      ),
    );
  }
}
