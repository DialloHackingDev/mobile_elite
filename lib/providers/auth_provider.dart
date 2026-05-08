import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/agent.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';

class AuthState {
  final bool isLoading;
  final Agent? agent;
  final String? error;
  final bool isAuthenticated;

  AuthState({
    this.isLoading = false,
    this.agent,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isLoading,
    Agent? agent,
    String? error,
    bool? isAuthenticated,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      agent: agent ?? this.agent,
      error: clearError ? null : (error ?? this.error),
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkSession();
  }

  Future<void> _checkSession() async {
    try {
      final isAuth = AuthService.isAuthenticated;
      if (isAuth) {
        final agent = AuthService.currentAgent;
        state = state.copyWith(
          agent: agent,
          isAuthenticated: true,
          clearError: true,
        );
        logInfo('Session restaurée pour l\'agent: ${agent?.id}');
      }
    } catch (e, stackTrace) {
      logError('Erreur de session', e, stackTrace);
    }
  }

  Future<void> loginAgent(String nationalAgentId, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await AuthService.login(nationalAgentId, password);
      if (result['success'] == true) {
        logBusiness('Login Agent', {'agentId': nationalAgentId});
        state = state.copyWith(
          agent: result['agent'] as Agent,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        logWarning('Échec login agent: ${result['error']}');
        state = state.copyWith(
          error: result['error'] ?? 'Identifiants invalides',
          isLoading: false,
        );
      }
    } catch (e, stackTrace) {
      logError('Erreur inattendue login agent', e, stackTrace);
      state = state.copyWith(
        error: 'Une erreur de connexion est survenue.',
        isLoading: false,
      );
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    logBusiness('Logout Agent');
    state = AuthState(); 
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
