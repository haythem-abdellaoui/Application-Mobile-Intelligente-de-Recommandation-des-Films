import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../widgets/featured_banner.dart';
import '../widgets/movie_carousel.dart';
import '../themes/app_theme.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'movie_details_screen.dart';
import '../services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  final String? username;
  const HomeScreen({super.key, this.username});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Movie> _featuredMovies = [];
  List<Movie> _popularMovies = [];
  List<Movie> _trendingMovies = [];
  List<Movie> _topRatedMovies = [];
  List<Movie> _genreClusteredMovies = [];
  List<Movie> _predictedMovies = [];
  List<Movie> _predictedLikeDislikeMovies = [];
  List<Movie> _clusterBasedRatingsMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _sendUsernameToApi();
    if (widget.username != null) {
      fetchGenreClusteredMovies(widget.username!);
    }
  }

  Future<void> fetchGenreClusteredMovies(String username) async {
    final baseUrl = dotenv.env['API_BASE_URL'];
    final url = Uri.parse('$baseUrl/send-username');
    final body = {"username": username};

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['recommended_movies'] != null) {
          setState(() {
            _genreClusteredMovies = (data['recommended_movies'] as List)
                .map((json) => Movie.fromJson(json))
                .toList();
          });
        }
      } else {
        print("❌ Failed to fetch movies: ${response.body}");
      }
    } catch (e) {
      print("❌ Error fetching movies: $e");
    }
  }

  Future<void> _sendUsernameToApi() async {
    String? username = widget.username;

    if (username == null) {
      // Try to get from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('loggedInUserId');
      if (userId != null) {
        final db = DatabaseHelper();
        final user = await db.getUserById(userId);
        username = user?.username;
      }
    }

    if (username != null) {
      // Fetch recommendations
      fetchGenreClusteredMovies(username);
      
      try {
        await ApiService(baseUrl: dotenv.env['API_BASE_URL']!).sendUsernameToApi(username);
        
        // Fetch predicted movies
        final predictedMovies = await ApiService(baseUrl: dotenv.env['API_BASE_URL']!).fetchPredictedMoviesRatings(username);
        if (mounted) {
          setState(() {
            _predictedMovies = predictedMovies;
          });
          print ('✅ Predicted movies fetched successfully: ${predictedMovies.length} movies');
        }
        
        // Fetch predicted movies (Like vs Dislike)
        final predictedLikeDislikeMovies = await ApiService(baseUrl: dotenv.env['API_BASE_URL']!).fetchPredictedMoviesLikeVsDislike(username);
        if (mounted) {
          setState(() {
            _predictedMovies = predictedMovies;
            _predictedLikeDislikeMovies = predictedLikeDislikeMovies;
          });
          print ('✅ Predicted Like/Dislike movies fetched successfully: ${predictedLikeDislikeMovies.length} movies');
        }

        // Fetch cluster based ratings movies
        final clusterBasedRatingsMovies = await ApiService(baseUrl: dotenv.env['API_BASE_URL']!).getClusterBasedOnRatings(username);
        if (mounted) {
          setState(() {
            _predictedMovies = predictedMovies;
            _predictedLikeDislikeMovies = predictedLikeDislikeMovies;
            _clusterBasedRatingsMovies = clusterBasedRatingsMovies;
          });
          print ('✅ Cluster based ratings movies fetched successfully: ${clusterBasedRatingsMovies.length} movies');
        }
      } catch (e) {
        print("Error sending username to API: $e");
      }
    }
  }

  Future<void> _loadMovies() async {
    print('🏠 [HomeScreen] Loading movies...');
    try {
      final movies = await Movie.getDummyMovies();
      print('🏠 [HomeScreen] Loaded ${movies.length} movies');
      setState(() {
        _featuredMovies = movies.take(1).toList();
        _popularMovies = movies.take(20).toList(); // Limit for performance
        _trendingMovies = movies.skip(20).take(20).toList();
        _topRatedMovies = movies.take(20).toList();
        _isLoading = false;
      });
      print('🏠 [HomeScreen] State updated, featured: ${_featuredMovies.length}, popular: ${_popularMovies.length}');
    } catch (e, stackTrace) {
      print('❌ [HomeScreen] Error loading movies: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildHomeContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_featuredMovies.isEmpty) {
      return const Center(
        child: Text('No movies available'),
      );
    }

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          floating: true,
          pinned: true,
          backgroundColor: AppTheme.black,
          elevation: 0,
          title: const Text('MovieRec'),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {},
            ),
          ],
        ),
        // Featured Banner
        SliverToBoxAdapter(
          child: FeaturedBanner(
            movie: _featuredMovies[0],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailsScreen(movie: _featuredMovies[0]),
                ),
              );
            },
          ),
        ),
        // Movie Carousels
        SliverToBoxAdapter(
          child: MovieCarousel(
            title: 'Popular Now',
            movies: _popularMovies,
            onSeeAll: () {},
            onMovieTap: (movie) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailsScreen(movie: movie),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: MovieCarousel(
            title: 'Trending',
            movies: _trendingMovies,
            onSeeAll: () {},
            onMovieTap: (movie) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailsScreen(movie: movie),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: MovieCarousel(
            title: 'Top Rated',
            movies: _topRatedMovies,
            onSeeAll: () {},
            onMovieTap: (movie) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailsScreen(movie: movie),
                ),
              );
            },
          ),
        ),
        SliverToBoxAdapter(
          child: MovieCarousel(
            title: 'Recommended For You',
            movies: _popularMovies,
            onSeeAll: () {},
            onMovieTap: (movie) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailsScreen(movie: movie),
                ),
              );
            },
          ),
        ),

        SliverToBoxAdapter(
          child: MovieCarousel(
            title: 'Your Genre Match Picks',
            movies: _genreClusteredMovies,
            onSeeAll: () {},
            onMovieTap: (movie) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieDetailsScreen(movie: movie),
                ),
              );
            },
          ),
        ),
        
        
          SliverToBoxAdapter(
            child: MovieCarousel(
              title: 'Movies You’re Likely to Enjoy',
              movies: _predictedMovies,
              onSeeAll: () {},
              onMovieTap: (movie) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(movie: movie),
                  ),
                );
              },
            ),
          ),
        
          SliverToBoxAdapter(
            child: MovieCarousel(
              title: 'Top Picks You’ll Love',
              movies: _predictedLikeDislikeMovies,
              onSeeAll: () {},
              onMovieTap: (movie) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(movie: movie),
                  ),
                );
              },
            ),
          ),
        
        if (_clusterBasedRatingsMovies.isNotEmpty)
          SliverToBoxAdapter(
            child: MovieCarousel(
              title: 'Loved by Users Like You',
              movies: _clusterBasedRatingsMovies,
              onSeeAll: () {},
              onMovieTap: (movie) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MovieDetailsScreen(movie: movie),
                  ),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const SearchScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppTheme.black,
        selectedItemColor: AppTheme.primaryRed,
        unselectedItemColor: AppTheme.lightGray,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

