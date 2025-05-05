class Genre {
  final String id;
  final String name;
  final String? parentGenre;

  Genre({required this.id, required this.name, this.parentGenre});

  factory Genre.fromJson(Map<String, dynamic> json) {
    return Genre(
      id: json['id'] as String,
      name: json['name'] as String,
      parentGenre: json['parentGenre'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'parentGenre': parentGenre};
  }

  static Map<String, List<String>> getRelatedGenres() {
    return {
      'rock': [
        'alternative rock',
        'hard rock',
        'indie rock',
        'classic rock',
        'punk rock',
      ],
      'pop': ['pop rock', 'dance pop', 'synthpop', 'electropop', 'k-pop'],
      'hip hop': ['rap', 'trap', 'r&b', 'urban', 'grime'],
      'electronic': [
        'edm',
        'techno',
        'house',
        'trance',
        'dubstep',
        'drum and bass',
      ],
      'metal': [
        'heavy metal',
        'death metal',
        'black metal',
        'thrash metal',
        'metalcore',
      ],
      'jazz': ['bebop', 'smooth jazz', 'fusion', 'big band', 'swing'],
      'country': [
        'country rock',
        'contemporary country',
        'americana',
        'bluegrass',
        'folk',
      ],
      'classical': [
        'orchestra',
        'chamber music',
        'opera',
        'symphony',
        'baroque',
      ],
      'reggae': ['dancehall', 'dub', 'ska', 'roots reggae'],
      'latin': ['salsa', 'reggaeton', 'bachata', 'latin pop', 'merengue'],
      'folk': [
        'singer-songwriter',
        'acoustic',
        'indie folk',
        'traditional folk',
      ],
      'blues': [
        'rhythm and blues',
        'chicago blues',
        'delta blues',
        'electric blues',
      ],
      'funk': ['soul', 'disco', 'r&b', 'motown'],
      'punk': ['hardcore punk', 'post-punk', 'pop punk', 'ska punk'],
      'indie': ['indie pop', 'indie rock', 'indie folk', 'alternative'],
    };
  }

  static bool areRelated(String genre1, String genre2) {
    final g1 = genre1.toLowerCase().trim();
    final g2 = genre2.toLowerCase().trim();

    if (g1 == g2) return true;

    if (g1.contains(g2) || g2.contains(g1)) return true;

    final relatedGenres = getRelatedGenres();

    for (final entry in relatedGenres.entries) {
      final mainGenre = entry.key;
      final relatedList = entry.value;

      final bool g1InGroup = mainGenre == g1 || relatedList.contains(g1);
      final bool g2InGroup = mainGenre == g2 || relatedList.contains(g2);

      if (g1InGroup && g2InGroup) return true;
    }

    return false;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Genre && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
