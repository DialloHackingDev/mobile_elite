import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// URL configurable via --dart-define=API_BASE_URL=http://X.X.X.X:3000/api
/// Émulateur Android  → http://10.0.2.2:3000/api  (valeur par défaut)
/// Vrai téléphone WiFi → http://192.168.X.X:3000/api
// Émulateur Android  → http://10.0.2.2:3000/api
// Vrai téléphone WiFi → http://192.168.1.107:3000/api  (IP de la machine hôte)
// Surcharger via : flutter run --dart-define=API_BASE_URL=http://X.X.X.X:3000/api
const String _kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3000/api',  // Localhost pour émulateur Android
);

class ApiService {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ── Clés SharedPreferences ─────────────────────────────────────────────────
  static const _kToken        = 'auth_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUser         = 'user_data';

  // ── État interne ───────────────────────────────────────────────────────────
  String? _token;
  String? _refreshToken;
  Map<String, dynamic>? _user;

  String get baseUrl => _kBaseUrl;
  bool   get isAuthenticated => _token != null;
  String? get token => _token;
  Map<String, dynamic>? get userData => _user;

  // ── Initialisation ─────────────────────────────────────────────────────────
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token        = prefs.getString(_kToken);
    _refreshToken = prefs.getString(_kRefreshToken);
    final raw     = prefs.getString(_kUser);
    if (raw != null) _user = jsonDecode(raw) as Map<String, dynamic>;
  }

  // ── Session ────────────────────────────────────────────────────────────────
  Future<void> _saveSession(
    String accessToken,
    String refreshToken,
    Map<String, dynamic> user,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    _token        = accessToken;
    _refreshToken = refreshToken;
    _user         = user;
    await prefs.setString(_kToken,        accessToken);
    await prefs.setString(_kRefreshToken, refreshToken);
    await prefs.setString(_kUser,         jsonEncode(user));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    _token = _refreshToken = _user = null;
    await prefs.remove(_kToken);
    await prefs.remove(_kRefreshToken);
    await prefs.remove(_kUser);
  }

  // ── Connectivité ───────────────────────────────────────────────────────────
  Future<bool> hasInternetConnection() async {
    final r = await Connectivity().checkConnectivity();
    return r != ConnectivityResult.none;
  }

  // ── HTTP helpers ───────────────────────────────────────────────────────────
  Map<String, String> _headers({bool auth = true}) => {
    'Content-Type': 'application/json',
    'Accept':       'application/json',
    if (auth && _token != null) 'Authorization': 'Bearer $_token',
  };

  /// Transforme la réponse HTTP en Map standard {success, data, error, statusCode}
  Map<String, dynamic> _parse(http.Response res) {
    try {
      final body    = jsonDecode(res.body) as Map<String, dynamic>;
      final success = res.statusCode >= 200 && res.statusCode < 300;

      // Token expiré ou invalide → on vide la session pour forcer la reconnexion
      if (res.statusCode == 401) {
        // Si on n'a pas de token, c'est une erreur d'authentification directe (ex: mauvais mot de passe au login)
        // Si on a un token, c'est que la session stockée n'est plus valide.
        final bool isSessionExpiration = _token != null;
        final backendMessage = body['message'] as String? ?? (isSessionExpiration ? 'Session expirée' : 'Identifiants invalides');
        
        if (isSessionExpiration) {
          clearSession();
        }

        return {
          'success': false,
          'error': isSessionExpiration ? 'SESSION_EXPIRED' : 'INVALID_CREDENTIALS',
          'message': backendMessage,
          'statusCode': 401,
        };
      }

      return {
        'success':    success,
        'data':       body['data'],
        'message':    body['message'],
        'error':      success ? null : (body['message'] ?? 'Erreur inconnue'),
        'statusCode': res.statusCode,
      };
    } catch (_) {
      // Token expiré avec réponse non-JSON
      if (res.statusCode == 401) {
        if (_token != null) clearSession();
        return {'success': false, 'error': 'SESSION_EXPIRED', 'statusCode': 401};
      }
      return {'success': false, 'error': 'Réponse invalide', 'statusCode': res.statusCode};
    }
  }

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    try {
      final res = await http
          .get(Uri.parse('$baseUrl$path'), headers: _headers(auth: auth))
          .timeout(const Duration(seconds: 30));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    try {
      final res = await http
          .post(Uri.parse('$baseUrl$path'),
              headers: _headers(auth: auth), body: jsonEncode(body))
          .timeout(const Duration(seconds: 60));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await http
          .patch(Uri.parse('$baseUrl$path'),
              headers: _headers(), body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final res = await http
          .delete(Uri.parse('$baseUrl$path'), headers: _headers())
          .timeout(const Duration(seconds: 30));
      return _parse(res);
    } catch (e) {
      return {'success': false, 'error': 'Erreur réseau: $e'};
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH — AGENT
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> loginAgent(
      String nationalAgentId, String password) async {
    final res = await post(
      '/auth/login',
      {'nationalAgentId': nationalAgentId, 'password': password},
      auth: false,
    );
    if (res['success'] == true) {
      final d = res['data'] as Map<String, dynamic>;
      await _saveSession(d['accessToken'], d['refreshToken'],
          d['agent'] as Map<String, dynamic>);
    }
    return res;
  }

  Future<void> logout() async {
    try { await post('/auth/logout', {}); } catch (_) {}
    await clearSession();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // AUTH — CITOYEN
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> loginCitizen(
      String phoneNumber, String password) async {
    final res = await post(
      '/auth/citizen/login',
      {'phoneNumber': phoneNumber, 'password': password},
      auth: false,
    );
    if (res['success'] == true) {
      final d = res['data'] as Map<String, dynamic>;
      await _saveSession(d['accessToken'], d['refreshToken'],
          d['citizen'] as Map<String, dynamic>);
    }
    return res;
  }

  Future<Map<String, dynamic>> registerCitizen(
      Map<String, dynamic> body) async {
    final res = await post('/auth/citizen/register', body, auth: false);
    if (res['success'] == true) {
      final d = res['data'] as Map<String, dynamic>;
      await _saveSession(d['accessToken'], d['refreshToken'],
          d['citizen'] as Map<String, dynamic>);
    }
    return res;
  }

  Future<Map<String, dynamic>> getMe() => get('/auth/me');

  // ══════════════════════════════════════════════════════════════════════════
  // NAISSANCES
  // ══════════════════════════════════════════════════════════════════════════

  /// Enregistre un acte (en ligne)
  Future<Map<String, dynamic>> registerBirth(
          Map<String, dynamic> data) =>
      post('/births', data);

  /// Liste paginée des actes de l'agent connecté
  Future<Map<String, dynamic>> getBirths({int page = 1, int limit = 20}) =>
      get('/births?page=$page&limit=$limit');

  /// Consulte un acte par son ID national (public)
  Future<Map<String, dynamic>> getBirthByNationalId(String nationalId) =>
      get('/births/$nationalId', auth: false);

  /// Synchronise un lot d'actes hors-ligne
  Future<Map<String, dynamic>> syncBirths(
          List<Map<String, dynamic>> births) =>
      post('/births/sync', {'births': births});

  /// Actes en attente de validation (admin)
  Future<Map<String, dynamic>> getPendingBirths() => get('/births/pending');

  /// Valide ou rejette un acte tardif (admin)
  Future<Map<String, dynamic>> validateBirth(
          String id, String decision) =>
      patch('/births/$id/validate', {'decision': decision});

  // ══════════════════════════════════════════════════════════════════════════
  // CITOYEN
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getMyChildren() => get('/citizen/my-children');

  // ══════════════════════════════════════════════════════════════════════════
  // DASHBOARD
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getDashboardStats() =>
      get('/dashboard/stats');

  // ══════════════════════════════════════════════════════════════════════════
  // VÉRIFICATION (public)
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> verifyById(String nationalId,
          {String verifierType = 'PUBLIC'}) =>
      post('/verify/id',
          {'nationalId': nationalId, 'verifierType': verifierType},
          auth: false);

  Future<Map<String, dynamic>> verifyByQR(String qrPayload,
          {String verifierType = 'PUBLIC'}) =>
      post('/verify/qr',
          {'qrPayload': qrPayload, 'verifierType': verifierType},
          auth: false);

  // ══════════════════════════════════════════════════════════════════════════
  // DEMANDES CITOYEN
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getMyRequests() =>
      get('/requests/my-requests');

  Future<Map<String, dynamic>> createRequest(
          Map<String, dynamic> body) =>
      post('/requests', body);

  Future<Map<String, dynamic>> cancelRequest(String id) =>
      delete('/requests/$id');

  // ══════════════════════════════════════════════════════════════════════════
  // NOTIFICATIONS & PARTAGE
  // ══════════════════════════════════════════════════════════════════════════

  Future<Map<String, dynamic>> getNotifications() =>
      get('/notifications');

  Future<Map<String, dynamic>> markNotificationAsRead(String id) =>
      patch('/notifications/$id/read', {});

  Future<Map<String, dynamic>> listCitizens() =>
      get('/notifications/citizens');

  Future<Map<String, dynamic>> listAgents() =>
      get('/notifications/agents');

  Future<Map<String, dynamic>> sendNotificationToCitizen(Map<String, dynamic> body) =>
      post('/notifications/send', body);

  // ══════════════════════════════════════════════════════════════════════════
  // HEALTH
  // ══════════════════════════════════════════════════════════════════════════

  Future<bool> healthCheck() async {
    final r = await get('/health', auth: false);
    return r['success'] == true;
  }
}
