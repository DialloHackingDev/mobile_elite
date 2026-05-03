import '../models/agent.dart';
import 'api_service.dart';

/// Couche d'authentification — délègue entièrement à ApiService.
/// Aucune logique dupliquée ici.
class AuthService {
  static final _api = ApiService();

  // ── Agent ──────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String nationalAgentId, String password) async {
    final res = await _api.loginAgent(nationalAgentId, password);
    if (res['success'] == true) {
      return {
        'success': true,
        'agent': Agent.fromJson(res['data'] as Map<String, dynamic>),
      };
    }
    return {'success': false, 'error': res['error'] ?? 'Identifiants invalides'};
  }

  static Future<void> logout() => _api.logout();

  static Agent? get currentAgent {
    final d = _api.userData;
    return d == null ? null : Agent.fromJson(d);
  }

  static bool get isAuthenticated => _api.isAuthenticated;

  // ── Citoyen ────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> citizenLogin(
          String phoneNumber, String password) =>
      _api.loginCitizen(phoneNumber, password);

  static Future<Map<String, dynamic>> citizenRegister({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String cniNumber,
    required String prefecture,
  }) =>
      _api.registerCitizen({
        'fullName':   fullName,
        'phoneNumber': phoneNumber,
        'password':   password,
        'cniNumber':  cniNumber,
        'prefecture': prefecture,
      });

  // ── Utilitaires ────────────────────────────────────────────────────────────
  static Future<bool> hasInternetConnection() =>
      _api.hasInternetConnection();
}
