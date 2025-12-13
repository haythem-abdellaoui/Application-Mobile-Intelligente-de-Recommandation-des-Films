import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/movie.dart';
import '../themes/app_theme.dart';
import '../widgets/movie_card.dart';
import 'settings_screen.dart';
import 'movie_details_screen.dart';
import '../database/db_helper.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<User?> _getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('loggedInUserId');
    if (userId == null) return null;
    return await DatabaseHelper().getUserById(userId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: _getLoggedInUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Scaffold(
            body: Center(child: Text('User not found')),
          );
        }

        final user = snapshot.data!;

        return Scaffold(
          backgroundColor: AppTheme.black,
          appBar: AppBar(
            title: const Text('Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: CustomScrollView(
            slivers: [
              // User Info Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 50,
                          color: AppTheme.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user.username,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              // Watchlist Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Watchlist',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<List<Movie>>(
                  future: Movie.getDummyMovies(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final watchlist = snapshot.data!.take(4).toList();
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: watchlist.length,
                        itemBuilder: (context, index) {
                          return MovieCard(
                            movie: watchlist[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MovieDetailsScreen(
                                      movie: watchlist[index]),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              // History Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recently Viewed',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: FutureBuilder<List<Movie>>(
                  future: Movie.getDummyMovies(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    final history = snapshot.data!.skip(1).take(4).toList();
                    return SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: history.length,
                        itemBuilder: (context, index) {
                          return MovieCard(
                            movie: history[index],
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MovieDetailsScreen(movie: history[index]),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMLFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryRed),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
