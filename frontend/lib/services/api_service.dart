import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/movie.dart';


class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<int> predictLikeDislike(List<double> features) async {
    final url = Uri.parse('$baseUrl/predict-like-dislike');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'features': features}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['like_dislike'];
    } else {
      throw Exception('Failed to get prediction: ${response.body}');
    }
  }

  Future<double> predictRating(List<double> features) async {
    final url = Uri.parse('$baseUrl/predict-rating');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'features': features}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['predicted_rating'];
    } else {
      throw Exception('Failed to get prediction: ${response.body}');
    }
  }

  Future<int> clusterUserRatings(List<double> features) async {
    final url = Uri.parse('$baseUrl/cluster-user-ratings');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'features': features}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['cluster'];
    } else {
      throw Exception('Failed to get cluster: ${response.body}');
    }
  }

  Future<int> clusterUserGenres(List<double> features) async {
    final url = Uri.parse('$baseUrl/cluster-user-genres');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'features': features}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['cluster'];
    } else {
      throw Exception('Failed to get cluster: ${response.body}');
    }
  }

  Future<void> sendGenresToApi(String userId, List<int> genres) async {
  final baseUrl = dotenv.env['API_BASE_URL'];
  final url = Uri.parse("$baseUrl/user/genres/");

  final body = jsonEncode({
    "user_id": userId,
    "preferred_genres": genres,  
  });

  final response = await http.post(
    url,
    headers: {
      "Content-Type": "application/json",
    },
    body: body,
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print("Cluster: ${data['cluster']}");
    print("Recommendations: ${data['recommendations']}");
  } else {
    print("Failed to send genres: ${response.statusCode}");
  }
  }

  Future<void> addUserToServer(User newUser) async {
  final userId = newUser.userId.isNotEmpty
      ? newUser.userId
      : DateTime.now().millisecondsSinceEpoch.toString();

  final body = {
    "userId": userId,
    "username": newUser.username,
    "password": newUser.password,
    "gender": newUser.gender ?? null,
    "age": newUser.age ?? null,
    "occupation": newUser.occupation ?? null,
    "zipCode": newUser.zipCode ?? null,
    "preferred_genres": newUser.preferredGenres?.join(',') ?? null,
  };

  final uri = Uri.parse('$baseUrl/add-user');

  final response = await http.post(
    uri,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print("✅ User added successfully, userId: ${data['userId']}");
  } else {
    print("❌ Failed to add user: ${response.body}");
  }
}

Future<void> updateUserGenresOnServerByUsername(
    String username, List<int> genres) async {
  final body = {
    "username": username,
    "preferred_genres": genres,
  };

  final uri = Uri.parse('$baseUrl/update-user-genres');

  final response = await http.put(
    uri,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (response.statusCode == 200) {
    print("✅ User genres updated successfully for $username");
  } else {
    print("❌ Failed to update user genres for $username: ${response.body}");
  }
}



  Future<void> sendUsernameToApi(String username) async {
    final url = Uri.parse('$baseUrl/send-username');
    
    final body = {
      "username": username,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("✅ Username sent successfully: $username");
      } else {
        print("❌ Failed to send username: ${response.body}");
      }
    } catch (e) {
      print("Error sending username: $e");
    }
  }

  Future<List<Movie>> fetchPredictedMoviesRatings(String username) async {
    final url = Uri.parse('$baseUrl/PredictFutureRating');
    final body = jsonEncode({"username": username});

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final moviesJson = data['recommended_movies'] as List;
        return moviesJson.map((json) => Movie.fromJson(json)).toList();
      } else {
        print("❌ Failed to fetch predicted movies: ${response.body}");
        return [];
      }
    } catch (e) {
      print("Error fetching predicted movies: $e");
      return [];
    }
  }

}
