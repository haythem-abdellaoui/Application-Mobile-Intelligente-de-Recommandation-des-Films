class User {
  final String userId;
  final String username;
  final String password;
  final String? gender;
  final int? age;
  final int? occupation;
  final String? zipCode;

  // Getters for convenience
  String get id => userId;
  String get name => username;

  User({
    this.userId = '',
    required this.username,
    required this.password,
    this.gender,
    this.age,
    this.occupation,
    this.zipCode,
  });

  // Create User from database map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userId: map['userId'] as String,
      username: map['username'] as String,
      password: map['password'] as String,
      gender: map['gender'] as String?,
      age: map['age'] as int?,
      occupation: map['occupation'] as int?,
      zipCode: map['zipCode'] as String?,
    );
  }

  // Convert User to database map
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'username': username,
      'password': password,
      'gender': gender,
      'age': age,
      'occupation': occupation,
      'zipCode': zipCode,
    };
  }

  // Dummy user for UI
  static User getDummyUser() {
    return User(
      userId: '1',
      username: 'dummy_user',
      password: 'password',
      gender: 'M',
      age: 25,
      occupation: 1,
      zipCode: '12345',
    );
  }
}

