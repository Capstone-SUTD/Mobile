import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'project_model.dart';

class DataService {
  static Future<List<Project>> getProjects() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    print("Fetching projects with token: $token"); // Debug
    
    final response = await http.get(
      Uri.parse('http://10.0.2.2:3000/project/list'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    ).timeout(Duration(seconds: 10));

    print("Response status: ${response.statusCode}"); // Debug
    print("Response body: ${response.body}"); // Debug

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      print("Parsed ${data.length} projects"); // Debug
      return data.map((json) => Project.fromJson(json)).toList();
    } else {
      throw Exception('Failed with status ${response.statusCode}');
    }
  } catch (e) {
    print('Error in getProjects: $e');
    rethrow;
  }
}
}