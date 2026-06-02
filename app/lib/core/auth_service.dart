import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
}

class AuthService {
  static const _tokenKey = 'auth_token';

  // ── Token storage ─────────────────────────────────────────

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// Devuelve true si hay un token válido y no ha expirado.
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    if (token == null) return false;
    try {
      return !JwtDecoder.isExpired(token);
    } catch (_) {
      return false;
    }
  }

  // ── API calls ─────────────────────────────────────────────

  /// Llama al endpoint de login y guarda el token.
  /// Lanza [AuthException] si las credenciales son incorrectas.
  static Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(ApiConstants.login),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': identifier, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const AuthException('Connection error. Check your network.');
    }

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      await saveToken(body['access_token'] as String);
      return;
    }

    // Extraer mensaje del backend si existe
    String detail = 'Invalid credentials';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      detail = body['detail'] as String? ?? detail;
    } catch (_) {}
    throw AuthException(detail);
  }
}
