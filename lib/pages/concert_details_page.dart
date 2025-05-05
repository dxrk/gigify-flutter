import 'package:flutter/material.dart';
import 'package:nextbigthing/models/concert.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nextbigthing/services/favorites/favorites_service.dart';

class ConcertDetailsPage extends StatefulWidget {
  final Concert concert;

  const ConcertDetailsPage({super.key, required this.concert});

  static const routeName = '/concert-details';

  static Route route(Concert concert) {
    return MaterialPageRoute(
      settings: const RouteSettings(name: routeName),
      builder: (context) => ConcertDetailsPage(concert: concert),
    );
  }

  @override
  State<ConcertDetailsPage> createState() => _ConcertDetailsPageState();
}

class _ConcertDetailsPageState extends State<ConcertDetailsPage> {
  Future<void> _launchTicketUrl() async {
    if (widget.concert.ticketUrl != null) {
      final uri = Uri.parse(widget.concert.ticketUrl!);
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            actions: [
              FutureBuilder<bool>(
                future: FavoritesService.initialize().then(
                  (service) => service.isConcertFavorited(widget.concert.id),
                ),
                builder: (context, snapshot) {
                  final isFavorited = snapshot.data ?? false;
                  return IconButton(
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? Colors.red : Colors.white,
                    ),
                    onPressed: () async {
                      final service = await FavoritesService.initialize();
                      await service.toggleFavoriteConcert(widget.concert);
                      setState(() {});
                    },
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: FutureBuilder<ImageProvider>(
                future: widget.concert.getImageProvider(),
                builder: (context, snapshot) {
                  return Container(
                    decoration: BoxDecoration(
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
                    widget.concert.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.concert.artist.name,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.purpleAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection('Date & Time', [
                    _buildInfoRow(
                      Icons.calendar_today,
                      DateFormat(
                        'EEEE, MMMM d, y',
                      ).format(widget.concert.startDateTime),
                    ),
                    _buildInfoRow(
                      Icons.access_time,
                      DateFormat('h:mm a').format(widget.concert.startDateTime),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _buildInfoSection('Venue', [
                    _buildInfoRow(Icons.location_on, widget.concert.venue),
                  ]),
                  const SizedBox(height: 16),
                  if (widget.concert.minPrice != null ||
                      widget.concert.maxPrice != null)
                    _buildInfoSection('Price Range', [
                      _buildInfoRow(
                        Icons.attach_money,
                        widget.concert.minPrice != null &&
                                widget.concert.maxPrice != null
                            ? '\$${widget.concert.minPrice!.toStringAsFixed(2)} - \$${widget.concert.maxPrice!.toStringAsFixed(2)}'
                            : widget.concert.minPrice != null
                                ? 'From \$${widget.concert.minPrice!.toStringAsFixed(2)}'
                                : 'Up to \$${widget.concert.maxPrice!.toStringAsFixed(2)}',
                      ),
                    ]),
                  if (widget.concert.minPrice != null ||
                      widget.concert.maxPrice != null)
                    const SizedBox(height: 16),
                  if (widget.concert.genres.isNotEmpty)
                    _buildInfoSection('Genres', [
                      Wrap(
                        spacing: 8,
                        children: widget.concert.genres
                            .map(
                              (genre) => Chip(
                                label: Text(genre),
                                backgroundColor:
                                    Colors.purpleAccent.withValues(alpha: 0.2),
                                labelStyle: const TextStyle(
                                  color: Colors.purpleAccent,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ]),
                  if (widget.concert.genres.isNotEmpty)
                    const SizedBox(height: 16),
                  if (widget.concert.description != null)
                    _buildInfoSection('About', [
                      Text(
                        widget.concert.description!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ]),
                  if (widget.concert.description != null)
                    const SizedBox(height: 16),
                  if (widget.concert.ageRestriction != null)
                    _buildInfoSection('Age Restriction', [
                      _buildInfoRow(
                        Icons.person,
                        '${widget.concert.ageRestriction}+ years',
                      ),
                    ]),
                  if (widget.concert.ageRestriction != null)
                    const SizedBox(height: 16),
                  if (widget.concert.isSoldOut)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
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
                  if (widget.concert.isSoldOut) const SizedBox(height: 16),
                  if (widget.concert.ticketUrl != null)
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
