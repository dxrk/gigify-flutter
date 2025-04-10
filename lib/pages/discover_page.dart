import 'package:flutter/material.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:nextbigthing/services/concert/concert_recommendation_service.dart';
import 'package:nextbigthing/services/spotify/spotify_auth.dart';

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
  final List<String> _filters = [
    'Recommended',
    'Discovery',
    'This Weekend',
    'Local',
    'Trending'
  ];
  String _selectedFilter = 'Recommended';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConcerts();
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
      final location = {'city': 'College Park'};
      final concertsMap = await concertService.getConcertRecommendations(
        accessToken: token,
        location: location,
        radius: 50,
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

  void _filterConcerts(String filter) {
    setState(() {
      _selectedFilter = filter;
      switch (filter) {
        case 'Recommended':
          _concerts = _allConcerts.where((c) => c.score >= 7.0).toList();
          break;
        case 'Discovery':
          _concerts = _allConcerts.where((c) => c.score < 7.0).toList();
          break;
        case 'This Weekend':
          final now = DateTime.now();
          final endOfWeekend = now.add(const Duration(days: 7));
          _concerts = _allConcerts
              .where((c) =>
                  c.startDateTime.isAfter(now) &&
                  c.startDateTime.isBefore(endOfWeekend))
              .toList();
          break;
        case 'Local':
          _concerts = _allConcerts
              .where((c) => c.venue.city?.toLowerCase() == 'college park')
              .toList();
          break;
        case 'Trending':
          _concerts = List.from(_allConcerts)..shuffle();
          _concerts = _concerts.take(5).toList();
          break;
        default:
          _concerts = _allConcerts;
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
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search concerts',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25.0),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF272727),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: _filters
                            .map((filter) => _buildFilterPill(filter))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Upcoming Concerts',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _concerts.length,
                        itemBuilder: (context, index) {
                          final concert = _concerts[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          concert.imageUrl ??
                                              'https://placehold.co/100x100.png',
                                        ),
                                        fit: BoxFit.cover,
                                      ),
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
                                          concert.venue.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          concert.startDateTime
                                              .toString()
                                              .split('T')
                                              .first,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.favorite_border,
                                      color: Colors.purpleAccent,
                                    ),
                                    onPressed: () {},
                                  ),
                                ],
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

  Widget _buildFilterPill(String label) {
    final isSelected = _selectedFilter == label;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        backgroundColor: const Color(0xFF272727),
        selectedColor: Colors.purpleAccent.withOpacity(0.2),
        side: BorderSide.none,
        onSelected: (bool selected) {
          if (selected) {
            _filterConcerts(label);
          }
        },
        labelStyle: TextStyle(
          color: isSelected ? Colors.purpleAccent : Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
