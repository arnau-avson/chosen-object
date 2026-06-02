import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class AuthException implements Exception {
  final String message;
  final int? statusCode;
  const AuthException(this.message, {this.statusCode});
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

  /// Registers a new account. Does NOT return a token — the user
  /// must verify their email first.
  static Future<void> register({
    required String email,
    required String username,
    required String password,
    required String role,
    String firstName = '',
    String lastName = '',
    String city = '',
    String country = '',
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(ApiConstants.register),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'username': username,
              'password': password,
              'role': role,
              'first_name': firstName,
              'last_name': lastName,
              'city': city,
              'country': country,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const AuthException('Connection error. Check your network.');
    }

    if (response.statusCode == 201) return;

    String detail = 'Could not create account';
    int code = response.statusCode;
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      detail = body['detail'] as String? ?? detail;
    } catch (_) {}
    throw AuthException(detail, statusCode: code);
  }

  /// Verifies the email with a 6-digit PIN and saves the token.
  static Future<void> verifyEmail({
    required String email,
    required String pin,
  }) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(ApiConstants.verifyEmail),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'pin': pin}),
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

    String detail = 'Verification failed';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      detail = body['detail'] as String? ?? detail;
    } catch (_) {}
    throw AuthException(detail, statusCode: response.statusCode);
  }

  /// Requests a new verification PIN for the given email.
  static Future<void> resendPin({required String email}) async {
    final http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(ApiConstants.resendPin),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const AuthException('Connection error. Check your network.');
    }

    if (response.statusCode == 200) return;

    String detail = 'Could not resend code';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      detail = body['detail'] as String? ?? detail;
    } catch (_) {}
    throw AuthException(detail, statusCode: response.statusCode);
  }

  /// Signs in and saves the token.
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

    String detail = 'Invalid credentials';
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      detail = body['detail'] as String? ?? detail;
    } catch (_) {}
    throw AuthException(detail, statusCode: response.statusCode);
  }
}
