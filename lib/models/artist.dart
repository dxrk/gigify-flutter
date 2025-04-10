class Artist {
  final String id;
  final String name;
  final int popularity;
  final List<String> genres;
  final String? imageUrl;
  final String? spotifyUrl;

  Artist({
    required this.id,
    required this.name,
    required this.popularity,
    required this.genres,
    this.imageUrl,
    this.spotifyUrl,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    final List<String> artistGenres = [];
    if (json.containsKey('genres')) {
      final genresList = json['genres'] as List<dynamic>;
      artistGenres.addAll(genresList.map((g) => g.toString()));
    }

    return Artist(
      id: json['id'] as String,
      name: json['name'] as String,
      popularity: json['popularity'] as int? ?? 0,
      genres: artistGenres,
      imageUrl: json.containsKey('images') &&
              (json['images'] as List<dynamic>).isNotEmpty
          ? (json['images'] as List<dynamic>)[0]['url'] as String
          : null,
      spotifyUrl: json['external_urls']?['spotify'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'popularity': popularity,
      'genres': genres,
      'imageUrl': imageUrl,
      'spotifyUrl': spotifyUrl,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Artist && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Artist(id: $id, name: $name)';
}
