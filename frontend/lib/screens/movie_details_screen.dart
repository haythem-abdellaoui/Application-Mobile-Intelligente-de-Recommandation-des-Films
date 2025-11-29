import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import '../themes/app_theme.dart';

class MovieDetailsScreen extends StatelessWidget {
  final Movie movie;

  const MovieDetailsScreen({
    super.key,
    required this.movie,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: CustomScrollView(
        slivers: [
          // App Bar with back button
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.black,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: movie.posterUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.primaryRed.withOpacity(0.3),
                              AppTheme.black,
                            ],
                          ),
                        ),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryRed,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.primaryRed.withOpacity(0.3),
                              AppTheme.black,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.movie,
                            size: 120,
                            color: AppTheme.primaryRed.withOpacity(0.5),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.primaryRed.withOpacity(0.3),
                            AppTheme.black,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.movie,
                          size: 120,
                          color: AppTheme.primaryRed.withOpacity(0.5),
                        ),
                      ),
                    ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              movie.title,
                              style: Theme.of(context).textTheme.displaySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          shape: BoxShape.circle,
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.star,
                              color: AppTheme.white,
                              size: 20,
                            ),
                            Text(
                              movie.rating?.toStringAsFixed(1) ?? 'N/A',
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Genres
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: movie.genres.map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: AppTheme.white,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Liked!'),
                                backgroundColor: AppTheme.primaryRed,
                              ),
                            );
                          },
                          icon: const Icon(Icons.thumb_up),
                          label: const Text('Like'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Disliked!'),
                                backgroundColor: AppTheme.mediumGray,
                              ),
                            );
                          },
                          icon: const Icon(Icons.thumb_down),
                          label: const Text('Dislike'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.white,
                            side: const BorderSide(color: AppTheme.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to Watchlist!'),
                            backgroundColor: AppTheme.primaryRed,
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add to Watchlist'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.white,
                        side: const BorderSide(color: AppTheme.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Similar Movies
                  Text(
                    'Similar Movies',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Movie>>(
                    future: Movie.getDummyMovies(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                      }
                      final movies = snapshot.data!.where((m) => m.id != movie.id).toList();
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            final similarMovie = movies[index];
                            return MovieCard(
                              movie: similarMovie,
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        MovieDetailsScreen(movie: similarMovie),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  // Recommended Movies
                  Text(
                    'Recommended For You',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Movie>>(
                    future: Movie.getDummyMovies(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                      }
                      final movies = snapshot.data!.where((m) => m.id != movie.id).toList();
                      return SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: movies.length,
                          itemBuilder: (context, index) {
                            final recommendedMovie = movies[index];
                            return MovieCard(
                              movie: recommendedMovie,
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MovieDetailsScreen(
                                      movie: recommendedMovie,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

