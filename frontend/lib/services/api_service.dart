import 'dart:convert';
import 'package:http/http.dart' as http;

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
}
