import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'agent/agent_dashboard_screen.dart';
import 'qr_display_screen.dart';

class SuccessScreen extends StatelessWidget {
  final String  babyName;
  final String  birthDate;
  final String  birthPlace;
  final String  fatherName;
  final String  motherName;
  final String  blockchainId;
  final String? nationalId;
  final bool    isOffline;

  const SuccessScreen({
    super.key,
    required this.babyName,
    required this.birthDate,
    required this.birthPlace,
    required this.fatherName,
    required this.motherName,
    required this.blockchainId,
    this.nationalId,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF059669);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                    color: primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Column(children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded,
                    size: 64, color: Colors.white),
              )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.elasticOut)
                  .then()
                  .shake(hz: 2, duration: 400.ms),

              const SizedBox(height: 20),

              Text(
                isOffline ? 'Sauvegardé localement' : 'Enregistrement réussi !',
                style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 6),

              Text(
                isOffline
                    ? 'Synchronisation automatique dès le retour en ligne'
                    : 'Acte certifié sur la blockchain nationale',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.white.withOpacity(0.85)),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 450.ms),
            ]),
          ),

          // ── Contenu ──────────────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
                if (isOffline)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(children: [
                      Icon(Icons.wifi_off,
                          color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Text('Mode hors-ligne — en attente de sync',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade700)),
                    ]),
                  ).animate().fadeIn(delay: 500.ms),

                // Infos enfant
                _Card(
                  title: 'Nouveau-né',
                  icon: Icons.child_care_rounded,
                  rows: [
                    _Row('Nom complet', babyName),
                    _Row('Date de naissance', birthDate),
                    _Row('Lieu de naissance', birthPlace),
                  ],
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 14),

                // Parents
                _Card(
                  title: 'Parents',
                  icon: Icons.family_restroom_rounded,
                  rows: [
                    _Row('Père', fatherName),
                    _Row('Mère', motherName),
                  ],
                ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 14),

                // Blockchain
                _Card(
                  title: 'Certification',
                  icon: Icons.verified_rounded,
                  iconColor: primary,
                  rows: [
                    if (nationalId != null) _Row('ID National', nationalId!),
                    _Row('Référence', blockchainId, mono: true),
                  ],
                ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // Bouton QR
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => QRDisplayScreen(
                          babyName: babyName,
                          birthDate: birthDate,
                          birthPlace: birthPlace,
                          fatherName: fatherName,
                          motherName: motherName,
                          blockchainId: blockchainId,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.qr_code_rounded, size: 20),
                    label: Text('Voir le QR Code',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ).animate().fadeIn(delay: 900.ms),

                const SizedBox(height: 12),

                // Retour dashboard
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AgentDashboardScreen()),
                      (r) => false,
                    ),
                    icon: const Icon(Icons.home_rounded, size: 20),
                    label: Text('Retour au tableau de bord',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: const BorderSide(color: Color(0xFF059669)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ).animate().fadeIn(delay: 1000.ms),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<_Row> rows;

  const _Card({
    required this.title,
    required this.icon,
    required this.rows,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? const Color(0xFF10B981);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A))),
        ]),
        const SizedBox(height: 14),
        const Divider(height: 1),
        const SizedBox(height: 14),
        ...rows,
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool mono;
  const _Row(this.label, this.value, {this.mono = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 2,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey[500])),
          ),
          Expanded(
            flex: 3,
            child: mono
                ? Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(value,
                        style: const TextStyle(
                            fontFamily: 'monospace', fontSize: 11)),
                  )
                : Text(value,
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A))),
          ),
        ]),
      );
}
