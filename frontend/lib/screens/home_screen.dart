import 'package:flutter/material.dart';
import '../models/movie.dart';
import '../widgets/featured_banner.dart';
import '../widgets/movie_carousel.dart';
import '../themes/app_theme.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'movie_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Movie> _featuredMovies = [];
  List<Movie> _popularMovies = [];
  List<Movie> _trendingMovies = [];
  List<Movie> _topRatedMovies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMovies();
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

