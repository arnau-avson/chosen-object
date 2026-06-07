import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'constants.dart';

// ═════════════════════════════════════════════════════════════
// ── ApiClient — centralised HTTP wrapper ────────────────────
// ═════════════════════════════════════════════════════════════

class ApiClient {
  static const _baseUrl = '${ApiConstants.baseUrl}/api/v1';

  static ApiClient? _instance;
  static ApiClient get instance => _instance ??= ApiClient._();
  ApiClient._();

  // ── Token management ──────────────────────────────────────

  String? _token;

  Future<String?> _getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    return _token;
  }

  Future<void> setToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
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

  Future<dynamic> get(String path) async {
    final response = await http.get(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
    );
    return _handleResponse(response);
  }

  // ── POST (JSON) ─────────────────────────────────────────

  Future<dynamic> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // ── PUT (JSON) ────────────────────────────────────────────

  Future<dynamic> put(
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

  // ── PATCH (JSON) ──────────────────────────────────────────

  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse(response);
  }

  // ── DELETE ────────────────────────────────────────────────

  Future<void> delete(String path) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: await _headers(),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw ApiException(response.statusCode, (body['detail'] ?? 'Unknown error').toString());
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

  // ── POST multipart with multiple files ────────────────────

  Future<Map<String, dynamic>> postMultipartMultiFile(
    String path, {
    Map<String, String> fields = const {},
    required List<Uint8List> files,
    String fileField = 'files',
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

    for (var i = 0; i < files.length; i++) {
      request.files.add(http.MultipartFile.fromBytes(
        fileField,
        files[i],
        filename: 'image_$i.jpg',
      ));
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _handleResponse(response);
  }

  // ── Response handling ─────────────────────────────────────

  dynamic _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final detail = body is Map ? (body['detail'] ?? 'Unknown error') : 'Unknown error';
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
