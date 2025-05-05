import 'package:flutter/material.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:nextbigthing/services/favorites/favorites_service.dart';
import 'package:nextbigthing/pages/concert_details_page.dart';

class FavoritedConcertsPage extends StatefulWidget {
  const FavoritedConcertsPage({super.key});

  @override
  State<FavoritedConcertsPage> createState() => _FavoritedConcertsPageState();
}

class _FavoritedConcertsPageState extends State<FavoritedConcertsPage> {
  List<Concert> _favoritedConcerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoritedConcerts();
  }

  Future<void> _loadFavoritedConcerts() async {
    try {
      final service = await FavoritesService.initialize();
      final concerts = await service.getFavoriteConcerts();

      setState(() {
        _favoritedConcerts = concerts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading favorited concerts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorited Concerts')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _favoritedConcerts.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No favorited concerts yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _favoritedConcerts.length,
                itemBuilder: (context, index) {
                  final concert = _favoritedConcerts[index];
                  return GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          ConcertDetailsPage.route(concert),
                        ).then((_) => _loadFavoritedConcerts()),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                concert.imageUrl ??
                                    'https://placehold.co/100x100.png',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    concert.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    concert.artist.name,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        concert.getFormattedStartTime(),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.favorite,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final service =
                                    await FavoritesService.initialize();
                                await service.toggleFavoriteConcert(concert);
                                _loadFavoritedConcerts();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
