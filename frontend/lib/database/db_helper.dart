import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/movie.dart';
import '../models/user.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static bool _isInitializing = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // Prevent multiple simultaneous initializations
    if (_isInitializing) {
      while (_isInitializing) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_database != null) return _database!;
    }
    
    _isInitializing = true;
    try {
      _database = await _initDatabase();
      _isInitializing = false;
      return _database!;
    } catch (e) {
      _isInitializing = false;
      print('❌ [DatabaseHelper] Error getting database: $e');
      // Reset and retry once
      _database = null;
      await Future.delayed(const Duration(milliseconds: 300));
      _isInitializing = true;
      try {
        _database = await _initDatabase();
        _isInitializing = false;
        return _database!;
      } catch (e2) {
        _isInitializing = false;
        print('❌ [DatabaseHelper] Retry failed: $e2');
        rethrow;
      }
    }
  }

  Future<Database> _initDatabase() async {
    try {
      // Ensure database factory is initialized by calling getDatabasesPath first
      final databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'movies.db');
      print('🗄️ [DatabaseHelper] Database path: $path');
      
      // Small delay to ensure factory is ready
      await Future.delayed(const Duration(milliseconds: 50));
      
      final db = await openDatabase(
        path,
        version: 3, // Increment version to trigger migration
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
      
      print('✅ [DatabaseHelper] Database initialized successfully');
      return db;
    } catch (e) {
      print('❌ [DatabaseHelper] Error initializing database: $e');
      // Retry once after a longer delay
      await Future.delayed(const Duration(milliseconds: 200));
      try {
        final databasesPath = await getDatabasesPath();
        String path = join(databasesPath, 'movies.db');
        final db = await openDatabase(
          path,
          version: 3,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );
        print('✅ [DatabaseHelper] Database initialized on retry');
        return db;
      } catch (e2) {
        print('❌ [DatabaseHelper] Retry also failed: $e2');
        rethrow;
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create movies table
    await db.execute('''
      CREATE TABLE movies(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        genres TEXT,
        rating REAL,
        year INTEGER,
        description TEXT,
        posterUrl TEXT
      )
    ''');

    // Create users table
    await db.execute('''
      CREATE TABLE users(
        userId TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        gender TEXT,
        age INTEGER,
        occupation INTEGER,
        zipCode TEXT
      )
    ''');
    print('✅ [DatabaseHelper] Created users table');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE movies ADD COLUMN posterUrl TEXT');
        print('✅ [DatabaseHelper] Added posterUrl column to database');
      } catch (e) {
        print('⚠️ [DatabaseHelper] posterUrl column may already exist: $e');
      }
    }
    
    if (oldVersion < 3) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS users(
            userId TEXT PRIMARY KEY,
            username TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            gender TEXT,
            age INTEGER,
            occupation INTEGER,
            zipCode TEXT
          )
        ''');
        print('✅ [DatabaseHelper] Created users table');
      } catch (e) {
        print('⚠️ [DatabaseHelper] Error creating users table: $e');
      }
    }
  }

  Future<void> insertMovies(List<Movie> movies) async {
    try {
      final db = await database;
      final batch = db.batch();
      for (var movie in movies) {
        batch.insert(
          'movies',
          {
            'id': movie.movieId,
            'title': movie.title,
            'genres': movie.genres.join(','),
            'rating': movie.rating,
            'year': movie.year,
            'description': movie.description,
            'posterUrl': movie.posterUrl,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      print('❌ [DatabaseHelper] Error inserting movies: $e');
      rethrow;
    }
  }

  Future<String> insertUser(User user) async {
    final db = await database;
    final userId = user.userId.isEmpty 
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : user.userId;
    await db.insert(
      'users',
      {
        'userId': userId,
        'username': user.username,
        'password': user.password,
        'gender': user.gender,
        'age': user.age,
        'occupation': user.occupation,
        'zipCode': user.zipCode,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return userId;
  }

  Future<User?> getUserByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return User.fromMap(maps.first);
  }

  Future<User?> getUserById(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (maps.isEmpty) {
      return null;
    }

    return User.fromMap(maps.first);
  }

  Future<bool> usernameExists(String username) async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM users WHERE username = ?',
        [username],
      ),
    ) ?? 0;
    return count > 0;
  }

  
    
}
