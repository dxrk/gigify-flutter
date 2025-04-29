import 'package:flutter/material.dart';
import 'package:nextbigthing/pages/faq_page.dart';
import 'package:nextbigthing/models/followed_artist.dart';
import 'package:nextbigthing/services/spotify/spotify_api.dart';
import 'package:nextbigthing/services/spotify/spotify_auth.dart';
import 'package:nextbigthing/models/top_artist.dart';
import 'package:nextbigthing/pages/welcome_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nextbigthing/services/cache/cache_service.dart';

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
  late int _artistCount;
  late String _accessToken;
  bool _isLoading = true;
  bool _showSettings = false;
  double _maxDistance = 50.0;
  String _selectedLocation = 'Current Location';
  String _customLocation = '';
  bool _isGettingLocation = false;
  bool _isVerifyingLocation = false;
  String? _locationError;
  double? _latitude;
  double? _longitude;
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadLocationSettings();
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadLocationSettings() async {
    final cacheService = await CacheService.initialize();
    final settings = await cacheService.getLocationSettings();

    setState(() {
      _selectedLocation = settings['locationType'];
      _customLocation = settings['location'];
      _maxDistance = settings['maxDistance'];
    });

    if (_selectedLocation == 'Current Location') {
      _getCurrentLocation();
    }

    if (_selectedLocation == 'Custom Location') {
      _locationController.text = _customLocation;
    }
  }

  Future<void> _saveLocationSettings() async {
    final cacheService = await CacheService.initialize();
    await cacheService.saveLocationSettings(
      locationType: _selectedLocation,
      location: _customLocation,
      maxDistance: _maxDistance,
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requestPermission = await Geolocator.requestPermission();
        if (requestPermission == LocationPermission.denied) {
          setState(() {
            _locationError = 'Location permission denied';
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedLocation = 'Current Location';
          _customLocation = '${place.locality}, ${place.administrativeArea}';
          _latitude = position.latitude;
          _longitude = position.longitude;
          _locationError = null;
        });
        await _saveLocationSettings();
      }
    } catch (e) {
      setState(() {
        _locationError = 'Error getting location';
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _verifyCustomLocation(String location) async {
    if (location.isEmpty) {
      setState(() {
        _locationError = 'Please enter a location';
        _latitude = null;
        _longitude = null;
      });
      return;
    }

    setState(() {
      _isVerifyingLocation = true;
      _locationError = null;
    });

    try {
      final locations = await locationFromAddress(location);
      if (locations.isNotEmpty) {
        final location = locations.first;
        setState(() {
          _latitude = location.latitude;
          _longitude = location.longitude;
          _locationError = null;
        });
        await _saveLocationSettings();
      } else {
        setState(() {
          _locationError = 'Location not found';
          _latitude = null;
          _longitude = null;
        });
      }
    } catch (e) {
      setState(() {
        _locationError = 'Invalid location format';
        _latitude = null;
        _longitude = null;
      });
    } finally {
      setState(() {
        _isVerifyingLocation = false;
      });
    }
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
                    const SizedBox(height: 32),
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
                          _buildProfileSection(
                              context,
                              Icons.refresh,
                              'Reset Recommendations',
                              'Reset your recommendations',
                              isDestructive: true, onTap: () async {
                            final cacheService =
                                await CacheService.initialize();
                            await cacheService.clearRecommendations();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Recommendations reset'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }),
                          _buildProfileSection(context, Icons.logout, 'Log Out',
                              'Sign out from your account', isDestructive: true,
                              onTap: () async {
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
            onChanged: (value) {
              setState(() => _maxDistance = value);
              _saveLocationSettings();
            },
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
          const Text('Location Settings',
              style: TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButton<String>(
                  value: _selectedLocation,
                  dropdownColor: const Color(0xFF272727),
                  style: const TextStyle(color: Colors.white),
                  underline: Container(
                    height: 1,
                    color: Colors.grey[700],
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Current Location',
                      child: Text('Current Location'),
                    ),
                    DropdownMenuItem(
                      value: 'Custom Location',
                      child: Text('Custom Location'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value!;
                      if (value == 'Current Location') {
                        _getCurrentLocation();
                      } else {
                        _customLocation = '';
                        _latitude = null;
                        _longitude = null;
                        _locationError = null;
                        _saveLocationSettings();
                      }
                    });
                  },
                ),
              ),
              if (_selectedLocation == 'Current Location')
                IconButton(
                  icon: _isGettingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.purpleAccent),
                          ),
                        )
                      : const Icon(Icons.refresh, color: Colors.purpleAccent),
                  onPressed: _isGettingLocation ? null : _getCurrentLocation,
                ),
            ],
          ),
          if (_selectedLocation == 'Custom Location')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter city, state',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _isVerifyingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.purpleAccent),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.check_circle_outline,
                                  color: Colors.purpleAccent),
                              onPressed: () => _verifyCustomLocation(
                                  _locationController.text),
                            ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _customLocation = value;
                        _locationError = null;
                        _latitude = null;
                        _longitude = null;
                      });
                    },
                    onSubmitted: (value) => _verifyCustomLocation(value),
                  ),
                  if (_locationError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _locationError!,
                        style: const TextStyle(
                            color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  if (_latitude != null && _longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Location verified: ${_customLocation}',
                        style:
                            TextStyle(color: Colors.green[400], fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Divider(color: Colors.grey),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await _saveLocationSettings();
              setState(() => _showSettings = false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purpleAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Save Settings'),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final cacheService = await CacheService.initialize();
              await cacheService.clearCache();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text('Clear Cache'),
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
