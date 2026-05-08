import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import '../../models/agent.dart';

class AgentProfileScreen extends StatelessWidget {
  final VoidCallback onLogout;
  const AgentProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final Agent? agent = AuthService.currentAgent;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // ── Header ──────────────────────────────────────────────────────
            Row(children: [
              Text('Profil',
                  style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A))),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                          color: Color(0xFF059669), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('ACTIF',
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669))),
                ]),
              ),
            ]),

            const SizedBox(height: 28),

            // ── Avatar ───────────────────────────────────────────────────────
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF059669), Color(0xFF047857)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF059669).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: Center(
                child: Text(
                  agent?.firstName.isNotEmpty == true
                      ? agent!.firstName[0].toUpperCase()
                      : 'A',
                  style: GoogleFonts.poppins(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),

            const SizedBox(height: 14),

            Text(
              agent?.fullName ?? 'Agent',
              style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A)),
            ),

            const SizedBox(height: 6),

            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                agent?.role ?? 'AGENT',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF06B6D4)),
              ),
            ),

            const SizedBox(height: 28),

            // ── Infos ────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(children: [
                _InfoRow(
                    icon: Icons.badge_outlined,
                    label: 'ID Agent',
                    value: agent?.nationalAgentId ?? '—'),
                const Divider(height: 20),
                _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Préfecture',
                    value: agent?.prefectureAssignment ?? '—'),
                const Divider(height: 20),
                _InfoRow(
                    icon: Icons.verified_user_outlined,
                    label: '2FA',
                    value: agent?.twoFactorEnabled == true
                        ? 'Activé'
                        : 'Désactivé'),
                const Divider(height: 20),
                _InfoRow(
                    icon: Icons.access_time_outlined,
                    label: 'Dernière connexion',
                    value: agent?.lastLogin != null
                        ? _fmtDate(agent!.lastLogin!)
                        : 'Première connexion'),
              ]),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 20),

            // ── Actions ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4))
                ],
              ),
              child: Column(children: [
                _ActionTile(
                    icon: Icons.security_outlined,
                    title: 'Sécurité & 2FA',
                    subtitle: 'Configurer l\'authentification à deux facteurs',
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Fonctionnalité à venir')))),
                const Divider(height: 16),
                _ActionTile(
                    icon: Icons.help_outline,
                    title: 'Aide & Support',
                    subtitle: 'Contacter l\'assistance technique',
                    onTap: () {}),
                const Divider(height: 16),
                _ActionTile(
                    icon: Icons.info_outline,
                    title: 'À propos',
                    subtitle: 'NaissanceChain v1.0 — MIABE 2026',
                    onTap: () {}),
              ]),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 28),

            // ── Déconnexion ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: Text('Se déconnecter',
                    style: GoogleFonts.poppins(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    const m = ['Jan','Fév','Mar','Avr','Mai','Juin',
                'Juil','Août','Sep','Oct','Nov','Déc'];
    return '${dt.day} ${m[dt.month - 1]} ${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF64748B), size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 11, color: const Color(0xFF94A3B8))),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A))),
          ]),
        ),
      ]);
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _ActionTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: const Color(0xFF64748B), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A))),
                    Text(subtitle,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: const Color(0xFF94A3B8))),
                  ]),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ]),
        ),
      );
}
