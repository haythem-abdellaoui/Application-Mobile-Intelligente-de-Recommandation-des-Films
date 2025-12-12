import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/api_service.dart';
import '../models/movie.dart';
import '../widgets/movie_card.dart';
import '../themes/app_theme.dart';

class MovieDetailsScreen extends StatefulWidget {
  final Movie movie;

  const MovieDetailsScreen({
    super.key,
    required this.movie,
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  double _rating = 3.0;

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
              background: widget.movie.posterUrl != null &&
                      widget.movie.posterUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: widget.movie.posterUrl!,
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
                              widget.movie.title,
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
                              widget.movie.rating?.toStringAsFixed(1) ?? 'N/A',
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
                    children: widget.movie.genres.map((genre) {
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
                  
                  // Rating Slider
                  Text(
                    'Rate this movie',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.darkGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _rating.toInt().toString(),
                          style: const TextStyle(
                            color: AppTheme.primaryRed,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Slider(
                          value: _rating,
                          min: 1,
                          max: 5,
                          divisions: 4,
                          activeColor: AppTheme.primaryRed,
                          inactiveColor: AppTheme.mediumGray,
                          label: _rating.round().toString(),
                          onChanged: (double value) {
                            setState(() {
                              _rating = value;
                            });
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1', style: TextStyle(color: Colors.grey)),
                              Text('5', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          final prefs = await SharedPreferences.getInstance();
                          final username = prefs.getString('loggedInUsername');

                          if (username != null) {
                            // Initialize ApiService
                            final apiService = ApiService(
                                baseUrl: dotenv.env['API_BASE_URL'] ?? '');
                            
                            await apiService.addRating(
                              username, 
                              int.parse(widget.movie.id), 
                              _rating
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Rating submitted: ${_rating.toInt()}',
                                  ),
                                  backgroundColor: AppTheme.primaryRed,
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please log in to rate movies'),
                                  backgroundColor: AppTheme.mediumGray,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error submitting rating: $e'),
                                backgroundColor: AppTheme.mediumGray,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryRed,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Rating',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                      final movies = snapshot.data!.where((m) => m.id != widget.movie.id).toList();
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
                      final movies = snapshot.data!.where((m) => m.id != widget.movie.id).toList();
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

