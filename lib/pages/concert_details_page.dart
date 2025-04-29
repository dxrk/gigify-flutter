import 'package:flutter/material.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ConcertDetailsPage extends StatelessWidget {
  final Concert concert;

  const ConcertDetailsPage({super.key, required this.concert});

  static const routeName = '/concert-details';

  static Route route(Concert concert) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => ConcertDetailsPage(concert: concert),
    );
  }

  Future<void> _launchTicketUrl() async {
    if (concert.ticketUrl != null) {
      final uri = Uri.parse(concert.ticketUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: FutureBuilder<ImageProvider>(
                future: concert.getImageProvider(),
                builder: (context, snapshot) {
                  return Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: snapshot.data ??
                            const NetworkImage(
                                'https://placehold.co/400x200.png'),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.5),
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    concert.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    concert.artist.name,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    'Date & Time',
                    [
                      _buildInfoRow(
                        Icons.calendar_today,
                        DateFormat('EEEE, MMMM d, y')
                            .format(concert.startDateTime),
                      ),
                      _buildInfoRow(
                        Icons.access_time,
                        DateFormat('h:mm a').format(concert.startDateTime),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    'Venue',
                    [
                      _buildInfoRow(
                        Icons.location_on,
                        concert.venue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (concert.minPrice != null || concert.maxPrice != null)
                    _buildInfoSection(
                      'Price Range',
                      [
                        _buildInfoRow(
                          Icons.attach_money,
                          concert.minPrice != null && concert.maxPrice != null
                              ? '\$${concert.minPrice!.toStringAsFixed(2)} - \$${concert.maxPrice!.toStringAsFixed(2)}'
                              : concert.minPrice != null
                                  ? 'From \$${concert.minPrice!.toStringAsFixed(2)}'
                                  : 'Up to \$${concert.maxPrice!.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  if (concert.minPrice != null || concert.maxPrice != null)
                    const SizedBox(height: 16),
                  if (concert.genres.isNotEmpty)
                    _buildInfoSection(
                      'Genres',
                      [
                        Wrap(
                          spacing: 8,
                          children: concert.genres
                              .map((genre) => Chip(
                                    label: Text(genre),
                                    backgroundColor:
                                        Colors.purpleAccent.withOpacity(0.2),
                                    labelStyle: const TextStyle(
                                        color: Colors.purpleAccent),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  if (concert.genres.isNotEmpty) const SizedBox(height: 16),
                  if (concert.description != null)
                    _buildInfoSection(
                      'About',
                      [
                        Text(
                          concert.description!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  if (concert.description != null) const SizedBox(height: 16),
                  if (concert.ageRestriction != null)
                    _buildInfoSection(
                      'Age Restriction',
                      [
                        _buildInfoRow(
                          Icons.person,
                          '${concert.ageRestriction}+ years',
                        ),
                      ],
                    ),
                  if (concert.ageRestriction != null)
                    const SizedBox(height: 16),
                  if (concert.isSoldOut)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Sold Out',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (concert.isSoldOut) const SizedBox(height: 16),
                  if (concert.ticketUrl != null)
                    ElevatedButton(
                      onPressed: _launchTicketUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purpleAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Get Tickets'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 16, color: Colors.grey[400]),
            ),
          ),
        ],
      ),
    );
  }
}
