import 'package:flutter/material.dart';
import 'package:nextbigthing/pages/faq_page.dart';
import 'package:nextbigthing/models/followed_artist.dart';
import 'package:nextbigthing/services/spotify/spotify_api.dart';
import 'package:nextbigthing/services/spotify/spotify_auth.dart';
import 'package:nextbigthing/models/top_artist.dart';
import 'package:nextbigthing/pages/welcome_screen.dart';

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
  late String _name;
  late String _email;
  late String _avatarUrl;
  late int _concertCount;
  late int _upcomingCount;
  late int _artistCount;
  late String _accessToken;
  bool _isLoading = true;
  bool _showSettings = false;
  double _maxDistance = 50.0;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final token = await getStoredAccessToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      _accessToken = token;
      final profile = await SpotifyApi.getUserProfile(token);
      final topArtists = await SpotifyApi.getTopArtists(token);

      setState(() {
        _name = profile['display_name'] ?? 'Unknown User';
        _email = profile['email'] ?? 'No email available';
        _avatarUrl = profile['images']?.isNotEmpty == true
            ? profile['images'][0]['url']
            : 'https://placehold.co/100x100.png';
        _concertCount = 12;
        _upcomingCount = 5;
        _artistCount = topArtists.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gigify.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => setState(() => _showSettings = !_showSettings),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    if (_showSettings) _buildSettingsPanel(),
                    const SizedBox(height: 20),
                    CircleAvatar(
                        radius: 50, backgroundImage: NetworkImage(_avatarUrl)),
                    const SizedBox(height: 16),
                    Text(_name,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(_email,
                        style:
                            TextStyle(fontSize: 16, color: Colors.grey[400])),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.edit,
                          size: 16, color: Colors.purpleAccent),
                      label: const Text('Edit Profile',
                          style: TextStyle(color: Colors.purpleAccent)),
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
                              _concertCount.toString(), 'Concerts'),
                          Container(
                              height: 40, width: 1, color: Colors.grey[700]),
                          _buildStatColumn(_artistCount.toString(), 'Artists'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          _buildProfileSection(context, Icons.favorite_border,
                              'Followed Artists', 'Check your followed artists',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FollowedArtist()))),
                          _buildProfileSection(context, Icons.history,
                              'Concert History', 'Browse your concert history',
                              onTap: () {}),
                          _buildProfileSection(context, Icons.help_outline,
                              'Help & Support', 'Contact us or read FAQs',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => FAQPage()))),
                          _buildProfileSection(context, Icons.onetwothree,
                              'Top Artists', 'View your top Spotify artists',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => TopArtist(
                                          accessToken: _accessToken)))),
                          _buildProfileSection(context, Icons.logout, 'Log Out',
                              'Sign out from your account', isDestructive: true,
                              onTap: () async {
                            await logout();
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const WelcomeScreen()));
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Settings',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purpleAccent)),
              IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => setState(() => _showSettings = false)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Max Distance for Concerts',
              style: TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          Text('${_maxDistance.toInt()} miles',
              style: TextStyle(fontSize: 14, color: Colors.grey[400])),
          Slider(
            value: _maxDistance,
            min: 10,
            max: 500,
            divisions: 49,
            activeColor: Colors.purpleAccent,
            inactiveColor: Colors.grey[700],
            onChanged: (value) => setState(() => _maxDistance = value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('10 miles',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              Text('500 miles',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notifications',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              Switch(
                  value: true,
                  onChanged: (value) {},
                  activeColor: Colors.purpleAccent),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() => _showSettings = false),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
  }

  Column _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[400])),
      ],
    );
  }

  Widget _buildProfileSection(
      BuildContext context, IconData icon, String title, String subtitle,
      {bool isDestructive = false, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF272727),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon,
            color: isDestructive ? Colors.redAccent : Colors.purpleAccent),
        title: Text(title,
            style: TextStyle(
                color: isDestructive ? Colors.redAccent : Colors.white)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey[400], fontSize: 12)),
        trailing: isDestructive
            ? null
            : const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
