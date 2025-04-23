import 'package:flutter/material.dart';
import 'package:nextbigthing/services/spotify/spotify_api.dart';
import 'package:nextbigthing/services/spotify/spotify_auth.dart';
import 'package:nextbigthing/services/concert/concert_recommendation_service.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:nextbigthing/models/artist.dart';
import 'package:nextbigthing/models/venue.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();

  static const routeName = '/home';

  static Route route() {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => const HomePage(),
    );
  }

  static Route onGenerateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => const HomePage(),
    );
  }
}

class _HomePageState extends State<HomePage> {
  late Concert _featuredConcert;
  List<Map<String, String>> _forYou = [];
  List<Map<String, String>> _trending = [];
  String _username = 'User';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    try {
      final token = await getStoredAccessToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final profile = await SpotifyApi.getUserProfile(token);
      final concertService = await ConcertRecommendationService.initialize();
      final concerts = await concertService.getConcertRecommendations(
        accessToken: token,
        location: {'city': 'College Park'},
        radius: 200,
      );

      final recommended = concerts['recommended'] ?? [];
      final discovery = concerts['discovery'] ?? [];

      setState(() {
        _username = profile['display_name'] ?? 'Unknown User';
        _featuredConcert = recommended.isNotEmpty
            ? recommended[0]
            : Concert(
                id: 'unknown',
                artist: Artist(
                  id: 'unknown',
                  name: 'Unknown Artist',
                  popularity: 0,
                  genres: [],
                ),
                name: 'No Upcoming Concerts',
                startDateTime: DateTime.now(),
                venue: Venue(id: 'unknown', name: 'Check back later'),
                imageUrl: 'https://placehold.co/400x200.png',
              );
        _forYou = recommended
            .take(5)
            .map((concert) => {
                  'artist': concert.artist.name,
                  'date': concert.startDateTime.toIso8601String(),
                  'venue': concert.venue.name,
                  'imageUrl':
                      concert.imageUrl ?? 'https://placehold.co/170x170.png',
                })
            .toList();
        _trending = discovery
            .take(5)
            .map((concert) => {
                  'artist': concert.artist.name,
                  'date': concert.startDateTime.toIso8601String(),
                  'imageUrl':
                      concert.imageUrl ?? 'https://placehold.co/200x200.png',
                })
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, $_username',
                        style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check out these upcoming concerts',
                        style: TextStyle(fontSize: 16, color: Colors.grey[400]),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(_featuredConcert.imageUrl ??
                                'https://placehold.co/400x200.png'),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              Colors.black.withOpacity(0.5),
                              BlendMode.darken,
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.purpleAccent.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Featured',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _featuredConcert.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _featuredConcert.venue.name,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.calendar_today,
                                      color: Colors.white70, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    _featuredConcert.startDateTime
                                        .toIso8601String()
                                        .split('T')[0],
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('For You',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See All',
                                style: TextStyle(color: Colors.purpleAccent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 230,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _forYou.length,
                          itemBuilder: (context, index) {
                            final concert = _forYou[index];
                            return Container(
                              width: 170,
                              margin: const EdgeInsets.only(right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                              concert['imageUrl']!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    concert['artist']!,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Flexible(
                                      child: Text(
                                        concert['date']!,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on,
                                        size: 14, color: Colors.grey[400]),
                                      const SizedBox(width: 4),
                                      Flexible(
                                      child: Text(
                                        concert['venue']!,
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Trending Now',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {},
                            child: const Text('See All',
                                style: TextStyle(color: Colors.purpleAccent)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _trending.length,
                        itemBuilder: (context, index) {
                          final trending = _trending[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    image: DecorationImage(
                                      image:
                                          NetworkImage(trending['imageUrl']!),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                trending['artist']!,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                trending['date']!,
                                style: TextStyle(
                                    color: Colors.grey[400], fontSize: 12),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
