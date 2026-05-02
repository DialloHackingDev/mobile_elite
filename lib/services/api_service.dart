import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service API principal pour communiquer avec le backend NaissanceChain
class ApiService {
  static String get _baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (envUrl.isNotEmpty) return envUrl;

    // IMPORTANT: Remplacez par l'IP de votre PC sur le réseau WiFi
    // Pour émulateur Android: http://10.0.2.2:3000/api
    // Pour vrai téléphone sur même WiFi: http://192.168.1.107:3000/api
    return 'http://192.168.1.107:3000/api';
  }

  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _agentKey = 'agent_data';

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _authToken;
  String? _refreshToken;
  Map<String, dynamic>? _agentData;

  /// Initialise le service avec les tokens stockés
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    _refreshToken = prefs.getString(_refreshTokenKey);
    final agentJson = prefs.getString(_agentKey);
    if (agentJson != null) {
      _agentData = jsonDecode(agentJson);
    }
  }

  /// Vérifie la connectivité réseau
  Future<bool> hasInternetConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Headers par défaut avec authentification
  Map<String, String> _getHeaders({bool requiresAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth && _authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Sauvegarde les tokens d'authentification
  Future<void> _saveTokens(String accessToken, String refreshToken, Map<String, dynamic> agent) async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = accessToken;
    _refreshToken = refreshToken;
    _agentData = agent;

    await prefs.setString(_tokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_agentKey, jsonEncode(agent));
  }

  /// Efface les tokens (logout)
  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = null;
    _refreshToken = null;
    _agentData = null;

    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_agentKey);
  }

  /// Récupère les données de l'agent connecté
  Map<String, dynamic>? get agentData => _agentData;
  bool get isAuthenticated => _authToken != null;
  String? get token => _authToken;

  // ==================== AUTHENTIFICATION ====================

  /// Connexion d'un agent
  /// POST /api/auth/login
  Future<Map<String, dynamic>> login(String nationalAgentId, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _getHeaders(requiresAuth: false),
        body: jsonEncode({
          'nationalAgentId': nationalAgentId,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final tokens = data['data'];
        await _saveTokens(
          tokens['accessToken'],
          tokens['refreshToken'],
          tokens['agent'],
        );
        return {'success': true, 'data': tokens};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Erreur de connexion'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Inscription d'un citoyen/famille
  /// POST /api/auth/citizen/register
  Future<Map<String, dynamic>> citizenRegister(Map<String, dynamic> body) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/citizen/register'),
        headers: _getHeaders(requiresAuth: false),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final tokens = data['data'];
        await _saveTokens(
          tokens['accessToken'],
          tokens['refreshToken'],
          tokens['citizen'],
        );
        return {'success': true, 'data': tokens};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Erreur d\'inscription'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Connexion d'un citoyen/famille
  /// POST /api/auth/citizen/login
  Future<Map<String, dynamic>> citizenLogin(String phoneNumber, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/citizen/login'),
        headers: _getHeaders(requiresAuth: false),
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final tokens = data['data'];
        await _saveTokens(
          tokens['accessToken'],
          tokens['refreshToken'],
          tokens['citizen'],
        );
        return {'success': true, 'data': tokens};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Erreur de connexion'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Rafraîchir le token
  /// POST /api/auth/refresh
  Future<bool> refreshToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: _getHeaders(requiresAuth: false),
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokens = data['data'];
        await _saveTokens(
          tokens['accessToken'],
          tokens['refreshToken'],
          _agentData!,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Déconnexion
  /// POST /api/auth/logout
  Future<void> logout() async {
    try {
      if (_authToken != null) {
        await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: _getHeaders(),
        );
      }
    } catch (e) {
      // Ignore les erreurs de logout
    } finally {
      await clearTokens();
    }
  }

  /// Configurer 2FA
  /// POST /api/auth/setup-2fa
  Future<Map<String, dynamic>> setup2FA() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/setup-2fa'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'data': data['data'],
        'error': data['message'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Vérifier 2FA
  /// POST /api/auth/verify-2fa
  Future<Map<String, dynamic>> verify2FA(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/verify-2fa'),
        headers: _getHeaders(),
        body: jsonEncode({'token': token}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'error': data['message'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ==================== NAISSANCES ====================

  /// Enregistrer une naissance
  /// POST /api/births
  Future<Map<String, dynamic>> registerBirth(Map<String, dynamic> birthData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/births'),
        headers: _getHeaders(),
        body: jsonEncode(birthData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Erreur d\'enregistrement'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Synchroniser les naissances hors-ligne
  /// POST /api/births/sync
  Future<Map<String, dynamic>> syncBirths(List<Map<String, dynamic>> births) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/births/sync'),
        headers: _getHeaders(),
        body: jsonEncode({'births': births}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Erreur de synchronisation'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Récupérer une naissance par ID national
  /// GET /api/births/{nationalId}
  Future<Map<String, dynamic>> getBirthByNationalId(String nationalId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/births/$nationalId'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Acte non trouvé'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Récupérer les naissances en attente (ADMIN)
  /// GET /api/births/pending
  Future<Map<String, dynamic>> getPendingBirths() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/births/pending'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Valider une naissance tardive (ADMIN)
  /// PATCH /api/births/{id}/validate
  Future<Map<String, dynamic>> validateLateBirth(String id, String decision) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/births/$id/validate'),
        headers: _getHeaders(),
        body: jsonEncode({'decision': decision}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Erreur de validation'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ==================== VÉRIFICATION ====================

  /// Vérifier un acte via QR Code
  /// POST /api/verify/qr
  Future<Map<String, dynamic>> verifyByQR(String qrPayload, {String verifierType = 'PUBLIC'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify/qr'),
        headers: _getHeaders(requiresAuth: false),
        body: jsonEncode({
          'qrPayload': qrPayload,
          'verifierType': verifierType,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Vérification échouée'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Vérifier un acte via ID National
  /// POST /api/verify/id
  Future<Map<String, dynamic>> verifyById(String nationalId, {String verifierType = 'PUBLIC'}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verify/id'),
        headers: _getHeaders(requiresAuth: false),
        body: jsonEncode({
          'nationalId': nationalId,
          'verifierType': verifierType,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Acte non trouvé'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ==================== DASHBOARD ====================

  /// Récupérer les statistiques
  /// GET /api/dashboard/stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/stats'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Récupérer les données de carte
  /// GET /api/dashboard/map
  Future<Map<String, dynamic>> getDashboardMap() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dashboard/map'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ==================== AGENTS ====================

  /// Récupérer la liste des agents
  /// GET /api/agents
  Future<Map<String, dynamic>> getAgents() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/agents'),
        headers: _getHeaders(),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message']};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Créer un nouvel agent
  /// POST /api/agents
  Future<Map<String, dynamic>> createAgent(Map<String, dynamic> agentData) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/agents'),
        headers: _getHeaders(),
        body: jsonEncode(agentData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {'success': false, 'error': data['message'] ?? 'Erreur de création'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Health check
  /// GET /api/health
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _getHeaders(requiresAuth: false),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'error': 'Service indisponible'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Service indisponible: $e'};
    }
  }

  // ==================== MÉTHODES GÉNÉRIQUES ====================

  /// Requête GET générique
  Future<Map<String, dynamic>> get(String endpoint, {bool requiresAuth = true}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(requiresAuth: requiresAuth),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'data': data['data'] ?? data,
        'error': data['message'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Requête POST générique
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, {bool requiresAuth = true}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _getHeaders(requiresAuth: requiresAuth),
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'data': data['data'] ?? data,
        'error': data['message'],
      };
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  /// Définir manuellement le token (pour auth citizen)
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = token;
    await prefs.setString(_tokenKey, token);
  }

  /// Effacer le token (alias pour logout)
  Future<void> clearToken() async {
    await clearTokens();
  }
}
