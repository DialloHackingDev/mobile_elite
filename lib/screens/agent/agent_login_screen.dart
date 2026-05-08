import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/agent.dart';
import 'agent_dashboard_screen.dart';
import '../admin/admin_dashboard_screen.dart';

class AgentLoginScreen extends StatefulWidget {
  const AgentLoginScreen({super.key});

  @override
  State<AgentLoginScreen> createState() => _AgentLoginScreenState();
}

class _AgentLoginScreenState extends State<AgentLoginScreen> {
  final _idCtrl       = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool  _loading      = false;
  bool  _obscure      = true;
  String? _error;
  bool  _isOnline     = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
  }

  @override
  void dispose() {
    _idCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final online = await ApiService().hasInternetConnection();
    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _login() async {
    final id   = _idCtrl.text.trim();
    final pass = _passCtrl.text;

    if (id.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Veuillez remplir tous les champs');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final result = await AuthService.login(id, pass);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      final agent = result['agent'] as Agent;
      
      // Redirection selon le rôle
      if (agent.isAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboardScreen(admin: agent)),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AgentDashboardScreen()),
        );
      }
    } else {
      final err = result['error'] as String?;
      final msg = result['message'] as String?;
      
      setState(() {
        if (err == 'SESSION_EXPIRED') {
          _error = 'Session expirée, veuillez vous reconnecter';
        } else if (err == 'INVALID_CREDENTIALS') {
          _error = msg ?? 'Identifiants ou mot de passe incorrects';
        } else {
          _error = msg ?? err ?? 'Erreur de connexion';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF059669);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // ── Retour ──────────────────────────────────────────────────
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // ── Logo ─────────────────────────────────────────────────────
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: green.withOpacity(0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.shield_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 20),

              Text(
                'NaissanceChain',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 4),

              Text(
                'Registre Civil National — République de Guinée',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: const Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 36),

              // ── Formulaire ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre section
                    Row(children: [
                      Container(
                          width: 4,
                          height: 22,
                          decoration: BoxDecoration(
                              color: green,
                              borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 10),
                      Text(
                        'Connexion Agent',
                        style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A)),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ID Agent
                    _label('IDENTIFIANT AGENT'),
                    const SizedBox(height: 8),
                    _field(
                      controller: _idCtrl,
                      hint: 'ex: ADMIN-0001',
                      icon: Icons.badge_outlined,
                      caps: TextCapitalization.characters,
                    ),

                    const SizedBox(height: 18),

                    // Mot de passe
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _label('MOT DE PASSE'),
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                          child: Text('Oublié ?',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: green)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _field(
                      controller: _passCtrl,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),

                    // Erreur
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(children: [
                          Icon(Icons.error_outline,
                              color: Colors.red.shade600, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(_error!,
                                style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: Colors.red.shade700)),
                          ),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Bouton
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.login_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Se connecter',
                                      style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 24),

              // ── Statut réseau ────────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? green.withOpacity(0.08)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? green
                          : const Color(0xFFF59E0B),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isOnline ? 'SYSTÈME EN LIGNE' : 'HORS LIGNE',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _isOnline
                          ? green
                          : const Color(0xFFF59E0B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
              ),

              const SizedBox(height: 32),

              Text(
                'MIABE Hackathon 2026 · République de Guinée',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
            letterSpacing: 0.5),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextCapitalization caps = TextCapitalization.none,
  }) =>
      TextFormField(
        controller: controller,
        obscureText: obscure,
        textCapitalization: caps,
        style: GoogleFonts.poppins(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
              color: const Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
            ),
          ),
          suffixIcon: suffix,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF059669), width: 2)),
        ),
      );
}
