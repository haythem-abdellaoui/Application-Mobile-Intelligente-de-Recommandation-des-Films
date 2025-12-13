import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../themes/app_theme.dart';
import '../services/fetch_posters.dart';
import '../models/movie.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.black,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Account'),
          _buildSettingTile(
            icon: Icons.person,
            title: 'Edit Profile',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Edit Profile - Coming Soon'),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.email,
            title: 'Change Email',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change Email - Coming Soon'),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.lock,
            title: 'Change Password',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Change Password - Coming Soon'),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Preferences Section
          _buildSectionHeader('Preferences'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications, color: AppTheme.white),
            title: const Text('Notifications'),
            subtitle: const Text('Enable push notifications'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode, color: AppTheme.white),
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.language, color: AppTheme.white),
            title: const Text('Language'),
            subtitle: Text(_selectedLanguage),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              _showLanguageDialog();
            },
          ),
          const SizedBox(height: 16),
          // Data Section
          _buildSectionHeader('Data'),
          _buildSettingTile(
            icon: Icons.image,
            title: 'Fetch Movie Posters',
            subtitle: 'Download posters from TMDB API',
            onTap: () async {
              _showPosterFetchDialog();
            },
          ),
          const SizedBox(height: 16),
          // About Section
          _buildSectionHeader('About'),
          _buildSettingTile(
            icon: Icons.info,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          _buildSettingTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy Policy - Coming Soon'),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            },
          ),
          _buildSettingTile(
            icon: Icons.description,
            title: 'Terms of Service',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Terms of Service - Coming Soon'),
                  backgroundColor: AppTheme.primaryRed,
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                // Clear user session
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                if (context.mounted) {
                  // Navigate to Login Screen and remove all previous routes
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryRed,
                side: const BorderSide(color: AppTheme.primaryRed),
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryRed,
            ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.white),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : null,
      onTap: onTap,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkGray,
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLanguageOption('English'),
            _buildLanguageOption('French'),
            _buildLanguageOption('Spanish'),
            _buildLanguageOption('Arabic'),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption(String language) {
    return ListTile(
      title: Text(language),
      trailing: _selectedLanguage == language
          ? const Icon(Icons.check, color: AppTheme.primaryRed)
          : null,
      onTap: () {
        setState(() {
          _selectedLanguage = language;
        });
        Navigator.pop(context);
      },
    );
  }

  void _showPosterFetchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkGray,
        title: const Text('Fetch Movie Posters'),
        content: const Text(
          'This will fetch movie posters from TMDB API. This may take a while. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _fetchPosters();
            },
            child: const Text('Fetch'),
          ),
        ],
      ),
    );
  }

  void _fetchPosters() async {
    // Create a controller for the progress dialog
    final progressNotifier = ValueNotifier<Map<String, int>>({
      'current': 0,
      'total': 0,
    });

    // Show loading dialog with progress
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ValueListenableBuilder<Map<String, int>>(
        valueListenable: progressNotifier,
        builder: (context, progress, _) {
          final current = progress['current'] ?? 0;
          final total = progress['total'] ?? 0;
          final progressValue = total > 0 ? current / total : 0.0;

          return AlertDialog(
            backgroundColor: AppTheme.darkGray,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Fetching posters...'),
                if (total > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    '$current / $total',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: AppTheme.mediumGray,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryRed),
                    minHeight: 6,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progressValue * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 12, color: AppTheme.lightGray),
                  ),
                ],
                const SizedBox(height: 8),
                const Text(
                  'This may take a while for all movies',
                  style: TextStyle(fontSize: 12, color: AppTheme.lightGray),
                ),
              ],
            ),
          );
        },
      ),
    );

    try {
      // Fetch all movies
      final movies = await Movie.getDummyMovies();
      progressNotifier.value = {'current': 0, 'total': movies.length};

      final results = await PosterFetcher.fetchAndSavePosters(
        movies,
        onProgress: (current, total) {
          progressNotifier.value = {'current': current, 'total': total};
        },
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Posters fetched: ${results['success']} successful, ${results['failed']} failed, ${results['skipped']} skipped',
            ),
            backgroundColor: AppTheme.primaryRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching posters: $e'),
            backgroundColor: AppTheme.primaryRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      progressNotifier.dispose();
    }
  }
}

