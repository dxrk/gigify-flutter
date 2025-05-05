import 'package:flutter/material.dart';
import 'package:nextbigthing/services/spotify/spotify_api.dart';

class TopArtist extends StatefulWidget {
  final String accessToken;

  const TopArtist({super.key, required this.accessToken});

  @override
  State<TopArtist> createState() => _TopArtistState();
}

class _TopArtistState extends State<TopArtist> {
  List<Map<String, dynamic>> _topArtists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopArtists();
  }

  Future<void> _loadTopArtists() async {
    try {
      final artists = await SpotifyAPI.getTopArtists(widget.accessToken);
      setState(() {
        _topArtists = artists.map((artist) => artist.toJson()).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading top artists: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Artists')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: _topArtists.length,
                itemBuilder: (context, index) {
                  final artist = _topArtists[index];
                  final String imageUrl =
                      artist['imageUrl'] ?? 'https://placehold.co/300x300.png';
                  final String name = artist['name'] ?? 'Unknown Artist';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
    );
  }
}
