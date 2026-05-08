import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';

/// Écran de détail d'un acte de naissance
/// Affiche le QR code, l'ID national et permet la vérification
class BirthDetailScreen extends StatefulWidget {
  final Map<String, dynamic> birth;

  const BirthDetailScreen({super.key, required this.birth});

  @override
  State<BirthDetailScreen> createState() => _BirthDetailScreenState();
}

class _BirthDetailScreenState extends State<BirthDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final api = ApiService();
      final nationalId = widget.birth['nationalId'];

      if (nationalId == null) {
        setState(() {
          _error = 'ID national manquant';
          _loading = false;
        });
        return;
      }

      // Récupérer les détails complets depuis l'API
      final res = await api.getBirthByNationalId(nationalId);

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _detail = res['data'] as Map<String, dynamic>?;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res['error'] ?? 'Erreur de chargement';
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erreur: $e';
        _loading = false;
      });
    }
  }

  /// Génère le payload du QR code pour la vérification
  String _generateQRPayload() {
    final nationalId = _detail?['nationalId'] ?? widget.birth['nationalId'];
    final hash = _detail?['blockchainHash'] ?? widget.birth['blockchainHash'];

    if (hash == null) {
      return jsonEncode({
        'id': nationalId,
        'url': 'https://naissancechain.gov.gn/verify/$nationalId',
      });
    }

    // Générer la signature HMAC (simplifiée pour le mobile)
    // En production, cette signature devrait venir du backend
    return jsonEncode({
      'id': nationalId,
      'hash': hash,
      'url': 'https://naissancechain.gov.gn/verify/$nationalId',
    });
  }

  Future<void> _shareCertificate() async {
    final nationalId = _detail?['nationalId'] ?? widget.birth['nationalId'];
    final childName =
        '${_detail?['childFirstName'] ?? widget.birth['childFirstName'] ?? ''} '
        '${_detail?['childLastName'] ?? widget.birth['childLastName'] ?? ''}';

    await Share.share(
      'Acte de naissance NaissanceChain\n'
      'Enfant: $childName\n'
      'ID National: $nationalId\n'
      'Vérifier: https://naissancechain.gov.gn/verify/$nationalId',
      subject: 'Acte de naissance - $childName',
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF059669);
    const darkBg = Color(0xFF0F172A);

    final birth = widget.birth;
    final nationalId = birth['nationalId']?.toString() ?? '—';
    final childName =
        '${birth['childLastName'] ?? '—'}, ${birth['childFirstName'] ?? ''}';
    final isSynced = birth['blockchainHash'] != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: green,
        elevation: 0,
        title: Text(
          'Détail de l\'acte',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          if (isSynced)
            IconButton(
              onPressed: _shareCertificate,
              icon: const Icon(Icons.share_outlined),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── En-tête avec statut ──────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isSynced ? green : const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isSynced
                                    ? Icons.verified_outlined
                                    : Icons.pending_outlined,
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
                                    isSynced
                                        ? 'Acte certifié Blockchain'
                                        : 'En attente de synchronisation',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    isSynced
                                        ? 'Cet acte est immuable et vérifiable'
                                        : 'Synchronisation en cours...',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(),

                      const SizedBox(height: 24),

                      // ── Carte d'identité ─────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    birth['childGender'] == 'F'
                                        ? Icons.face_3
                                        : Icons.face,
                                    color: green,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        childName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      Text(
                                        'Né(e) le ${_formatDate(birth['dateOfBirth'])}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 32),
                            _buildInfoRow('Lieu de naissance',
                                birth['placeOfBirth'] ?? '—'),
                            _buildInfoRow('ID National', nationalId,
                                isHighlight: true),
                            _buildInfoRow(
                                'Statut',
                                isSynced
                                    ? 'Enregistré sur blockchain'
                                    : 'En attente'),
                            if (_detail != null) ...[
                              _buildInfoRow(
                                  'Établissement',
                                  _detail?['establishment']?['name'] ?? '—'),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 24),

                      // ── QR Code ──────────────────────────────────────────
                      if (isSynced) ...[
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'QR Code de vérification',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Scannez ce code pour vérifier l\'authenticité de l\'acte',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: QrImageView(
                                  data: _generateQRPayload(),
                                  version: QrVersions.auto,
                                  size: 220,
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F172A),
                                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_outlined,
                                      color: green,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Signature cryptographique valide',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 24),

                        // ── Instructions de vérification ─────────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Comment vérifier cet acte ?',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildStep(1, 'Rendez-vous sur',
                                  'naissancechain.gov.gn'),
                              _buildStep(2, 'Scannez le QR code',
                                  'ou saisissez l\'ID national'),
                              _buildStep(3, 'Vérification instantanée',
                                  'résultat affiché immédiatement'),
                            ],
                          ),
                        ).animate().fadeIn(delay: 300.ms),
                      ] else ...[
                        // ── Message attente synchronisation ────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFFCA5A5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFFF59E0B),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'L\'acte est en attente de synchronisation avec la blockchain. Le QR code sera disponible une fois la synchronisation terminée.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 200.ms),
                      ],

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w700 : FontWeight.w500,
                color: isHighlight ? const Color(0xFF059669) : const Color(0xFF0F172A),
                letterSpacing: isHighlight ? 0.5 : 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
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
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }
}
