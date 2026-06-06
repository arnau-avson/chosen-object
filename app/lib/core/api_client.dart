import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ═════════════════════════════════════════════════════════════
// ── ApiClient — centralised HTTP wrapper ────────────────────
// ═════════════════════════════════════════════════════════════

class ApiClient {
  // Change this to your backend URL.
  // Android emulator → 10.0.2.2, iOS simulator → 127.0.0.1
  static const _baseUrl = 'http://10.0.2.2:8000/api/v1';

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();
  ApiClient._();

  // ── Token management ──────────────────────────────────────

  String? _token;

  Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  // ── Headers ───────────────────────────────────────────────

  Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── GET ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> get(String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  // ── PUT (JSON) ────────────────────────────────────────────

  Future<Map<String, dynamic>> put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.put(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ── POST multipart (for image uploads) ────────────────────

  Future<Map<String, dynamic>> postMultipart(
    String path, {
    Map<String, String> fields = const {},
    Uint8List? fileBytes,
    String fileField = 'file',
    String fileName = 'image.webp',
  }) async {
    final token = await _getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl$path'),
    );

    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);

    if (fileBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        fileField,
        fileBytes,
        filename: fileName,
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  // ── Response handling ─────────────────────────────────────

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final detail = body['detail'] ?? 'Unknown error';
    throw ApiException(response.statusCode, detail.toString());
  }
}

// ═════════════════════════════════════════════════════════════

class ApiException implements Exception {
  final int statusCode;
  final String message;

  const ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}
