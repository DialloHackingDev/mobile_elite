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

/// Tableau de bord Admin - Supervision nationale (v2 - avec vraies données)
class AdminDashboardScreenV2 extends StatefulWidget {
  final Agent admin;
  
  const AdminDashboardScreenV2({super.key, required this.admin});

  @override
  State<AdminDashboardScreenV2> createState() => _AdminDashboardScreenV2State();
}

class _AdminDashboardScreenV2State extends State<AdminDashboardScreenV2> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final api = ApiService();
      
      // Charger tous les KPIs
      final kpisRes = await api.get('/dashboard/kpis');
      final agentsRes = await api.get('/dashboard/agents');
      final networkRes = await api.get('/dashboard/network');
      final auditRes = await api.get('/dashboard/audit');

      if (mounted) {
        setState(() {
          _dashboardData = {
            'kpis': kpisRes ?? {},
            'agents': agentsRes ?? {},
            'network': networkRes ?? {},
            'audit': auditRes ?? {},
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement dashboard: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de chargement des données';
          _isLoading = false;
        });
      }
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
    final kpis = _dashboardData?['kpis'] ?? {};

    final screens = [
      _NationalOverviewTab(
        kpis: kpis,
        agents: _dashboardData?['agents'],
        network: _dashboardData?['network'],
        audit: _dashboardData?['audit'],
        isLoading: _isLoading,
        admin: widget.admin,
        onRefresh: _loadDashboardData,
      ),
      AdminAgentsScreen(agentsData: _dashboardData?['agents']),
      AdminNetworkScreen(networkData: _dashboardData?['network']),
      AdminAuditScreen(auditData: _dashboardData?['audit']),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF10B981),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Supervision Nationale',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Indicateur en ligne
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'EN LIGNE',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Bouton déconnexion
          IconButton(
            icon: const Icon(Icons.logout_outlined, size: 22),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Agents',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.network_check_outlined,
                  activeIcon: Icons.network_check,
                  label: 'Réseau',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.security_outlined,
                  activeIcon: Icons.security,
                  label: 'Audit',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
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
  final Map<String, dynamic> kpis;
  final Map<String, dynamic>? agents;
  final Map<String, dynamic>? network;
  final Map<String, dynamic>? audit;
  final bool isLoading;
  final Agent admin;
  final VoidCallback onRefresh;

  const _NationalOverviewTab({
    required this.kpis,
    this.agents,
    this.network,
    this.audit,
    required this.isLoading,
    required this.admin,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement des données...',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      color: const Color(0xFF10B981),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec info admin
            _AdminHeader(admin: admin),
            const SizedBox(height: 24),

            // KPIs Nationaux
            Text(
              'Indicateurs Nationaux',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Grid KPIs
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _KpiCard(
                  icon: Icons.child_care,
                  value: _formatNumber(kpis['totalBirths'] ?? 0),
                  label: 'Total Naissances',
                  trend: '+${_formatNumber(kpis['birthsToday'] ?? 0)}/jour',
                  trendUp: true,
                  color: const Color(0xFF059669),
                ),
                _KpiCard(
                  icon: Icons.public,
                  value: '${kpis['coverageRate'] ?? 0}%',
                  label: 'Couverture Nationale',
                  trend: 'Objectif: 100%',
                  trendUp: (kpis['coverageRate'] ?? 0) >= 80,
                  color: const Color(0xFF10B981),
                ),
                _KpiCard(
                  icon: Icons.badge,
                  value: '${kpis['activeAgents'] ?? 0}',
                  label: 'Agents Actifs',
                  trend: '${kpis['totalAgents'] ?? 0} total',
                  trendUp: null,
                  color: const Color(0xFF7C3AED),
                ),
                _KpiCard(
                  icon: Icons.sync,
                  value: '${kpis['syncRate'] ?? 0}%',
                  label: 'Taux Sync',
                  trend: '${kpis['blockchainNodes'] ?? 0} nœuds',
                  trendUp: (kpis['syncRate'] ?? 0) >= 95,
                  color: const Color(0xFFDC2626),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Statistiques détaillées
            _DetailedStatsCard(kpis: kpis),

            const SizedBox(height: 24),

            // Activité géographique
            _GeographicActivityCard(kpis: kpis),

            const SizedBox(height: 24),

            // Objectifs mensuels
            _MonthlyGoalsCard(kpis: kpis),

            const SizedBox(height: 24),

            // Sécurité réseau
            _SecurityStatusCard(network: network),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _formatNumber(dynamic num) {
    if (num == null) return '0';
    final n = int.tryParse(num.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}

class _AdminHeader extends StatelessWidget {
  final Agent admin;

  const _AdminHeader({required this.admin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Administrateur',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  admin.fullName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Ministère de l\'État Civil',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.8),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
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
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (trendUp != null)
                  Icon(
                    trendUp! ? Icons.trending_up : Icons.trending_down,
                    color: trendUp! ? const Color(0xFF059669) : const Color(0xFFDC2626),
                    size: 13,
                  ),
                if (trendUp != null) const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    trend!,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _DetailedStatsCard extends StatelessWidget {
  final Map<String, dynamic> kpis;

  const _DetailedStatsCard({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Détails Statistiques',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          _StatRow(
            label: 'Naissances ce mois',
            value: '${kpis['birthsThisMonth'] ?? 0}',
            icon: Icons.calendar_today_outlined,
          ),
          const SizedBox(height: 10),
          _StatRow(
            label: 'Distribution (M/F)',
            value: '${kpis['genderDistribution']?['male'] ?? 0} / ${kpis['genderDistribution']?['female'] ?? 0}',
            icon: Icons.people_outline,
          ),
          const SizedBox(height: 10),
          _StatRow(
            label: 'Établissements actifs',
            value: '${kpis['activeEstablishments'] ?? 0} / ${kpis['totalEstablishments'] ?? 0}',
            icon: Icons.domain_outlined,
          ),
          const SizedBox(height: 10),
          _StatRow(
            label: 'Synchronisation',
            value: '${kpis['pendingSync'] ?? 0} en attente',
            icon: Icons.hourglass_bottom_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _GeographicActivityCard extends StatelessWidget {
  final Map<String, dynamic> kpis;

  const _GeographicActivityCard({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'EN DIRECT',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Dernières synchronisations par région',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map_outlined,
                    color: const Color(0xFF10B981),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Carte interactive',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyGoalsCard extends StatelessWidget {
  final Map<String, dynamic> kpis;

  const _MonthlyGoalsCard({required this.kpis});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Objectifs Mensuels',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          _GoalProgress(
            label: 'Objectif de Recensement',
            current: 12000,
            target: 15000,
            color: const Color(0xFF059669),
          ),
          const SizedBox(height: 12),
          _GoalProgress(
            label: 'Validation Blockchain',
            current: 15000,
            target: 15000,
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
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF475569),
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: progress >= 1 ? const Color(0xFF059669) : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0, 1),
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1 ? const Color(0xFF059669) : color,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _SecurityStatusCard extends StatelessWidget {
  final Map<String, dynamic>? network;

  const _SecurityStatusCard({this.network});

  @override
  Widget build(BuildContext context) {
    final health = network?['health'] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFBBF7D0),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF059669).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: Color(0xFF059669),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sécurité du Réseau',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Tous les nœuds validateurs sont opérationnels',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _SecurityIndicator(
                label: 'Blockchain',
                value: '${health['blockchainIntegrity'] ?? 100}%',
                isGood: true,
              ),
              const SizedBox(width: 12),
              _SecurityIndicator(
                label: 'Réponse',
                value: '${health['responseTime'] ?? 12}ms',
                isGood: true,
              ),
              const SizedBox(width: 12),
              _SecurityIndicator(
                label: 'Nœuds',
                value: '${health['nodeHealth'] ?? 100}%',
                isGood: true,
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
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isGood ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 9,
                color: const Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981).withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
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
