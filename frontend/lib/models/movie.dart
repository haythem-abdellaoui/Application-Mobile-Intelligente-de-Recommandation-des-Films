import '../database/db_helper.dart';

class Movie {
  final String movieId;
  final String title;
  final List<String> genres;
  final double? rating;
  final int? year;
  final String? description;
  final String? posterUrl;

  // Getter for convenience (using id instead of movieId)
  String get id => movieId;

  Movie({
    required this.movieId,
    required this.title,
    required this.genres,
    this.rating,
    this.year,
    this.description,
    this.posterUrl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      movieId: json['movieId']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      genres: json['genres'] is List 
          ? List<String>.from(json['genres']) 
          : (json['genres'] as String?)?.split(',') ?? [],
      rating: (json['rating'] as num?)?.toDouble(),
      year: json['year'] as int?,
      description: json['description'],
      posterUrl: json['posterUrl'],
    );
  }

  static Future<List<Movie>> getDummyMovies() async {
    try {
      print('🔍 [Movie] Fetching movies from database...');
      final db = await DatabaseHelper().database;
      final List<Map<String, dynamic>> maps = await db.query('movies');
      print('📊 [Movie] Found ${maps.length} movies in database');

      final movies = List.generate(maps.length, (i) {
        return Movie(
          movieId: maps[i]['id'] as String,
          title: maps[i]['title'] as String,
          genres: maps[i]['genres'] != null && (maps[i]['genres'] as String).isNotEmpty
              ? (maps[i]['genres'] as String).split(',')
              : [],
          rating: maps[i]['rating'] != null ? (maps[i]['rating'] as double) : null,
          year: maps[i]['year'] != null ? (maps[i]['year'] as int) : null,
          description: maps[i]['description'] as String?,
          posterUrl: maps[i]['posterUrl'] as String?,
        );
      });
      
      print('✅ [Movie] Returning ${movies.length} movies');
      return movies;
    } catch (e, stackTrace) {
      print('❌ [Movie] Error fetching movies from database: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
}
