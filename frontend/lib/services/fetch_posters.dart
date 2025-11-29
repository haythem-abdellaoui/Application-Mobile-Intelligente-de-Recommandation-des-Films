import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../database/db_helper.dart';
import '../models/movie.dart';

class PosterFetcher {
  static String get apiKey => dotenv.env['TMDB_API_KEY'] ?? '';

  static Future<Map<String, int>> fetchAndSavePosters(
    List<Movie> movies, {
    Function(int current, int total)? onProgress,
  }) async {
    if (apiKey.isEmpty) {
      print('⚠️ [PosterFetcher] TMDB_API_KEY not found in .env file');
      return {'success': 0, 'failed': 0, 'skipped': 0};
    }

    print('🖼️ [PosterFetcher] Starting to fetch posters for ${movies.length} movies...');
    final db = await DatabaseHelper().database;
    int successCount = 0;
    int failCount = 0;
    int skippedCount = 0;
    int totalProcessed = 0;

    for (var movie in movies) {
      totalProcessed++;
      
      // Report progress
      if (onProgress != null) {
        onProgress(totalProcessed, movies.length);
      }
      // Skip if poster already exists
      final existing = await db.query(
        'movies',
        columns: ['posterUrl'],
        where: 'id = ?',
        whereArgs: [movie.movieId],
      );
      
      if (existing.isNotEmpty && existing[0]['posterUrl'] != null && (existing[0]['posterUrl'] as String).isNotEmpty) {
        skippedCount++;
        continue; // Skip if poster already exists
      }

      try {
        // Clean title for better search results (remove year if present)
        String cleanTitle = movie.title;
        final yearMatch = RegExp(r'\s*\(\d{4}\)\s*$');
        cleanTitle = cleanTitle.replaceAll(yearMatch, '').trim();
        
        final query = Uri.encodeComponent(cleanTitle);
        final url = 'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=$query';

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          if (data['results'] != null && (data['results'] as List).isNotEmpty) {
            final firstResult = (data['results'] as List)[0] as Map<String, dynamic>;
            final posterPath = firstResult['poster_path'] as String?;
            
            if (posterPath != null && posterPath.isNotEmpty) {
              final posterUrl = 'https://image.tmdb.org/t/p/w500$posterPath';

              await db.update(
                'movies',
                {'posterUrl': posterUrl},
                where: 'id = ?',
                whereArgs: [movie.movieId],
              );
              successCount++;
            }
          }
        } else {
          failCount++;
        }
      } catch (e) {
        failCount++;
        print('❌ [PosterFetcher] Error fetching poster for "${movie.title}": $e');
      }
      
      // Add small delay to avoid rate limiting (TMDB allows 40 requests per 10 seconds)
      await Future.delayed(const Duration(milliseconds: 250));
    }

    print('✅ [PosterFetcher] Completed: $successCount successful, $failCount failed, $skippedCount skipped');
    return {
      'success': successCount,
      'failed': failCount,
      'skipped': skippedCount,
    };
  }
}