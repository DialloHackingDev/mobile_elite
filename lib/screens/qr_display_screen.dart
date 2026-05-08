import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/qr_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'agent/agent_dashboard_screen.dart';
import '../services/api_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QRDisplayScreen extends StatelessWidget {
  final String babyName;
  final String birthDate;
  final String birthPlace;
  final String fatherName;
  final String motherName;
  final String blockchainId;

  const QRDisplayScreen({
    super.key,
    required this.babyName,
    required this.birthDate,
    required this.birthPlace,
    required this.fatherName,
    required this.motherName,
    required this.blockchainId,
  });

  @override
  Widget build(BuildContext context) {
    final qrData = QRService.generateBirthCertificateData(
      babyName: babyName,
      birthDate: birthDate,
      birthPlace: birthPlace,
      fatherName: fatherName,
      motherName: motherName,
      blockchainId: blockchainId,
    );

    const primaryGreen = Color(0xFF059669);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        title: Text("QR Code Généré", 
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _shareQRCode(context, qrData),
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF059669),
                      Color(0xFF047857),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Certificat de Naissance",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Enregistré avec succès sur la blockchain",
                      style: GoogleFonts.poppins(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // QR Code Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryGreen.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Text(
                      "ID Blockchain",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      blockchainId,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      "Scannez ce QR code pour vérifier l'authenticité du certificat",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Baby Information
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: primaryGreen, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Informations de l'acte",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow("Enfant", babyName),
                    _buildInfoRow("Né le", birthDate),
                    _buildInfoRow("Lieu", birthPlace),
                    _buildInfoRow("Père", fatherName),
                    _buildInfoRow("Mère", motherName),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareWithFamily(context),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text("Envoyer ID"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: primaryGreen,
                        side: const BorderSide(color: primaryGreen, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Retourner au dashboard proprement
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AgentDashboardScreen()),
                          (route) => false,
                        );
                      },
                      icon: const Icon(Icons.home_rounded, size: 18),
                      label: const Text("Accueil"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: primaryGreen.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _shareQRCode(context, qrData),
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text("Partager le certificat complet"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              "$label :",
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareQRCode(BuildContext context, String qrData) {
    Share.share(
      '📜 Certificat de Naissance - NaissanceChain\n'
      '----------------------------------\n'
      'Enfant : $babyName\n'
      'Né(e) le : $birthDate\n'
      'Lieu : $birthPlace\n'
      'ID Blockchain : $blockchainId\n\n'
      'Vérifier l\'authenticité sur : https://naissancechain.gov.gn/verify/$blockchainId',
      subject: 'Certificat de Naissance - $babyName',
    );
  }

  void _shareWithFamily(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Partager l\'ID de l\'extrait',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.message, color: Color(0xFF25D366)),
                title: const Text('Via WhatsApp / SMS'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareExternal();
                },
              ),
              ListTile(
                leading: const Icon(Icons.app_shortcut, color: Color(0xFF059669)),
                title: const Text('Dans l\'application NaissanceChain'),
                subtitle: const Text('La famille recevra l\'ID directement'),
                onTap: () {
                  Navigator.pop(ctx);
                  _shareInApp(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareExternal() {
    Share.share(
      'Bonjour, voici l\'ID de l\'extrait de naissance de votre enfant ($babyName) :\n\n'
      '$blockchainId\n\n'
      'Vous pouvez utiliser cet ID dans l\'application NaissanceChain pour télécharger l\'extrait.',
      subject: 'ID Blockchain - $babyName',
    );
  }

  Future<void> _shareInApp(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CitizenPicker(
        onSelected: (citizen) async {
          final api = ApiService();
          final res = await api.sendNotificationToCitizen({
            'citizenId': citizen['id'],
            'title': 'ID Extrait Disponible',
            'content': 'L\'agent a généré l\'extrait pour $babyName. ID: $blockchainId',
            'type': 'BIRTH_ID',
            'relatedId': blockchainId,
          });

          if (context.mounted) {
            Navigator.pop(ctx);
            if (res['success']) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('ID envoyé à ${citizen['fullName']}'),
                  backgroundColor: const Color(0xFF059669),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: ${res['error']}')),
              );
            }
          }
        },
      ),
    );
  }
}

class _CitizenPicker extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelected;
  const _CitizenPicker({required this.onSelected});

  @override
  State<_CitizenPicker> createState() => _CitizenPickerState();
}

class _CitizenPickerState extends State<_CitizenPicker> {
  List<Map<String, dynamic>> _citizens = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiService();
    final res = await api.listCitizens();
    if (mounted) {
      setState(() {
        _citizens = List<Map<String, dynamic>>.from(res['data'] ?? []);
        _filtered = _citizens;
        _loading = false;
      });
    }
  }

  void _filter(String q) {
    setState(() {
      _filtered = _citizens
          .where((c) =>
              c['fullName'].toString().toLowerCase().contains(q.toLowerCase()) ||
              c['phoneNumber'].toString().contains(q))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Sélectionner la famille',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou téléphone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_filtered.isEmpty)
            const Center(child: Text('Aucune famille trouvée'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final c = _filtered[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFDBEAFE),
                      child: Icon(Icons.person, color: Color(0xFF06B6D4)),
                    ),
                    title: Text(c['fullName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(c['phoneNumber']),
                    trailing: const Icon(Icons.send_rounded, color: Color(0xFF059669)),
                    onTap: () => widget.onSelected(c),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
