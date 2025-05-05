import 'package:flutter/material.dart';
import 'package:nextbigthing/services/spotify/spotify_api.dart';
import 'package:nextbigthing/services/spotify/spotify_auth.dart';
import 'package:nextbigthing/services/favorites/favorites_service.dart';
import 'package:nextbigthing/models/artist.dart';

class FollowedArtist extends StatefulWidget {
  const FollowedArtist({super.key});

  @override
  State<FollowedArtist> createState() => _FollowedArtistState();
}

class _FollowedArtistState extends State<FollowedArtist> {
  List<Artist> _favoriteArtists = [];
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

      final followedArtists = await SpotifyAPI.getFollowedArtists(token);

      setState(() {
        _favoriteArtists = followedArtists;
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
      body:
          _isLoading
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
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                artist.imageUrl ??
                                    'https://placehold.co/100x100.png',
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        const Icon(Icons.person, size: 100),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              artist.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              artist.genres.isNotEmpty
                                  ? artist.genres[0]
                                  : 'Unknown Genre',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: FutureBuilder<bool>(
                            future: FavoritesService.initialize().then(
                              (service) => service.isArtistFavorited(artist.id),
                            ),
                            builder: (context, snapshot) {
                              final isFavorited = snapshot.data ?? false;
                              return IconButton(
                                icon: Icon(
                                  isFavorited
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      isFavorited ? Colors.red : Colors.white,
                                ),
                                onPressed: () async {
                                  final service =
                                      await FavoritesService.initialize();
                                  await service.toggleFavoriteArtist(artist);
                                  setState(() {});
                                },
                              );
                            },
                          ),
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
