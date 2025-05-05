import 'package:flutter/material.dart';
import 'package:nextbigthing/services/spotify/spotify_api.dart';
import 'package:nextbigthing/services/spotify/spotify_auth.dart';
import 'package:nextbigthing/services/concert/concert_recommendation_service.dart';
import 'package:nextbigthing/services/cache/cache_service.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:nextbigthing/models/artist.dart';
import 'package:nextbigthing/pages/concert_details_page.dart';
import 'package:nextbigthing/services/favorites/favorites_service.dart';
import 'package:nextbigthing/pages/all_recommendations_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late Concert _featuredConcert;
  List<Map<String, String>> _forYou = [];
  List<Map<String, String>> _trending = [];
  String _username = 'User';
  bool _isLoading = true;
  List<Concert> _allConcerts = [];
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  int _currentMessageIndex = 0;

  final List<String> _loadingMessages = [
    "We're cooking up your recommendations...",
    "They're smoking hot! 🔥",
    "Almost ready to rock...",
    "Finding the perfect concerts...",
    "Your music journey awaits...",
    "Loading your personalized picks...",
  ];

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeInOut),
    );

    _startMessageRotation();
    _loadHomeData();
  }

  void _startMessageRotation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        _startMessageRotation();
      }
    });
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
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

      final profile = await SpotifyAPI.getUserProfile(token);
      final concertService = await ConcertRecommendationService.initialize();
      final cacheService = await CacheService.initialize();
      final locationSettings = await cacheService.getLocationSettings();

      if (locationSettings['locationType'] == 'Current Location') {
        try {
          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            print('Location services are disabled');
            return;
          }

          final permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            final requestPermission = await Geolocator.requestPermission();
            if (requestPermission == LocationPermission.denied) {
              print('Location permission denied');
              return;
            }
          }

          if (permission == LocationPermission.deniedForever) {
            print('Location permissions permanently denied');
            return;
          }

          final position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 10),
          );

          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            final location = {
              'details': '${place.locality}, ${place.administrativeArea}',
              'latitude': position.latitude,
              'longitude': position.longitude,
            };
            await cacheService.saveLocationSettings(
              locationType: 'Current Location',
              location: location,
              maxDistance: locationSettings['maxDistance'],
            );
            locationSettings['location'] = location;
          }
        } catch (e) {
          print('Error getting current location: $e');
        }
      }

      final location = {
        'details': locationSettings['location']['details'],
        'latitude': locationSettings['location']['latitude'],
        'longitude': locationSettings['location']['longitude'],
        'type': locationSettings['locationType'].toString(),
      };

      final featuredConcert = await concertService.getFeaturedConcert(
        accessToken: token,
        location: location,
        radius: locationSettings['maxDistance'].toInt(),
      );

      final concerts = await concertService.getConcertRecommendations(
        accessToken: token,
        location: location,
        radius: locationSettings['maxDistance'].toInt(),
      );

      final recommended = concerts['recommended'] ?? [];
      final discovery = concerts['discovery'] ?? [];

      setState(() {
        _username = profile['display_name'] ?? 'Unknown User';
        _featuredConcert = featuredConcert ??
            (recommended.isNotEmpty
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
                    venue: 'Check back later',
                    imageUrl: 'https://placehold.co/400x200.png',
                  ));
        _forYou = recommended
            .take(5)
            .map(
              (concert) => {
                'artist': concert.artist.name,
                'date': concert.startDateTime.toIso8601String(),
                'venue': concert.venue,
                'imageUrl':
                    concert.imageUrl ?? 'https://placehold.co/170x170.png',
              },
            )
            .toList();
        _trending = discovery
            .take(5)
            .map(
              (concert) => {
                'artist': concert.artist.name,
                'date': concert.startDateTime.toIso8601String(),
                'imageUrl':
                    concert.imageUrl ?? 'https://placehold.co/200x200.png',
              },
            )
            .toList();
        _allConcerts = [...recommended, ...discovery];
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
          title: const Text(
            'Gigify.',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Text(
                        _loadingMessages[_currentMessageIndex],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome ${_username.split(" ").first}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check out these upcoming concerts',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            ConcertDetailsPage.route(_featuredConcert),
                          );
                          if (result == true) {
                            _loadHomeData();
                          }
                        },
                        child: Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: DecorationImage(
                              image: NetworkImage(
                                _featuredConcert.imageUrl ??
                                    'https://placehold.co/400x200.png',
                              ),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withValues(alpha: 0.5),
                                BlendMode.darken,
                              ),
                            ),
                          ),
                          child: FutureBuilder<ImageProvider>(
                            future: _featuredConcert.getImageProvider(),
                            builder: (context, snapshot) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: snapshot.data ??
                                        const NetworkImage(
                                          'https://placehold.co/400x200.png',
                                        ),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                      Colors.black.withValues(alpha: 0.5),
                                      BlendMode.darken,
                                    ),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: FutureBuilder<bool>(
                                        future:
                                            FavoritesService.initialize().then(
                                          (service) =>
                                              service.isConcertFavorited(
                                                  _featuredConcert.id),
                                        ),
                                        builder: (context, snapshot) {
                                          final isFavorited =
                                              snapshot.data ?? false;
                                          return Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.black
                                                  .withValues(alpha: 0.5),
                                              shape: BoxShape.circle,
                                            ),
                                            child: IconButton(
                                              icon: Icon(
                                                isFavorited
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isFavorited
                                                    ? Colors.red
                                                    : Colors.white,
                                                size: 20,
                                              ),
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 36,
                                                minHeight: 36,
                                              ),
                                              onPressed: () async {
                                                final service =
                                                    await FavoritesService
                                                        .initialize();
                                                await service
                                                    .toggleFavoriteConcert(
                                                        _featuredConcert);
                                                setState(() {});
                                              },
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.purpleAccent
                                                  .withValues(alpha: 0.3),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                20,
                                              ),
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
                                          Flexible(
                                            child: Text(
                                              _featuredConcert.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 26,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.location_on,
                                                color: Colors.white70,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _featuredConcert.venue,
                                                style: TextStyle(
                                                  color:
                                                      Colors.white.withValues(
                                                    alpha: 0.9,
                                                  ),
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              const Icon(
                                                Icons.calendar_today,
                                                color: Colors.white70,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _featuredConcert
                                                    .getFormattedStartTimeTruncated(),
                                                style: TextStyle(
                                                  color:
                                                      Colors.white.withValues(
                                                    alpha: 0.9,
                                                  ),
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'For You',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AllRecommendationsPage(
                                  concerts: _allConcerts,
                                ),
                              ),
                            ),
                            child: const Text(
                              'See All',
                              style: TextStyle(color: Colors.purpleAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _forYou.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(
                                  'No recommendations available',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 230,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _forYou.length,
                                itemBuilder: (context, index) {
                                  final concert = _forYou[index];
                                  return _buildConcertCard(concert, true);
                                },
                              ),
                            ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Trending Now',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_trending.isNotEmpty)
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AllRecommendationsPage(
                                    concerts: _allConcerts,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'See All',
                                style: TextStyle(color: Colors.purpleAccent),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _trending.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                child: Text(
                                  'No trending concerts available',
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.0,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _trending.length,
                              itemBuilder: (context, index) {
                                final trending = _trending[index];
                                final concertObject = _allConcerts.firstWhere(
                                  (concert) =>
                                      concert.artist.name == trending['artist'],
                                  orElse: () =>
                                      _allConcerts[index + _forYou.length],
                                );
                                return GestureDetector(
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      ConcertDetailsPage.route(concertObject),
                                    );
                                    if (result == true) {
                                      setState(() {});
                                    }
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                image: DecorationImage(
                                                  image: NetworkImage(
                                                    trending['imageUrl']!,
                                                  ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 8,
                                              right: 8,
                                              child: FutureBuilder<bool>(
                                                future: FavoritesService
                                                        .initialize()
                                                    .then(
                                                  (service) => service
                                                      .isConcertFavorited(
                                                    concertObject.id,
                                                  ),
                                                ),
                                                builder: (context, snapshot) {
                                                  final isFavorited =
                                                      snapshot.data ?? false;
                                                  return Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                              alpha: 0.5),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        isFavorited
                                                            ? Icons.favorite
                                                            : Icons
                                                                .favorite_border,
                                                        color: isFavorited
                                                            ? Colors.red
                                                            : Colors.white,
                                                        size: 14,
                                                      ),
                                                      padding: EdgeInsets.zero,
                                                      constraints:
                                                          const BoxConstraints(
                                                        minWidth: 24,
                                                        minHeight: 24,
                                                      ),
                                                      onPressed: () async {
                                                        final service =
                                                            await FavoritesService
                                                                .initialize();
                                                        await service
                                                            .toggleFavoriteConcert(
                                                          concertObject,
                                                        );
                                                        setState(() {});
                                                      },
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        trending['artist']!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        concertObject
                                            .getFormattedStartTimeTruncated(),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
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

  Widget _buildConcertCard(Map<String, String> concert, bool isForYou) {
    final concertObject = _allConcerts.firstWhere(
      (c) =>
          c.artist.name == concert['artist'] &&
          c.startDateTime.toIso8601String() == concert['date'],
    );

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConcertDetailsPage(concert: concertObject),
          ),
        );
        if (result == true) {
          _loadHomeData();
        }
      },
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 170,
                  width: 170,
                  child: FutureBuilder<ImageProvider>(
                    future: concertObject.getImageProvider(),
                    builder: (context, snapshot) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: snapshot.data ??
                                const NetworkImage(
                                  'https://placehold.co/170x170.png',
                                ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FutureBuilder<bool>(
                    future: FavoritesService.initialize().then(
                      (service) => service.isConcertFavorited(concertObject.id),
                    ),
                    builder: (context, snapshot) {
                      final isFavorited = snapshot.data ?? false;
                      return Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorited ? Colors.red : Colors.white,
                            size: 14,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          onPressed: () async {
                            final service = await FavoritesService.initialize();
                            await service.toggleFavoriteConcert(concertObject);
                            setState(() {});
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              concert['artist']!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              concert['venue'] ?? '',
              style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
