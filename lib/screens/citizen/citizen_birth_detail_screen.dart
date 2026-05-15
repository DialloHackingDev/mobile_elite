import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../services/api_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../utils/platform_helper.dart';

class CitizenBirthDetailScreen extends StatefulWidget {
  final Map<String, dynamic> birthData;

  const CitizenBirthDetailScreen({super.key, required this.birthData});

  @override
  State<CitizenBirthDetailScreen> createState() => _CitizenBirthDetailScreenState();
}

class _CitizenBirthDetailScreenState extends State<CitizenBirthDetailScreen> {
  bool _isDownloading = false;

  Future<void> _downloadCertificate() async {
    // Vérifier que l'acte est bien certifié avant téléchargement
    if (widget.birthData['blockchainHash'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cet acte n'est pas encore certifié sur la blockchain"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final api = ApiService();
    final birthId = widget.birthData['nationalId'] ?? widget.birthData['id']?.toString() ?? '';
    
    if (birthId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID de l\'acte introuvable'), backgroundColor: Colors.red),
      );
      return;
    }

    final safeName = (widget.birthData['childFirstName'] ?? 'acte').toString().replaceAll(' ', '_');
    final fileName = '${safeName}_${birthId.replaceAll('/', '_')}.pdf';

    if (kIsWeb) {
      // Sur le Web, on ouvre l'URL directe avec le token en query param
      final url = '${api.baseUrl}/citizen/certificate/$birthId?token=${api.token}';
      downloadWeb(url, fileName);
      return;
    }

    setState(() => _isDownloading = true);
    try {
      final bytes = await api.downloadCertificateBytes(birthId);
      if (bytes == null || bytes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible de télécharger l\'extrait'), backgroundColor: Colors.red),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final filePath = p.join(tempDir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      // Partager / ouvrir le fichier PDF
      await Share.shareXFiles([XFile(filePath)], text: 'Acte de naissance - ${widget.birthData['childFirstName']}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Certificat prêt'), backgroundColor: Color(0xFF059669)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _shareCertificate() async {
    final message = 
      'Acte de naissance - NaissanceChain\n\n'
      'Enfant: ${widget.birthData['childFirstName']} ${widget.birthData['childLastName']}\n'
      'Né(e) le: ${_formatDate(widget.birthData['dateOfBirth'])}\n'
      'À: ${widget.birthData['placeOfBirth']}\n'
      'ID National: ${widget.birthData['nationalId']}\n\n'
      'Vérifié sur Blockchain ✅';
    
    await Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Icon(Icons.arrow_back, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'NaissanceChain',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _shareCertificate,
                      icon: const Icon(Icons.share_outlined),
                    ),
                  ],
                ),
              ),
            ),
            
            // Titre
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Détail de l\'acte',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vérifiez les informations avant le\ntéléchargement.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Carte Acte
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge Certifié (ou en attente)
                      Row(
                        children: [
                          if (widget.birthData['blockchainHash'] != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1FAE5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'CERTIFIÉ BLOCKCHAIN',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF059669),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'EN ATTENTE',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF59E0B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.qr_code_2,
                                size: 48,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Nom enfant
                      Text(
                        '${widget.birthData['childFirstName']} ${widget.birthData['childLastName']}',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // ID
                      Row(
                        children: [
                          Text(
                            'ID: ',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
                            ),
                          ),
                          Text(
                            widget.birthData['nationalId'] ?? 'En attente',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Divider
                      Divider(color: const Color(0xFFE2E8F0)),
                      
                      const SizedBox(height: 20),
                      
                      // Infos détaillées
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              label: 'DATE DE NAISSANCE',
                              value: _formatDate(widget.birthData['dateOfBirth']),
                              icon: Icons.calendar_today,
                            ),
                          ),
                          Expanded(
                            child: _InfoItem(
                              label: 'LIEU',
                              value: widget.birthData['placeOfBirth'] ?? 'Non spécifié',
                              icon: Icons.location_on,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Parents
                      Row(
                        children: [
                          Expanded(
                            child: _InfoItem(
                              label: 'PÈRE',
                              value: widget.birthData['fatherFullName'] ?? 'Non renseigné',
                              icon: Icons.person_outline,
                            ),
                          ),
                          Expanded(
                            child: _InfoItem(
                              label: 'MÈRE',
                              value: widget.birthData['motherFullName'] ?? 'Non renseignée',
                              icon: Icons.person_outline,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Hash Blockchain
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.link,
                                color: Color(0xFF059669),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'HASH LEDGER',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatHash(widget.birthData['blockchainHash']),
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF059669),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(begin: 0.2, end: 0),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Bouton Télécharger
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton(
                  onPressed: (_isDownloading || widget.birthData['blockchainHash'] == null) ? null : _downloadCertificate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isDownloading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.file_download_outlined, size: 22),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'TÉLÉCHARGER L\'EXTRAIT',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    '(PDF)',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            
            // Warning infalsifiable
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.verified_user,
                          color: Color(0xFF059669),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DOCUMENT INFALSIABLE',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF059669),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Cet acte est ancré de manière permanente dans la blockchain nationale. Toute modification ultérieure invalidera la signature numérique du QR Code.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                label: 'ACCUEIL',
                isActive: false,
                onTap: () => Navigator.pop(context),
              ),
              _NavItem(
                icon: Icons.description,
                label: 'MES ACTES',
                isActive: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.add_circle_outline,
                label: 'DEMANDE',
                isActive: false,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.person_outline,
                label: 'PROFIL',
                isActive: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return 'Non spécifiée';
    try {
      // Nettoyer la date si c'est une chaîne ISO complète
      final DateTime dt = DateTime.parse(date).toLocal();
      return DateFormat('dd MMM yyyy', 'fr_FR').format(dt);
    } catch (e) {
      return date;
    }
  }

  String _formatHash(String? hash) {
    if (hash == null || hash.isEmpty) return '0x7f8e...a2b1';
    if (hash.length <= 12) return hash;
    return '${hash.substring(0, 6)}...${hash.substring(hash.length - 4)}';
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF94A3B8)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFF059669) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
