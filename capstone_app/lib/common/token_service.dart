// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:dio/dio.dart';

// class TokenService {
//   // Save token (1-liner)
//   static Future<void> saveToken(String token) async =>
//       (await SharedPreferences.getInstance()).setString('auth_token', token);

//   // Retrieve token (1-liner)
//   static Future<String?> getToken() async =>
//       (await SharedPreferences.getInstance()).getString('auth_token');

//   // Send POST request with token in header
//   static Future<Response?> sendPostWithToken({
//     required String url,
//     Map<String, dynamic>? data,
//   }) async {
//     final token = await getToken();
//     if (token == null) {
//       print('No token found');
//       return null;
//     }

//     Dio dio = Dio();
//     dio.options.headers['Authorization'] = 'Bearer $token';

//     try {
//       final response = await dio.post(url, data: data);
//       return response;
//     } catch (e) {
//       print('POST request failed: $e');
//       return null;
//     }
//   }
// }
