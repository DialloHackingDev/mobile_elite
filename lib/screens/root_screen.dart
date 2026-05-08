import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/agent.dart';
import 'role_selection_screen.dart';
import 'agent/agent_dashboard_screen.dart';
import 'citizen/citizen_dashboard_screen.dart';
import 'admin/admin_dashboard_screen.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    final api = ApiService();
    
    // Si pas authentifié, go selection rôle
    if (!api.isAuthenticated || api.userData == null) {
      _navigate(const RoleSelectionScreen());
      return;
    }

    final user = api.userData!;
    final role = user['role'] as String?;

    if (role == 'CITIZEN') {
      _navigate(const CitizenDashboardScreen());
    } else {
      // Pour les agents et admins
      final agent = Agent.fromJson(user);
      if (agent.isAdmin) {
        _navigate(AdminDashboardScreen(admin: agent));
      } else {
        _navigate(const AgentDashboardScreen());
      }
    }
  }

  void _navigate(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      ),
    );
  }
}
