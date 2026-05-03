import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../role_selection_screen.dart';
import 'citizen_birth_detail_screen.dart';
import 'citizen_requests_screen.dart';
import 'citizen_new_request_screen.dart';
import 'citizen_profile_screen.dart';

class CitizenDashboardScreen extends StatefulWidget {
  const CitizenDashboardScreen({super.key});

  @override
  State<CitizenDashboardScreen> createState() => _CitizenDashboardScreenState();
}

class _CitizenDashboardScreenState extends State<CitizenDashboardScreen> {
  List<Map<String, dynamic>> _children = [];
  Map<String, dynamic>? _userInfo;
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final api = ApiService();

      // Récupérer les enfants via la bonne route
      final childrenRes = await api.getMyChildren();
      // Récupérer le profil
      final meRes = await api.getMe();

      // Session expirée
      if (childrenRes['statusCode'] == 401 || meRes['statusCode'] == 401) {
        _redirectToLogin();
        return;
      }

      if (!mounted) return;
      setState(() {
        _children = List<Map<String, dynamic>>.from(
            childrenRes['data'] ?? []);
        _userInfo = meRes['data'] as Map<String, dynamic>?;
        _loading  = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = 'Erreur de chargement'; _loading = false; });
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
    final name = _userInfo?['fullName'] as String? ?? 'Famille';
    final lastName = name.split(' ').last;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
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
                          Text('Famille $lastName',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B))),
                        ]),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout_rounded,
                        color: Color(0xFF64748B)),
                    tooltip: 'Déconnexion',
                  ),
                ]),
              ),
            ),

            // ── Hero card ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bonjour, Famille $lastName 👋',
                            style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(
                          'Vos registres familiaux sont sécurisés\nsur la blockchain nationale.',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.75)),
                        ),
                      ]),
                ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              ),
            ),

            // ── Stats ────────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _StatCard(
                    title: '${_children.length}',
                    subtitle: 'Enfants enregistrés',
                    icon: Icons.child_care_rounded,
                    color: const Color(0xFF059669),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    title: '${_children.where((c) => c['blockchainHash'] != null).length}',
                    subtitle: 'Certifiés blockchain',
                    icon: Icons.verified_rounded,
                    color: const Color(0xFF3B82F6),
                  ),
                ]),
              ),
            ),

            // ── Section enfants ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Enfants enregistrés',
                          style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A))),
                      Text('Mis à jour aujourd\'hui',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFF64748B))),
                    ]),
              ),
            ),

            // ── Liste enfants ────────────────────────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    Icon(Icons.error_outline,
                        color: Colors.red[300], size: 48),
                    const SizedBox(height: 8),
                    Text(_error!,
                        style: GoogleFonts.poppins(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _load,
                        child: const Text('Réessayer')),
                  ]),
                ),
              )
            else if (_children.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(children: [
                    Icon(Icons.child_care_outlined,
                        size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Aucun enfant enregistré',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: const Color(0xFF64748B))),
                  ]),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final child = _children[i];
                    return _ChildCard(
                      child: child,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CitizenBirthDetailScreen(birthData: child),
                        ),
                      ),
                    ).animate().fadeIn(delay: (i * 100).ms);
                  },
                  childCount: _children.length,
                ),
              ),

            // ── CTA Nouveau-né ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CitizenNewRequestScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nouveau-né ?',
                                  style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF92400E))),
                              const SizedBox(height: 4),
                              Text(
                                'Lancez une demande d\'acte de naissance sécurisée.',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFFB45309)),
                              ),
                            ]),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_rounded,
                            color: Colors.white),
                      ),
                    ]),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ]),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        onAccueil: () {},
        onActes: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CitizenRequestsScreen())),
        onDemande: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const CitizenNewRequestScreen())),
        onProfil: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CitizenProfileScreen())),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.subtitle, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A))),
                Text(subtitle,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF64748B))),
              ]),
            ),
          ]),
        ),
      );
}

class _ChildCard extends StatelessWidget {
  final Map<String, dynamic> child;
  final VoidCallback onTap;
  const _ChildCard({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final certified = child['blockchainHash'] != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  child['childGender'] == 'F' ? Icons.face_3 : Icons.face,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${child['childFirstName']} ${child['childLastName']}',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A)),
                      ),
                      Text(
                        _fmtDate(child['dateOfBirth']),
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF64748B)),
                      ),
                    ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: certified
                      ? const Color(0xFFD1FAE5)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  certified ? 'CERTIFIÉ' : 'EN ATTENTE',
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: certified
                        ? const Color(0xFF059669)
                        : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: Text('ACCÉDER À L\'ACTE',
                    style: GoogleFonts.poppins(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ]),
        ),
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
    } catch (_) { return raw.toString(); }
  }
}

class _BottomNav extends StatelessWidget {
  final VoidCallback onAccueil, onActes, onDemande, onProfil;
  const _BottomNav({required this.onAccueil, required this.onActes, required this.onDemande, required this.onProfil});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Item(icon: Icons.home_rounded,        label: 'ACCUEIL', active: true,  onTap: onAccueil),
            _Item(icon: Icons.description_rounded, label: 'MES ACTES', active: false, onTap: onActes),
            _Item(icon: Icons.add_circle_outline,  label: 'DEMANDE', active: false, onTap: onDemande),
            _Item(icon: Icons.person_outline,      label: 'PROFIL',  active: false, onTap: onProfil),
          ]),
        ),
      );
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Item({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? const Color(0xFF059669) : const Color(0xFF94A3B8), size: 24),
          const SizedBox(height: 3),
          Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600,
              color: active ? const Color(0xFF059669) : const Color(0xFF94A3B8))),
        ]),
      );
}
