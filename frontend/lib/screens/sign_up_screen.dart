import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import 'login_screen.dart';
import '../database/db_helper.dart';
import '../models/user.dart';
import 'select_genres_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  final _zipCodeController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedGender;
  int? _selectedOccupation;
  bool _isCheckingUsername = false;

  // Occupation codes and names
  final Map<int, String> _occupations = {
    0: 'other / not specified',
    1: 'academic / educator',
    2: 'artist',
    3: 'clerical / admin',
    4: 'college / grad student',
    5: 'customer service',
    6: 'doctor / health care',
    7: 'executive / manager',
    8: 'farmer',
    9: 'homemaker',
    10: 'K-12 student',
    11: 'lawyer',
    12: 'programmer',
    13: 'retired',
    14: 'sales / marketing',
    15: 'scientist',
    16: 'self-employed',
    17: 'technician / engineer',
    18: 'tradesman / craftsman',
    19: 'unemployed',
    20: 'writer',
  };

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    // Validate all fields first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if all required fields are filled
    if (_selectedGender == null || _selectedOccupation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: AppTheme.primaryRed,
        ),
      );
      return;
    }

    // Check username uniqueness
    setState(() {
      _isCheckingUsername = true;
    });

    try {
      // Ensure database is initialized with error handling
      try {
        await DatabaseHelper().database;
      } catch (e) {
        print('⚠️ [SignUp] Database initialization error, retrying: $e');
        await Future.delayed(const Duration(milliseconds: 300));
        await DatabaseHelper().database;
      }
      
      final usernameExists = await DatabaseHelper().usernameExists(_usernameController.text.trim());
      
      if (usernameExists) {
        setState(() {
          _isCheckingUsername = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username already exists. Please choose another one.'),
            backgroundColor: AppTheme.primaryRed,
          ),
        );
        // Trigger validation to show error
        _formKey.currentState!.validate();
        return;
      }

      // All validations passed - Create user and insert into database
      final newUser = User(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        gender: _selectedGender,
        age: int.tryParse(_ageController.text),
        occupation: _selectedOccupation,
        zipCode: _zipCodeController.text.trim(),
      );

      // Insert user into database
      final userId = await DatabaseHelper().insertUser(newUser);
      
      setState(() {
        _isCheckingUsername = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to login screen after successful sign up
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => SelectGenresScreen(userId: userId)),
        );
      }
    } catch (e) {
      setState(() {
        _isCheckingUsername = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppTheme.primaryRed,
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                // Logo/Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryRed.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.movie,
                      size: 50,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Title
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                // Username field
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                  style: const TextStyle(color: AppTheme.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (value.length > 20) {
                      return 'Username must be less than 20 characters';
                    }
                    // Check for valid characters (alphanumeric and underscore)
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    // Clear any previous validation error when user types
                    if (_formKey.currentState != null) {
                      _formKey.currentState!.validate();
                    }
                  },
                ),
                const SizedBox(height: 20),
                // Password field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppTheme.lightGray,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  style: const TextStyle(color: AppTheme.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (value.length > 50) {
                      return 'Password must be less than 50 characters';
                    }
                    // Check for at least one letter and one number
                    if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
                      return 'Password must contain at least one letter and one number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Gender dropdown
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    hintText: 'Select your gender',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  dropdownColor: AppTheme.mediumGray,
                  style: const TextStyle(color: AppTheme.white),
                  iconEnabledColor: AppTheme.white,
                  items: const [
                    DropdownMenuItem(
                      value: 'M',
                      child: Text('Male'),
                    ),
                    DropdownMenuItem(
                      value: 'F',
                      child: Text('Female'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select your gender';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Age field
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Age',
                    hintText: 'Enter your age',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  style: const TextStyle(color: AppTheme.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your age';
                    }
                    final age = int.tryParse(value);
                    if (age == null) {
                      return 'Please enter a valid age';
                    }
                    if (age < 1 || age > 100) {
                      return 'Please enter a valid age (1-100)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Occupation dropdown
                DropdownButtonFormField<int>(
                  value: _selectedOccupation,
                  decoration: const InputDecoration(
                    labelText: 'Occupation',
                    hintText: 'Select your occupation',
                    prefixIcon: Icon(Icons.work_outline),
                  ),
                  dropdownColor: AppTheme.mediumGray,
                  style: const TextStyle(color: AppTheme.white),
                  iconEnabledColor: AppTheme.white,
                  items: _occupations.entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedOccupation = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select your occupation';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Zip code field
                TextFormField(
                  controller: _zipCodeController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    labelText: 'Zip Code',
                    hintText: 'Enter your zip code',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  style: const TextStyle(color: AppTheme.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your zip code';
                    }
                    // Validate zip code format (5 digits for US, or alphanumeric for international)
                    // Accepts both US format (12345) and international format (alphanumeric, 3-10 chars)
                    if (!RegExp(r'^[0-9]{5}(-[0-9]{4})?$').hasMatch(value) && 
                        !RegExp(r'^[A-Za-z0-9\s-]{3,10}$').hasMatch(value)) {
                      return 'Please enter a valid zip code (e.g., 12345 or ABC123)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Sign up button
                ElevatedButton(
                  onPressed: _isCheckingUsername ? null : _handleSignUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isCheckingUsername
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppTheme.mediumGray,
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppTheme.mediumGray,
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Login link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
