import 'package:flutter/material.dart';

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
  List<Map<String, dynamic>> _concerts = [];
  final List<String> _filters = [
    'This Weekend',
    'Rock',
    'Pop',
    'Jazz',
    'Local',
    'Trending'
  ];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConcerts();
  }

  Future<void> _loadConcerts() async {
    // Simulate API call delay, for testing
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _concerts = [
        {
          'id': '1',
          'artistName': 'Taylor Swift',
          'venue': 'Madison Square Garden',
          'date': 'March 15 2025',
          'imageUrl': 'https://placehold.co/100x100.png',
          'genre': 'Pop',
          'price': '\$150'
        },
        {
          'id': '2',
          'artistName': 'The Weeknd',
          'venue': 'Staples Center',
          'date': 'March 16 2025',
          'imageUrl': 'https://placehold.co/100x100.png',
          'genre': 'R&B',
          'price': '\$120'
        },
        {
          'id': '3',
          'artistName': 'Coldplay',
          'venue': 'Wembley Stadium',
          'date': 'March 17 2025',
          'imageUrl': 'https://placehold.co/100x100.png',
          'genre': 'Rock',
          'price': '\$200'
        },
        {
          'id': '4',
          'artistName': 'Drake',
          'venue': 'O2 Arena',
          'date': 'March 18 2025',
          'imageUrl': 'https://placehold.co/100x100.png',
          'genre': 'Hip Hop',
          'price': '\$180'
        },
        {
          'id': '5',
          'artistName': 'Ed Sheeran',
          'venue': 'Rogers Centre',
          'date': 'March 19 2025',
          'imageUrl': 'https://placehold.co/100x100.png',
          'genre': 'Pop',
          'price': '\$130'
        }
      ];
      _isLoading = false;
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
                    // Search bar
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
                      'Popular Concerts',
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
                                        image:
                                            NetworkImage(concert['imageUrl']),
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
                                          concert['artistName'],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          concert['venue'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          concert['date'],
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
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        backgroundColor: const Color(0xFF272727),
        selectedColor: Colors.purpleAccent.withValues(alpha: 0.2),
        side: BorderSide.none,
        onSelected: (bool selected) {},
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
