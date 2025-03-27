import 'package:flutter/material.dart';
import 'package:nextbigthing/spotify_auth.dart';
import 'package:nextbigthing/spotify_api.dart';
import 'package:nextbigthing/top_artist.dart';
import 'package:nextbigthing/welcome_screen.dart';

class TopArtist extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Top Artist')),
      body: Center(
        child: Text('This is the Subpage'),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => TopArtistState();
}

class TopArtistState extends State<TopArtist> {
  Map<String, dynamic> _artistData = {};
  bool _isLoading = true;
  bool _showSettings = false;
  double _maxDistance = 50.0;

  Future<void> _loadProfileData() async {
    try {
      final token = await getStoredAccessToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch user profile data and top artists
      final profile = await SpotifyApi.getUserProfile(token);
      final topArtists = await SpotifyApi.getTopArtists(token);
      final recentlyPlayed = await SpotifyApi.getRecentlyPlayed(token);

      setState(() {
        _artistData = {
          'favoriteArtists': topArtists
              .map((artist) => {
                    'name': artist['name'],
                    'genre': artist['genres']?.isNotEmpty == true
                        ? artist['genres'][0]
                        : 'Unknown Genre',
                    'imageUrl': artist['images']?.isNotEmpty == true
                        ? artist['images'][0]['url']
                        : 'https://placehold.co/100x100.png'
                  })
              .toList(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Top Artists'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Top Artists'),
      ),
      body: _artistData['favoriteArtists'] != null
          ? GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // number of items per row
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.75, // Aspect ratio of each item
              ),
              itemCount: _artistData['favoriteArtists'].length,
              itemBuilder: (context, index) {
                final artist = _artistData['favoriteArtists'][index];
                return GestureDetector(
                  onTap: () {
                    // You can add actions for when you tap on an artist
                    print('Tapped on ${artist['name']}');
                  },
                  child: Card(
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            artist['imageUrl'],
                            height: 150,
                            width: 150,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          artist['name'],
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          artist['genre'],
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : Center(child: Text('No favorite artists found')),
    );
  }
}
