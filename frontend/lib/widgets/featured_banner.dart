import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/movie.dart';
import '../themes/app_theme.dart';

class FeaturedBanner extends StatelessWidget {
  final Movie movie;
  final VoidCallback? onTap;

  const FeaturedBanner({
    super.key,
    required this.movie,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 400,
        width: double.infinity,
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
        child: Stack(
          children: [
            // Background poster or placeholder
            movie.posterUrl != null && movie.posterUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: movie.posterUrl!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
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
                          size: 150,
                          color: AppTheme.primaryRed.withOpacity(0.2),
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
                        size: 150,
                        color: AppTheme.primaryRed.withOpacity(0.2),
                      ),
                    ),
                  ),
            // Content overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppTheme.black,
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      movie.title,
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (movie.rating != null) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 16,
                                color: AppTheme.primaryRed,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${movie.rating}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ],
                        if (movie.genres.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          ...movie.genres.take(2).map((genre) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryRed,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  genre,
                                  style: const TextStyle(
                                    color: AppTheme.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            )),
                        ],
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.info_outline),
                          label: const Text('More Info'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.white,
                            side: const BorderSide(color: AppTheme.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

