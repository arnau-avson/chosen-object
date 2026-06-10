/// Base API URL.
///
/// In development nothing is needed; in production pass it at build time:
///   flutter run  --dart-define=API_BASE_URL=https://api.yourdomain.com
///   flutter build apk --dart-define=API_BASE_URL=https://api.yourdomain.com
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://apichosenobject.avson.eu', // Production
  // defaultValue: 'http://10.0.2.2:8000', // Android emulator
);

class ApiConstants {
  static const String baseUrl = kApiBaseUrl;

  static const String login = '$baseUrl/api/v1/auth/login';
  static const String register = '$baseUrl/api/v1/auth/register';
  static const String verifyEmail = '$baseUrl/api/v1/auth/verify-email';
  static const String resendPin = '$baseUrl/api/v1/auth/resend-pin';
  static const String me = '$baseUrl/api/v1/auth/me';
}
