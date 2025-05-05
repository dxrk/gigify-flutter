import 'package:flutter/material.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:nextbigthing/services/concert/concert_recommendation_service.dart';
import 'package:nextbigthing/services/spotify/spotify_auth.dart';
import 'package:nextbigthing/services/cache/cache_service.dart';
import 'package:nextbigthing/pages/concert_details_page.dart';
import 'package:nextbigthing/services/ticketmaster/ticketmaster_api.dart';
import 'package:nextbigthing/services/favorites/favorites_service.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();

  static const routeName = '/discover';

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => const DiscoverPage(),
    );
  }

  static Route onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => const DiscoverPage(),
    );
  }
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<Concert> _concerts = [];
  List<Concert> _allConcerts = [];
  final List<String> _filters = ['Recommended', 'Discovery', 'This Weekend'];
  String _selectedFilter = 'Recommended';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadConcerts();
    _filterConcerts('Recommended');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConcerts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await getStoredAccessToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final concertService = await ConcertRecommendationService.initialize();
      final cacheService = await CacheService.initialize();
      final locationSettings = await cacheService.getLocationSettings();

      final location = {
        'details': locationSettings['location']['details'],
        'latitude': locationSettings['location']['latitude'],
        'longitude': locationSettings['location']['longitude'],
        'type': locationSettings['locationType'].toString(),
      };

      final concertsMap = await concertService.getConcertRecommendations(
        accessToken: token,
        location: location,
        radius: locationSettings['maxDistance'].toInt(),
      );

      final allConcerts = concertsMap.values.expand((list) => list).toList();

      setState(() {
        _allConcerts = allConcerts;
        _concerts = allConcerts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading concerts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchConcerts(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _concerts = _allConcerts;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _isLoading = true;
    });

    try {
      final ticketmasterApi = await TicketmasterAPI.initialize();
      final cacheService = await CacheService.initialize();
      final locationSettings = await cacheService.getLocationSettings();

      final location = {
        'details': locationSettings['location']['details'],
        'latitude': locationSettings['location']['latitude'],
        'longitude': locationSettings['location']['longitude'],
        'type': locationSettings['locationType'].toString(),
      };

      final events = await ticketmasterApi.searchEvents(
        artistName: query,
        location: location,
        radius: locationSettings['maxDistance'].toInt(),
      );

      final concerts = events.map((e) => Concert.fromJson(e)).toList();

      setState(() {
        _concerts = concerts;
        _isLoading = false;
      });
    } catch (e) {
      print('Error searching concerts: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterConcerts(String filter) {
    setState(() {
      _selectedFilter = filter;
      final concertsToFilter = _isSearching ? _concerts : _allConcerts;

      switch (filter) {
        case 'Recommended':
          _concerts = List.from(concertsToFilter);
          break;
        case 'Discovery':
          if (!_isSearching) {
            _concerts = [];
          } else {
            _concerts = concertsToFilter;
          }
          break;
        case 'This Weekend':
          final now = DateTime.now();
          final endOfWeekend = now.add(const Duration(days: 7));
          _concerts = concertsToFilter
              .where(
                (c) =>
                    c.startDateTime.isAfter(now) &&
                    c.startDateTime.isBefore(endOfWeekend),
              )
              .toList();
          break;
        default:
          _concerts = concertsToFilter;
      }
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
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF272727),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () => _filterConcerts(filter),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.purpleAccent.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    filter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.purpleAccent
                                          : Colors.white,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_selectedFilter == 'Discovery')
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search for concerts...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    _searchConcerts('');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25.0),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF272727),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                        ),
                        onSubmitted: _searchConcerts,
                      ),
                    if (_selectedFilter == 'Discovery')
                      const SizedBox(height: 20),
                    Text(
                      _isSearching ? 'Search Results' : '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: _concerts.isEmpty
                          ? Center(
                              child: Text(
                                _isSearching
                                    ? 'Search for concerts'
                                    : 'No upcoming concerts',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _concerts.length,
                              itemBuilder: (context, index) {
                                final concert = _concerts[index];
                                return GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      ConcertDetailsPage.route(concert),
                                    );
                                    if (result == true) {
                                      _loadConcerts();
                                    }
                                  },
                                  child: Card(
                                    margin: const EdgeInsets.only(
                                      bottom: 12,
                                    ),
                                    elevation: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 70,
                                            height: 70,
                                            child: FutureBuilder<ImageProvider>(
                                              future:
                                                  concert.getImageProvider(),
                                              builder: (context, snapshot) {
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                    image: DecorationImage(
                                                      image: snapshot.data ??
                                                          const NetworkImage(
                                                            'https://placehold.co/100x100.png',
                                                          ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
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
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  concert.venue,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  concert
                                                      .getFormattedStartTime(),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          FutureBuilder<bool>(
                                            future:
                                                FavoritesService.initialize()
                                                    .then(
                                              (service) =>
                                                  service.isConcertFavorited(
                                                concert.id,
                                              ),
                                            ),
                                            builder: (context, snapshot) {
                                              final isFavorited =
                                                  snapshot.data ?? false;
                                              return IconButton(
                                                icon: Icon(
                                                  isFavorited
                                                      ? Icons.favorite
                                                      : Icons.favorite_border,
                                                  color: isFavorited
                                                      ? Colors.red
                                                      : Colors.grey[400],
                                                ),
                                                onPressed: () async {
                                                  final service =
                                                      await FavoritesService
                                                          .initialize();
                                                  await service
                                                      .toggleFavoriteConcert(
                                                    concert,
                                                  );
                                                  setState(() {});
                                                },
                                              );
                                            },
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
              ),
      ),
    );
  }
}
