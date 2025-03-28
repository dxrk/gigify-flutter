import 'package:flutter/material.dart';
import 'package:nextbigthing/spotify_api.dart';
import 'package:nextbigthing/spotify_auth.dart';

class FollowedArtist extends StatefulWidget {
  const FollowedArtist({super.key});

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Followed Artist')),
      body: Center(
        child: Text('This is the Subpage'),
      ),
    );
  }

  @override
  State<StatefulWidget> createState() => FollowedArtistState();
}

class FollowedArtistState extends State<FollowedArtist> {
  Map<String, dynamic> _artistData = {};
  bool _isLoading = true;

  Future<void> _loadProfileData() async {
    try {
      final token = await getStoredAccessToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final followedArtist = await SpotifyApi.getFollowedArtists(token);

      setState(() {
        _artistData = {
          'favoriteArtists': followedArtist
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
          title: Text('Followed Artists'),
        ),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Followed Artists'),
      ),
      body: _artistData['favoriteArtists'] != null
          ? GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 0.75,
              ),
              itemCount: _artistData['favoriteArtists'].length,
              itemBuilder: (context, index) {
                final artist = _artistData['favoriteArtists'][index];
                return GestureDetector(
                  onTap: () {
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
          : Center(child: Text('No followed artists found')),
    );
  }
}
