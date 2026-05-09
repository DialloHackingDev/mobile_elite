import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

/// Audit and Security screen with activity and registration listings.
class AdminAuditScreen extends StatefulWidget {
  final Map<String, dynamic>? auditData;

  const AdminAuditScreen({Key? key, this.auditData}) : super(key: key);

  @override
  State<AdminAuditScreen> createState() => _AdminAuditScreenState();
}

class _AdminAuditScreenState extends State<AdminAuditScreen> {
  String _selectedFilter = 'Tout';
  late Future<Map<String, dynamic>> _auditDataFuture;

  @override
  void initState() {
    super.initState();
    _auditDataFuture = _loadAuditFromAPI();
  }

  Future<Map<String, dynamic>> _loadAuditFromAPI() async {
    try {
      final api = ApiService();
      final response = await api.getFast('/dashboard/audit');
      return response;
    } catch (e) {
      // ignore: avoid_print
      print('Erreur chargement audit: $e');
      return {'births': [], 'agents': [], 'total': 0};
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
            Text(
              'Audit & Sécurité',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
              const SizedBox(height: 8),
              Text(
                "Journal d'activité et surveillance du système",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              // Filters
              Row(
                children: [
                  _FilterChip(
                    label: 'Tout',
                    isActive: _selectedFilter == 'Tout',
                    onTap: () => setState(() => _selectedFilter = 'Tout'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Actes',
                    isActive: _selectedFilter == 'Actes',
                    onTap: () => setState(() => _selectedFilter = 'Actes'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Agents',
                    isActive: _selectedFilter == 'Agents',
                    onTap: () => setState(() => _selectedFilter = 'Agents'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Alertes',
                    isActive: _selectedFilter == 'Alertes',
                    onTap: () => setState(() => _selectedFilter = 'Alertes'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FutureBuilder<Map<String, dynamic>>(
                future: _auditDataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snapshot.data ?? {};
                  final births = (data['births'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                  final agents = (data['agents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
                  final alerts = (data['alerts'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedFilter == 'Tout' || _selectedFilter == 'Actes') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                "Dernières Inscriptions au Registre",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Row(
                              children: const [
                                Icon(Icons.sync, size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  "MÀJ",
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF10B981)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: births.take(5).toList().asMap().entries.map((entry) {
                              final b = entry.value;
                              final isLast = entry.key == births.take(5).length - 1;
                              return Column(
                                children: [
                                  _RegistrationRow(
                                    blockNum: b['blockNum'] ?? '0',
                                    hash: b['hash'] ?? 'N/A',
                                    type: 'Naissance',
                                    status: b['status'] ?? 'VALID',
                                  ),
                                  if (!isLast) const Divider(height: 1, indent: 16, endIndent: 16),
                                ],
                              );
                            }).toList(),
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                        const SizedBox(height: 24),
                      ],

                      if (_selectedFilter == 'Tout' || _selectedFilter == 'Agents' || _selectedFilter == 'Alertes') ...[
                        Text(
                          'Activité Récente',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 16),
                        if (_selectedFilter == 'Tout' || _selectedFilter == 'Agents')
                          ...agents.take(3).map((a) => _CustomActivityCard(
                            icon: Icons.person_add_outlined,
                            iconColor: const Color(0xFF06B6D4),
                            bgColor: const Color(0xFFDBEAFE),
                            title: 'Nouvel Agent Enregistré',
                            description: "Agent ${a['name']} ajouté à la région ${a['status']}",
                            time: 'Récemment',
                          )),
                        if (_selectedFilter == 'Tout' || _selectedFilter == 'Alertes')
                          ...alerts.map((al) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: _CustomActivityCard(
                              icon: Icons.warning_amber_outlined,
                              iconColor: const Color(0xFFF59E0B),
                              bgColor: const Color(0xFFFEF3C7),
                              title: al['type'] ?? 'Alerte',
                              description: al['message'] ?? 'Problème détecté',
                              time: 'Maintenant',
                            ),
                          )),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
  }
}

// ---------- Helper Widgets ----------

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _RegistrationRow extends StatelessWidget {
  final String blockNum;
  final String hash;
  final String type;
  final String status;

  const _RegistrationRow({required this.blockNum, required this.hash, required this.type, required this.status});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'valid':
        statusColor = const Color(0xFF10B981);
        break;
      case 'pending':
        statusColor = const Color(0xFFF59E0B);
        break;
      default:
        statusColor = const Color(0xFF64748B);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bloc $blockNum', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                Text(hash, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
              ]),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(type, style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF64748B))),
              Text(status.toUpperCase(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CustomActivityCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String title;
  final String description;
  final String time;

  const _CustomActivityCard({required this.icon, required this.iconColor, required this.bgColor, required this.title, required this.description, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Text(description, style: GoogleFonts.poppins(fontSize: 10, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w600, color: iconColor)),
        ],
      ),
    );
  }
}
