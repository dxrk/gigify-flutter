import 'package:flutter/material.dart';
import 'package:nextbigthing/services/spotify/spotify_api.dart';
import 'package:nextbigthing/services/spotify/spotify_auth.dart';

class FollowedArtist extends StatefulWidget {
  const FollowedArtist({super.key});

  @override
  State<FollowedArtist> createState() => _FollowedArtistState();
}

class _FollowedArtistState extends State<FollowedArtist> {
  List<Map<String, String>> _favoriteArtists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowedArtists();
  }

  Future<void> _loadFollowedArtists() async {
    try {
      final token = await getStoredAccessToken();
      if (token == null) {
        setState(() => _isLoading = false);
        return;
      }

      final followedArtists = await SpotifyApi.getFollowedArtists(token);

      final artists = followedArtists
          .map<Map<String, String>>((artist) => {
                'name': artist.name,
                'genre': artist.genres.isNotEmpty
                    ? artist.genres[0]
                    : 'Unknown Genre',
                'imageUrl':
                    (artist.imageUrl != null && artist.imageUrl!.isNotEmpty)
                        ? artist.imageUrl!
                        : 'https://placehold.co/100x100.png',
              })
          .toList();

      setState(() {
        _favoriteArtists = artists;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading followed artists: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Followed Artists')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favoriteArtists.isNotEmpty
              ? GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _favoriteArtists.length,
                  itemBuilder: (context, index) {
                    final artist = _favoriteArtists[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              artist['imageUrl']!,
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.person, size: 100),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist['name']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            artist['genre']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  },
                )
              : const Center(child: Text('No followed artists found')),
    );
  }
}
