class Venue {
  final String id;
  final String name;
  final String? city;
  final String? state;
  final String? country;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final int? capacity;
  final String? websiteUrl;

  Venue({
    required this.id,
    required this.name,
    this.city,
    this.state,
    this.country,
    this.address,
    this.latitude,
    this.longitude,
    this.imageUrl,
    this.capacity,
    this.websiteUrl,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    String? city;
    String? state;
    String? country;
    String? address;

    if (json.containsKey('city')) {
      city = json['city']['name'] as String?;
    }

    if (json.containsKey('state')) {
      state = json['state']['name'] as String?;
    }

    if (json.containsKey('country')) {
      country = json['country']['name'] as String?;
    }

    if (json.containsKey('address')) {
      address = json['address']['line1'] as String?;
    }

    double? latitude;
    double? longitude;
    if (json.containsKey('location')) {
      latitude = json['location'].containsKey('latitude')
          ? double.tryParse(json['location']['latitude'] as String)
          : null;
      longitude = json['location'].containsKey('longitude')
          ? double.tryParse(json['location']['longitude'] as String)
          : null;
    }

    String? imageUrl;
    if (json.containsKey('images') &&
        (json['images'] as List<dynamic>).isNotEmpty) {
      imageUrl = (json['images'] as List<dynamic>)[0]['url'] as String;
    }

    int? capacity;
    if (json.containsKey('capacity')) {
      capacity = int.tryParse(json['capacity'] as String? ?? '');
    }

    String? websiteUrl;
    if (json.containsKey('url')) {
      websiteUrl = json['url'] as String;
    }

    return Venue(
      id: json['id'] as String,
      name: json['name'] as String,
      city: city,
      state: state,
      country: country,
      address: address,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
      capacity: capacity,
      websiteUrl: websiteUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'state': state,
      'country': country,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'capacity': capacity,
      'websiteUrl': websiteUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Venue && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Venue(id: $id, name: $name)';
}
