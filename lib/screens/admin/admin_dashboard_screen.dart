import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/agent.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../role_selection_screen.dart';
import 'admin_agents_screen.dart';
import 'admin_network_screen.dart';
import 'admin_audit_screen.dart';
import '../agent/agent_register_wizard_screen.dart';

/// Tableau de bord Admin - Supervision nationale du système
class AdminDashboardScreen extends StatefulWidget {
  final Agent admin;

  const AdminDashboardScreen({super.key, required this.admin});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _nationalStats;
  Map<String, dynamic>? _regionalData;
  List<Map<String, dynamic>> _pendingRequests = [];

  @override
  void initState() {
    super.initState();
    _loadNationalData();
  }

  Future<void> _loadNationalData() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      // Récupérer les données avec cache (ultra-rapide)
      final statsRes = await api.getFast('/dashboard/stats');
      final mapRes = await api.getFast('/dashboard/map');

      if (statsRes?['statusCode'] == 401) {
        if (mounted) {
          AuthService.logout().then((_) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
              (r) => false,
            );
          });
        }
        return;
      }

      if (mounted) {
        setState(() {
          _nationalStats = statsRes?['data'] ?? statsRes;
          _regionalData = mapRes?['data'] ?? mapRes;
          _isLoading = false;
        });
        _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRequests() async {
    try {
      final api = ApiService();
      final res = await api.getFast('/requests/pending/all');
      if (mounted && res != null && res['success'] == true) {
        setState(() {
          _pendingRequests =
              (res['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        });
      }
    } catch (e) {
      print('Erreur chargement demandes: $e');
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
        (r) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _NationalOverviewTab(
        stats: _nationalStats,
        regionalData: _regionalData,
        admin: widget.admin,
        onRefresh: _loadNationalData,
      ),
      _RequestsTab(requests: _pendingRequests, onRefresh: _loadRequests),
      const AdminAgentsScreen(),
      const AdminNetworkScreen(),
      const AdminAuditScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Supervision Nationale',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Indicateur en ligne
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'EN LIGNE',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Bouton déconnexion
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: screens[_currentIndex],
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AgentRegisterWizardScreen()),
                ).then((_) => _loadNationalData());
              },
              backgroundColor: const Color(0xFF10B981),
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text(
                'NOUVEL ACTE',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Tableau',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.assignment_outlined,
                  activeIcon: Icons.assignment,
                  label: 'Demandes',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Agents',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.wifi_tethering,
                  activeIcon: Icons.wifi_tethering,
                  label: 'Réseau',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.security_outlined,
                  activeIcon: Icons.security,
                  label: 'Audit',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Onglet Vue d'ensemble nationale
class _NationalOverviewTab extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final Map<String, dynamic>? regionalData;
  final Agent admin;
  final VoidCallback onRefresh;

  const _NationalOverviewTab({
    required this.stats,
    this.regionalData,
    required this.admin,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF10B981),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // En-tête avec info admin
          _AdminHeader(admin: admin),
          const SizedBox(height: 24),

          // KPIs Nationaux
          _NationalKPIs(stats: stats),
          const SizedBox(height: 24),

          // Activité géographique (Carte)
          _GeographicActivityCard(stats: stats, regionalData: regionalData),
          const SizedBox(height: 24),

          // Statistiques par Région/Ville (DEMANDÉ)
          _RegionalStatsCard(stats: stats, regionalData: regionalData),
          const SizedBox(height: 24),

          // Objectifs mensuels
          _SecurityStatusCard(stats: stats),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _AdminHeader extends StatelessWidget {
  final Agent admin;

  const _AdminHeader({required this.admin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administrateur',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                Text(
                  admin.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Ministère de l\'État Civil',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NationalKPIs extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _NationalKPIs({this.stats});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Indicateurs Nationaux',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.child_care,
                value: '${stats?['totalBirths']?.toString() ?? '1248392'}',
                label: 'Total Naissances',
                trend: '+${stats?['birthsToday'] ?? 342}/jour',
                trendUp: true,
                color: const Color(0xFF059669),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.public,
                value: '${stats?['coverageRate'] ?? 85}%',
                label: 'Couverture Nationale',
                trend: 'Objectif: 100%',
                trendUp: true,
                color: const Color(0xFF06B6D4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                icon: Icons.badge,
                value: '${stats?['activeAgents'] ?? 4120}',
                label: 'Agents Actifs',
                trend: '124 établissements',
                trendUp: null,
                color: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                icon: Icons.sync,
                value: '${stats?['syncRate'] ?? 99.9}%',
                label: 'Taux Sync',
                trend: '${stats?['blockchainNodes'] ?? 124} nœuds',
                trendUp: true,
                color: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? trend;
  final bool? trendUp;
  final Color color;

  const _KpiCard({
    required this.icon,
    required this.value,
    required this.label,
    this.trend,
    this.trendUp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (trendUp != null)
                  Icon(
                    trendUp! ? Icons.trending_up : Icons.trending_down,
                    color: trendUp!
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    size: 14,
                  ),
                if (trendUp != null) const SizedBox(width: 4),
                Text(
                  trend!,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GeographicActivityCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final Map<String, dynamic>? regionalData;
  const _GeographicActivityCard({this.stats, this.regionalData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activité Géographique',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'FILTRES',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Dernières synchronisations par région',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),
          // Carte placeholder
          InkWell(
            onTap: () {
              // Afficher les détails géographiques
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) =>
                    _RegionDetailsSheet(regionalData: regionalData),
              );
            },
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: AssetImage('assets/images/map_placeholder.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.touch_app, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Text(
                        'Cliquez pour explorer',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyGoalsCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _MonthlyGoalsCard({this.stats});

  @override
  Widget build(BuildContext context) {
    // Calcul simple pour la démo
    final birthsThisMonth = (stats?['birthsThisMonth'] ?? 0) as int;
    final target = 500; // Objectif arbitraire de 500 par mois

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Objectifs Mensuels',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          _GoalProgress(
            label: 'Objectif de Recensement',
            current: birthsThisMonth,
            target: target,
            color: const Color(0xFF059669),
          ),
          const SizedBox(height: 12),
          _GoalProgress(
            label: 'Validation Blockchain',
            current: (stats?['syncRate'] ?? 0) as int,
            target: 100,
            color: const Color(0xFF06B6D4),
          ),
        ],
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  final String label;
  final int current;
  final int target;
  final Color color;

  const _GoalProgress({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = current / target;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: progress >= 1 ? const Color(0xFF059669) : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1 ? const Color(0xFF059669) : color,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

class _RegionalStatsCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  final Map<String, dynamic>? regionalData;
  const _RegionalStatsCard({this.stats, this.regionalData});

  @override
  Widget build(BuildContext context) {
    // Transformer les données du backend pour l'affichage
    final List<Map<String, dynamic>> regions = [];

    if (regionalData != null && regionalData!['prefectures'] != null) {
      final List prefList = regionalData!['prefectures'];
      for (var i = 0; i < prefList.length; i++) {
        final item = prefList[i];
        regions.add({
          'name': item['prefecture'] ?? 'Inconnu',
          'count': item['count'] ?? 0,
          'color': [
            const Color(0xFF10B981),
            const Color(0xFF3B82F6),
            const Color(0xFFF59E0B),
            const Color(0xFF7C3AED),
            const Color(0xFFEF4444),
            const Color(0xFF06B6D4),
            const Color(0xFFEC4899),
            const Color(0xFF6366F1),
          ][i % 8],
        });
      }
    } else {
      regions.addAll([
        {'name': 'Conakry', 'count': 42839, 'color': const Color(0xFF10B981)},
        {'name': 'Kankan', 'count': 18230, 'color': const Color(0xFFF59E0B)},
        {'name': 'Kindia', 'count': 15420, 'color': const Color(0xFF3B82F6)},
        {'name': 'Labé', 'count': 12100, 'color': const Color(0xFF8B5CF6)},
        {'name': 'Nzérékoré', 'count': 9840, 'color': const Color(0xFFEF4444)},
        {'name': 'Boké', 'count': 8500, 'color': const Color(0xFF06B6D4)},
        {'name': 'Mamou', 'count': 7200, 'color': const Color(0xFFF97316)},
        {'name': 'Faranah', 'count': 6800, 'color': const Color(0xFFEC4899)},
      ]);
    }

    regions.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));
    final maxCount = regions.isEmpty ? 1 : (regions.first['count'] as int);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Répartition par Région',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Icon(Icons.bar_chart, color: Color(0xFF64748B), size: 20),
            ],
          ),
          const SizedBox(height: 20),
          ...regions.map((reg) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: reg['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reg['name'] as String,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${reg['count']} actes',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (reg['count'] as int) / maxCount,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(
                            reg['color'] as Color),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _SecurityStatusCard extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _SecurityStatusCard({this.stats});

  @override
  Widget build(BuildContext context) {
    final alertCount = (stats?['alerts'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Color(0xFF059669),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sécurité du Réseau',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      alertCount == 0
                          ? 'Tous les nœuds validateurs sont opérationnels'
                          : '$alertCount alertes système détectées',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SecurityIndicator(
                label: 'Intégrité',
                value: '${stats?['syncRate'] ?? 100}%',
                isGood: true,
              ),
              const SizedBox(width: 8),
              _SecurityIndicator(
                label: 'Latence',
                value: '${stats?['avgBlockTime'] ?? 1.2}s',
                isGood: true,
              ),
              const SizedBox(width: 8),
              _SecurityIndicator(
                label: 'Alertes',
                value: '$alertCount',
                isGood: alertCount == 0,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecurityIndicator extends StatelessWidget {
  final String label;
  final String value;
  final bool isGood;

  const _SecurityIndicator({
    required this.label,
    required this.value,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color:
                    isGood ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF10B981).withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionDetailsSheet extends StatelessWidget {
  final Map<String, dynamic>? regionalData;

  const _RegionDetailsSheet({this.regionalData});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> regions = [];
    if (regionalData != null && regionalData!['success'] == true) {
      final list = regionalData!['data'] as List?;
      if (list != null) {
        for (var i = 0; i < list.length; i++) {
          final item = list[i];
          regions.add({
            'name': item['prefecture'] ?? 'Inconnu',
            'count': item['count'] ?? 0,
            'color': [
              const Color(0xFF10B981),
              const Color(0xFFF59E0B),
              const Color(0xFF3B82F6),
              const Color(0xFF8B5CF6),
              const Color(0xFFEF4444),
              const Color(0xFF06B6D4),
              const Color(0xFFF97316),
              const Color(0xFFEC4899),
            ][i % 8],
          });
        }
      }
    }

    if (regions.isEmpty) {
      regions.addAll([
        {'name': 'Conakry', 'count': 42839, 'color': const Color(0xFF10B981)},
        {'name': 'Kankan', 'count': 18230, 'color': const Color(0xFFF59E0B)},
      ]);
    }

    regions.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Détails par Région',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: regions.length,
              itemBuilder: (context, index) {
                final reg = regions[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (reg['color'] as Color).withOpacity(0.2),
                    child:
                        Icon(Icons.location_on, color: reg['color'] as Color),
                  ),
                  title: Text(reg['name'] as String,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                  trailing: Text('${reg['count']} actes',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final List<Map<String, dynamic>> requests;
  final VoidCallback onRefresh;

  const _RequestsTab({required this.requests, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF10B981),
      child: requests.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in_outlined,
                      size: 48, color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text('Aucune demande en attente',
                      style:
                          GoogleFonts.poppins(color: const Color(0xFF64748B))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  color: Colors.white,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF10B981).withOpacity(0.1),
                      child: const Icon(Icons.description,
                          color: Color(0xFF10B981)),
                    ),
                    title: Text(
                        req['childFirstName'] != null
                            ? '${req['childFirstName']} ${req['childLastName']}'
                            : 'Demande d\'acte',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Demandeur: ${req['citizen']?['fullName'] ?? 'N/A'}'),
                        Text('Tél: ${req['citizen']?['phoneNumber'] ?? 'N/A'}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AgentRegisterWizardScreen(initialRequest: req),
                        ),
                      );
                      if (result == true) {
                        onRefresh();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
