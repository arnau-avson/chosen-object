/// URL base de la API.
///
/// En desarrollo no hace falta nada; en producción pásala al compilar:
///   flutter run  --dart-define=API_BASE_URL=https://api.tudominio.com
///   flutter build apk --dart-define=API_BASE_URL=https://api.tudominio.com
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000', // Windows desktop / Web / iOS simulator
  // defaultValue: 'http://10.0.2.2:8000', // Android emulator
);

class ApiConstants {
  static const String baseUrl = kApiBaseUrl;

  static const String login = '$baseUrl/api/v1/auth/login';
  static const String register = '$baseUrl/api/v1/auth/register';
  static const String me = '$baseUrl/api/v1/auth/me';
}
