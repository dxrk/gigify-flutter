import 'package:flutter/material.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:nextbigthing/models/genre.dart';
import 'package:nextbigthing/pages/concert_details_page.dart';

class AllRecommendationsPage extends StatefulWidget {
  final List<Concert> concerts;

  const AllRecommendationsPage({super.key, required this.concerts});

  @override
  State<AllRecommendationsPage> createState() => _AllRecommendationsPageState();
}

class _AllRecommendationsPageState extends State<AllRecommendationsPage> {
  String? _selectedGenre;
  List<Concert> _filteredConcerts = [];
  final List<String> _mainGenres = [
    'rock',
    'pop',
    'hip hop',
    'electronic',
    'metal',
    'jazz',
    'country',
    'classical',
    'reggae',
    'latin',
    'folk',
    'blues',
    'funk',
    'punk',
    'indie',
  ];

  @override
  void initState() {
    super.initState();
    _filteredConcerts = widget.concerts;
  }

  void _filterByGenre(String? genre) {
    setState(() {
      _selectedGenre = genre;
      if (genre == null) {
        _filteredConcerts = widget.concerts;
      } else {
        _filteredConcerts =
            widget.concerts.where((concert) {
              return concert.genres.any(
                (concertGenre) => Genre.areRelated(
                  concertGenre.toLowerCase(),
                  genre.toLowerCase(),
                ),
              );
            }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Recommendations')),
      body: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _mainGenres.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('All'),
                      selected: _selectedGenre == null,
                      onSelected: (selected) {
                        if (selected) _filterByGenre(null);
                      },
                    ),
                  );
                }
                final genre = _mainGenres[index - 1];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(genre),
                    selected: _selectedGenre == genre,
                    onSelected: (selected) {
                      if (selected) _filterByGenre(genre);
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child:
                _filteredConcerts.isEmpty
                    ? Center(
                      child: Text(
                        'No concerts found for ${_selectedGenre ?? 'all genres'}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredConcerts.length,
                      itemBuilder: (context, index) {
                        final concert = _filteredConcerts[index];
                        return GestureDetector(
                          onTap:
                              () => Navigator.push(
                                context,
                                ConcertDetailsPage.route(concert),
                              ),
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: FutureBuilder<ImageProvider>(
                                      future: concert.getImageProvider(),
                                      builder: (context, snapshot) {
                                        return Image(
                                          image:
                                              snapshot.data ??
                                              const NetworkImage(
                                                'https://placehold.co/100x100.png',
                                              ),
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 14,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                concert.venue,
                                                style: TextStyle(
                                                  color: Colors.grey[400],
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
