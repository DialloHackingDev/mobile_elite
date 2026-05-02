import '../models/agent.dart';
import 'api_service.dart';

/// Service d'authentification avec le backend
class AuthService {
  static final ApiService _apiService = ApiService();

  /// Connexion d'un agent
  /// [nationalAgentId] - Identifiant national de l'agent (ex: AGENT-0001)
  /// [password] - Mot de passe
  /// Retourne un objet avec success, agent et message d'erreur si applicable
  static Future<Map<String, dynamic>> login(String nationalAgentId, String password) async {
    try {
      final result = await _apiService.login(nationalAgentId, password);

      if (result['success']) {
        final agentData = result['data']['agent'];
        final agent = Agent.fromJson(agentData);

        return {
          'success': true,
          'agent': agent,
          'accessToken': result['data']['accessToken'],
          'refreshToken': result['data']['refreshToken'],
          'message': 'Connexion réussie',
        };
      } else {
        return {
          'success': false,
          'error': result['error'] ?? 'Identifiants invalides',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erreur de connexion: $e',
      };
    }
  }

  /// Déconnexion
  static Future<void> logout() async {
    await _apiService.logout();
  }

  /// Inscription d'un citoyen/famille
  static Future<Map<String, dynamic>> citizenRegister({
    required String fullName,
    required String phoneNumber,
    required String password,
    required String cniNumber,
    required String prefecture,
  }) async {
    final result = await _apiService.citizenRegister({
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'password': password,
      'cniNumber': cniNumber,
      'prefecture': prefecture,
    });

    return result;
  }

  /// Connexion d'un citoyen/famille
  static Future<Map<String, dynamic>> citizenLogin(String phoneNumber, String password) async {
    final result = await _apiService.citizenLogin(phoneNumber, password);
    return result;
  }

  /// Vérifier si l'utilisateur est connecté
  static bool get isAuthenticated => _apiService.isAuthenticated;

  /// Récupérer l'agent connecté
  static Agent? get currentAgent {
    final agentData = _apiService.agentData;
    if (agentData == null) return null;
    return Agent.fromJson(agentData);
  }

  /// Configurer la 2FA
  static Future<Map<String, dynamic>> setup2FA() async {
    return await _apiService.setup2FA();
  }

  /// Vérifier le code 2FA
  static Future<Map<String, dynamic>> verify2FA(String token) async {
    return await _apiService.verify2FA(token);
  }

  /// Rafraîchir le token
  static Future<bool> refreshToken() async {
    return await _apiService.refreshToken();
  }

  /// Vérifier la connexion internet
  static Future<bool> hasInternetConnection() async {
    return await _apiService.hasInternetConnection();
  }

  /// Health check du serveur
  static Future<Map<String, dynamic>> healthCheck() async {
    return await _apiService.healthCheck();
  }
}