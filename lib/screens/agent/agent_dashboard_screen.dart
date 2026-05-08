import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/offline_service.dart';
import '../../services/auth_service.dart';
import 'agent_register_wizard_screen.dart';
import 'agent_history_screen.dart';
import 'agent_profile_screen.dart';
import 'agent_sync_screen.dart';
import '../role_selection_screen.dart';

class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({super.key});

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  int    _tab        = 0;
  bool   _isOnline   = true;

  // Données home
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _recentBirths = [];
  List<Map<String, dynamic>> _pendingSync  = [];
  bool   _loadingHome = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadHome();
  }

  Future<void> _checkConnectivity() async {
    final online = await ApiService().hasInternetConnection();
    if (mounted) setState(() => _isOnline = online);
  }

  Future<void> _loadHome() async {
    setState(() => _loadingHome = true);
    try {
      final api     = ApiService();
      final offline = OfflineService();

      final statsRes  = await api.getDashboardStats();
      final birthsRes = await api.getBirths(limit: 5);

      // Rediriger vers login UNIQUEMENT si le token est explicitement rejeté (401)
      // Ne pas rediriger sur erreur réseau (statusCode absent ou null)
      if (statsRes['statusCode'] == 401 || birthsRes['statusCode'] == 401) {
        if (mounted) _redirectToLogin();
        return;
      }

      final pending = await offline.getOfflineBirths();

      if (!mounted) return;
      setState(() {
        _stats = statsRes['data'] as Map<String, dynamic>?;
        final birthsData = birthsRes['data'] as Map<String, dynamic>?;
        _recentBirths = List<Map<String, dynamic>>.from(
            birthsData?['births'] ?? []);
        _pendingSync  = pending;
        _loadingHome  = false;
      });
    } catch (_) {
      // Erreur réseau ou autre — on ne redirige PAS vers login
      if (mounted) setState(() => _loadingHome = false);
    }
  }

  void _redirectToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      (r) => false,
    );
  }

  Future<void> _logout() async {
    await AuthService.logout();
    _redirectToLogin();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _HomeTab(
        stats: _stats,
        recentBirths: _recentBirths,
        pendingSync: _pendingSync,
        isOnline: _isOnline,
        loading: _loadingHome,
        onRefresh: _loadHome,
        onNewRecord: () => setState(() => _tab = 1),
      ),
      const AgentRegisterWizardScreen(),
      const AgentHistoryScreen(),
      AgentProfileScreen(onLogout: _logout),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: screens[_tab],
      bottomNavigationBar: _BottomNav(
        current: _tab,
        pendingCount: _pendingSync.length,
        onTap: (i) => setState(() => _tab = i),
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final List<Map<String, dynamic>> recentBirths;
  final List<Map<String, dynamic>> pendingSync;
  final bool isOnline;
  final bool loading;
  final VoidCallback onRefresh;
  final VoidCallback onNewRecord;

  const _HomeTab({
    required this.stats,
    required this.recentBirths,
    required this.pendingSync,
    required this.isOnline,
    required this.loading,
    required this.onRefresh,
    required this.onNewRecord,
  });

  @override
  Widget build(BuildContext context) {
    final agent = AuthService.currentAgent;

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield_rounded,
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('NaissanceChain',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        isOnline ? 'Système en ligne' : 'Mode hors-ligne',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isOnline
                              ? const Color(0xFF059669)
                              : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (pendingSync.isNotEmpty)
                  GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AgentSyncScreen())),
                    child: Stack(children: [
                      const Icon(Icons.notifications_outlined, size: 26),
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                        ),
                      ),
                    ]),
                  ),
              ]),
            ),
          ),

          // ── Salutation ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${agent?.firstName ?? 'Agent'} 👋',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A)),
                  ),
                  Text(
                    'Terminal de registre civil numérique',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: const Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ),

          // ── Bannière hors-ligne ──────────────────────────────────────────
          if (!isOnline || pendingSync.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AgentSyncScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF451A03),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      const Icon(Icons.wifi_off,
                          color: Color(0xFFFCD34D), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          !isOnline
                              ? 'MODE HORS-LIGNE ACTIF'
                              : '${pendingSync.length} acte(s) en attente de sync',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFCD34D)),
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Color(0xFFFCD34D)),
                    ]),
                  ),
                ).animate().fadeIn(),
              ),
            ),

          // ── Stats ────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.how_to_reg,
                    iconColor: const Color(0xFF059669),
                    iconBg: const Color(0xFFD1FAE5),
                    value: (stats?['birthsThisMonth'] ?? 0).toString(),
                    label: 'CE MOIS',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.sync_problem,
                    iconColor: const Color(0xFFDC2626),
                    iconBg: const Color(0xFFFEE2E2),
                    value: pendingSync.length.toString().padLeft(2, '0'),
                    label: 'À SYNCHRONISER',
                  ),
                ),
              ]),
            ),
          ),

          // ── Bouton Nouvel Enregistrement ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: GestureDetector(
                onTap: onNewRecord,
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'NOUVEL ENREGISTREMENT',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
            ),
          ),

          // ── Activité récente ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Activité récente',
                      style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A))),
                ],
              ),
            ),
          ),

          if (loading)
            const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()))
          else if (recentBirths.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(children: [
                  Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  Text('Aucune activité récente',
                      style: GoogleFonts.poppins(
                          fontSize: 15, color: const Color(0xFF64748B))),
                ]),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final b = recentBirths[i];
                  final synced = b['blockchainHash'] != null;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            b['childGender'] == 'F'
                                ? Icons.face_3
                                : Icons.face,
                            color: const Color(0xFF06B6D4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${b['childLastName']}, ${b['childFirstName']}',
                                style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A)),
                              ),
                              Text(
                                _fmtDate(b['dateOfBirth']),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: synced
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            synced ? 'SYNC' : 'PENDING',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: synced
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ).animate().fadeIn(delay: (i * 80).ms);
                },
                childCount: recentBirths.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString());
      const m = ['Jan','Fév','Mar','Avr','Mai','Juin',
                  'Juil','Août','Sep','Oct','Nov','Déc'];
      return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}

// ── Widgets partagés ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String value, label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 14),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A))),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.5)),
        ]),
      );
}

class _BottomNav extends StatelessWidget {
  final int current;
  final int pendingCount;
  final ValueChanged<int> onTap;

  const _BottomNav({
    required this.current,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 16,
                offset: const Offset(0, -4))
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(icon: Icons.home_rounded,      label: 'Accueil',  active: current == 0, onTap: () => onTap(0)),
              _NavItem(icon: Icons.person_add_alt_1,  label: 'Enreg.',   active: current == 1, onTap: () => onTap(1)),
              _NavItem(icon: Icons.history_rounded,   label: 'Historique', active: current == 2, onTap: () => onTap(2), badge: pendingCount),
              _NavItem(icon: Icons.settings_rounded,  label: 'Profil',   active: current == 3, onTap: () => onTap(3)),
            ],
          ),
        ),
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badge;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? const Color(0xFFD1FAE5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(children: [
              Icon(icon,
                  color: active
                      ? const Color(0xFF059669)
                      : const Color(0xFF94A3B8),
                  size: 24),
              if (badge > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                  ),
                ),
            ]),
            const SizedBox(height: 3),
            Text(label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight:
                      active ? FontWeight.w600 : FontWeight.w500,
                  color: active
                      ? const Color(0xFF059669)
                      : const Color(0xFF94A3B8),
                )),
          ]),
        ),
      );
}
