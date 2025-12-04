// lib/services/data_loader.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/movie.dart';
import '../models/user.dart';
import '../database/db_helper.dart';

class DataLoader {
  static Future<List<Movie>> loadMovies() async {
    try {
      print('📖 [DataLoader] Reading assets/movies.dat...');
      final String moviesData = await rootBundle.loadString('assets/movies.dat');
      print('✅ [DataLoader] File read successfully, length: ${moviesData.length}');
      
      final List<Movie> movies = [];
      int lineCount = 0;
      int skippedCount = 0;

      for (var line in LineSplitter.split(moviesData)) {
        lineCount++;
        if (line.trim().isEmpty) continue;
        final parts = line.split('|'); // split by | now
        
        if (parts.length < 2) {
          skippedCount++;
          continue;
        }

        final id = parts[0].trim();
        final title = parts[1].trim();
        if (id.isEmpty || title.isEmpty) {
          skippedCount++;
          continue;
        }

        final genres = parts.length > 2 && parts[2].isNotEmpty
            ? parts[2].replaceAll('"', '').split('|').map((g) => g.trim()).where((g) => g.isNotEmpty).toList()
            : <String>[];

        movies.add(Movie(
          movieId: id,
          title: title,
          genres: genres,
        ));
      }

      print('📊 [DataLoader] Parsed $lineCount lines, created ${movies.length} movies, skipped $skippedCount');

      if (movies.isNotEmpty) {
        print('💾 [DataLoader] Saving ${movies.length} movies to database...');
        await DatabaseHelper().insertMovies(movies);
        print('✅ [DataLoader] Movies saved to database');
      } else {
        print('⚠️ [DataLoader] No movies to save!');
      }

      return movies;
    } catch (e, stackTrace) {
      print('❌ [DataLoader] Error loading movies: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<void> loadRatings() async {
    try {
      final String ratingsData = await rootBundle.loadString('assets/ratings.dat');
      final db = await DatabaseHelper().database;

      final Map<String, List<double>> ratingsMap = {};

      for (var line in LineSplitter.split(ratingsData)) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|'); // split by | now
        if (parts.length < 3) continue;

        final movieId = parts[1].trim();
        final rating = double.tryParse(parts[2].trim());
        if (rating != null && movieId.isNotEmpty) {
          ratingsMap[movieId] ??= [];
          ratingsMap[movieId]!.add(rating);
        }
      }

      for (var entry in ratingsMap.entries) {
        final movieId = entry.key;
        final ratingsList = entry.value;
        if (ratingsList.isEmpty) continue;
        
        final avgRating = ratingsList.reduce((a, b) => a + b) / ratingsList.length;

        await db.update(
          'movies',
          {'rating': avgRating},
          where: 'id = ?',
          whereArgs: [movieId],
        );
      }
    } catch (e) {
      debugPrint('Error loading ratings: $e');
    }
  }

  static Future<List<User>> loadUsers() async {
    try {
      final String usersData = await rootBundle.loadString('assets/users.dat');
      final List<User> users = [];

      for (var line in LineSplitter.split(usersData)) {
        if (line.trim().isEmpty) continue;
        final parts = line.split('|');
        if (parts.length < 1) continue; // only userId is mandatory

      final userId = parts[0].trim();

      users.add(User(
        userId: userId,
        username: parts.length > 1 ? parts[1].trim() : 'user_$userId',
        password: parts.length > 2 ? parts[2].trim() : 'default_password',
        gender: parts.length > 3 ? parts[3].trim() : null,
        age: parts.length > 4 ? int.tryParse(parts[4].trim()) : null,
        occupation: parts.length > 5 ? int.tryParse(parts[5].trim()) : null,
        zipCode: parts.length > 6 ? parts[6].trim() : null,
        preferredGenres: parts.length > 7 
            ? parts[7].split(',').map((g) => int.tryParse(g) ?? 0).toList()
            : null,
      ));
      }

      print('📊 [DataLoader] Loaded ${users.length} users from dataset');

      if (users.isNotEmpty) {
      print('💾 [DataLoader] Saving users to database...');
      await DatabaseHelper().insertUsersBatch(users);
      print('✅ [DataLoader] Users saved to database');
      }

      return users;

    } catch (e) {
      print('❌ [DataLoader] Error loading users: $e');
      return [];
    }
  }

}
