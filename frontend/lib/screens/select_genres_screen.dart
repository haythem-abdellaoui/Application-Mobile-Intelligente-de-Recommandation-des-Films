import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import 'home_screen.dart';
import '../services/api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SelectGenresScreen extends StatefulWidget {
  final String userId;
  const SelectGenresScreen({super.key, required this.userId});

  @override
  State<SelectGenresScreen> createState() => _SelectGenresScreenState();
}

class _SelectGenresScreenState extends State<SelectGenresScreen> {
  final List<String> _genres = [
    'Action',
    'Comedy',
    'Drama',
    'Sci-Fi',
    'Thriller',
    'Romance',
    'Adventure',
    'Crime'
  ];

  late List<bool> _selectedGenres;

  @override
  void initState() {
    super.initState();
    _selectedGenres = List<bool>.filled(_genres.length, false);
  }

  Future<void> _saveGenres() async {
    // Save genre preferences in the database
    final db = DatabaseHelper();
    final user = await db.getUserById(widget.userId);
    if (user != null) {
      user.preferredGenres = _selectedGenres.map((e) => e ? 1 : 0).toList();
      await db.updateUserGenres(user.userId, user.preferredGenres!);

      // Update on server using username
      await ApiService(baseUrl: dotenv.env['API_BASE_URL']!)
          .updateUserGenresOnServerByUsername(user.username, user.preferredGenres!);
    }

    // Navigate to home screen
    if (mounted) {
        await ApiService(baseUrl: dotenv.env['API_BASE_URL']!).sendGenresToApi(widget.userId, _selectedGenres.map((e) => e ? 1 : 0).toList());

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(username: user?.username)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        backgroundColor: AppTheme.black,
        elevation: 0,
        title: const Text('Select Your Favorite Genres'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Choose your preferred genres:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_genres.length, (index) {
                  return ChoiceChip(
                    label: Text(_genres[index]),
                    selected: _selectedGenres[index],
                    selectedColor: AppTheme.primaryRed,
                    backgroundColor: AppTheme.mediumGray,
                    labelStyle: const TextStyle(color: AppTheme.white),
                    onSelected: (selected) {
                      setState(() {
                        _selectedGenres[index] = selected;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _selectedGenres.contains(true) ? _saveGenres : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
