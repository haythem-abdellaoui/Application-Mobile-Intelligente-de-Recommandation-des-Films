import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:sqflite/sqflite.dart';
import 'themes/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'services/data_loader.dart';
import 'database/db_helper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io' show Platform;                  // for Platform checks
import 'package:sqflite_common_ffi/sqflite_ffi.dart';  // for sqflite FFI on desktop
import 'package:flutter/foundation.dart';       // for kIsWeb


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  
  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ [Main] Environment variables loaded');
  } catch (e) {
    print('⚠️ [Main] No .env file found or error loading it: $e');
  }
  
  print('🚀 [Main] Starting app initialization...');
  print('🚀 [Main] WidgetsFlutterBinding initialized');
  
  // Initialize database factory by calling getDatabasesPath first
  try {
    print('🗄️ [Main] Initializing database factory...');
    await getDatabasesPath();
    print('✅ [Main] Database factory initialized');
  } catch (e) {
    print('⚠️ [Main] Database factory initialization warning: $e');
  }
  
  // Check if database already has data
  try {
    final db = await DatabaseHelper().database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM movies')
    ) ?? 0;
    print('📊 [Main] Current movies in database: $count');
    
    if (count == 0) {
      print('📦 [Main] Database is empty, loading data...');
      print('📦 [Main] Loading movies...');
      final movies = await DataLoader.loadMovies();
      print('✅ [Main] Loaded ${movies.length} movies');
      
      print('⭐ [Main] Loading ratings...');
      await DataLoader.loadRatings();
      print('✅ [Main] Ratings loaded');
      
      print('👥 [Main] Loading users...');
      final users = await DataLoader.loadUsers();
      print('✅ [Main] Loaded ${users.length} users');
      
      print('✅ [Main] All data loaded successfully!');
    } else {
      print('✅ [Main] Database already has $count movies, skipping data load');
    }
  } catch (e, stackTrace) {
    print('❌ [Main] Error during data loading: $e');
    print('Stack trace: $stackTrace');
  }
  
  print('🎬 [Main] Starting app...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MovieRec',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Temporarily set to LoginScreen for testing
      // Change back to SplashScreen() when done testing
      //home: const LoginScreen(),
       home: const SplashScreen(),
    );
  }
}
