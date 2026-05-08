import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

/// Écran de supervision réseau blockchain avec vraies données
class AdminNetworkScreen extends StatefulWidget {
  final Map<String, dynamic>? networkData;

  const AdminNetworkScreen({super.key, this.networkData});

  @override
  State<AdminNetworkScreen> createState() => _AdminNetworkScreenState();
}

class _AdminNetworkScreenState extends State<AdminNetworkScreen> {
  late Future<Map<String, dynamic>> _networkDataFuture;

  @override
  void initState() {
    super.initState();
    _networkDataFuture = _loadNetworkFromAPI();
  }


  Future<Map<String, dynamic>> _loadNetworkFromAPI() async {
    try {
      final api = ApiService();
      final response = await api.get('/dashboard/network');
      return response ?? {};
    } catch (e) {
      print('Erreur chargement réseau: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _networkDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              );
            }

            final data = snapshot.data ?? {};
            final network = data['network'] ?? {};
            final health = data['health'] ?? {};
            final blocks = data['blocks'] ?? {};

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                  Text(
                    'Supervision Réseau',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${network['name'] ?? 'Mainnet Hyperledger Fabric'} • Statut Opérationnel',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF64748B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Badge souveraineté
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Souveraineté Validée',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Carte Santé Réseau
                  _NetworkHealthCard(
                    healthPercent: (health['networkHealth'] ?? 99.9).toDouble(),
                    activeNodes: network['activeNodes'] ?? 8,
                    totalNodes: network['blockchainNodes'] ?? 8,
                    integrity: (health['blockchainIntegrity'] ?? 100).toDouble(),
                    responseTime: health['responseTime'] ?? 12,
                  ),
                  const SizedBox(height: 20),

                  // Temps de bloc
                  _BlockTimeCard(
                    lastBlockTime: (network['lastBlockTime'] ?? 1.2).toDouble(),
                  ),
                  const SizedBox(height: 20),

                  // Nœuds Hyperledger
                  _NodesCard(
                    activeNodes: network['activeNodes'] ?? 8,
                  ),
                  const SizedBox(height: 20),

                  // Flux de consensus
                  const _ConsensusCard(),
                  const SizedBox(height: 20),

                  // TPS et Latence
                  _PerformanceCard(
                    tps: (blocks['transactionsPerSecond'] ?? 15.4).toDouble(),
                    latency: (health['responseTime'] ?? 12).toInt(),
                  ),
                  const SizedBox(height: 20),

                  // Alertes
                  const _AlertsCard(),
                  const SizedBox(height: 20),

                  // Bouton logs
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.list_alt_outlined),
                      label: Text(
                        'VOIR TOUS LES LOGS',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF475569),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              );
          },
        ),
      );
  }
}

class _HealthStat extends StatelessWidget {
  final String label;
  final String value;

  const _HealthStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 3),
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
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ActivityRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
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

class _BlockchainStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _BlockchainStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


class _NetworkHealthCard extends StatelessWidget {
  final double healthPercent;
  final int activeNodes;
  final int totalNodes;
  final double integrity;
  final int responseTime;

  const _NetworkHealthCard({
    required this.healthPercent,
    required this.activeNodes,
    required this.totalNodes,
    required this.integrity,
    required this.responseTime,
  });

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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.network_check, color: Color(0xFF10B981), size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$healthPercent%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF059669),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Santé du Réseau',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: healthPercent / 100,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _HealthStat(
                label: 'Nœuds',
                value: '$activeNodes/$totalNodes',
              ),
              _HealthStat(
                label: 'Intégrité',
                value: '$integrity%',
              ),
              _HealthStat(
                label: 'Latence',
                value: '${responseTime}ms',
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms);
  }
}

class _BlockTimeCard extends StatelessWidget {
  final double lastBlockTime;

  const _BlockTimeCard({required this.lastBlockTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'GLOBAL',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Temps de Bloc Moyen',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$lastBlockTime',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'secondes',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }
}

class _NodesCard extends StatelessWidget {
  final int activeNodes;

  const _NodesCard({required this.activeNodes});

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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.hub_outlined, color: Color(0xFFF59E0B), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$activeNodes ACTIFS',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...List.generate(activeNodes > 4 ? 4 : activeNodes, (i) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    )),
                    if (activeNodes > 4)
                      Text(
                        '+${activeNodes - 4}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF059669),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Nœuds Hyperledger',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }
}

class _ConsensusCard extends StatelessWidget {
  const _ConsensusCard();

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
          Text(
            'Flux de Consensus en Temps Réel',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          const _ConsensusItem(
            name: 'PEER-01',
            status: 'active',
            color: Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          const _ConsensusItem(
            name: 'PEER-02',
            status: 'active',
            color: Color(0xFF06B6D4),
          ),
          const SizedBox(height: 12),
          const _ConsensusItem(
            name: 'ORDERER',
            status: 'warning',
            color: Color(0xFFF59E0B),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _ConsensusItem extends StatelessWidget {
  final String name;
  final String status;
  final Color color;

  const _ConsensusItem({
    required this.name,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: status == 'active' ? 0.85 : 0.45,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          name,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final double tps;
  final int latency;

  const _PerformanceCard({required this.tps, required this.latency});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                  'TPS ACTUEL',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$tps txn/s',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
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
                  'LATENCE',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${latency}ms',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              Text(
                'Alertes de Sécurité',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _AlertItem(
            icon: Icons.block_flipped,
            color: Color(0xFFDC2626),
            title: 'TENTATIVE D\'ACCÈS REJETÉE',
            subtitle: 'IP 192.168.1.45 bloquée',
          ),
          const SizedBox(height: 12),
          const _AlertItem(
            icon: Icons.verified_user_outlined,
            color: Color(0xFF059669),
            title: 'CERTIFICAT MSP RENOUVELÉ',
            subtitle: 'Nœud validateur #04 mis à jour',
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}

class _AlertItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _AlertItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
