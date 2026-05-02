import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

/// Écran de vérification d'acte avec scanner QR et saisie manuelle
class VerifyScreen extends StatefulWidget {
  const VerifyScreen({super.key});

  @override
  State<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _nationalIdController = TextEditingController();

  bool _isScanning = false;
  bool _isVerifying = false;
  bool _showResult = false;
  Map<String, dynamic>? _verificationResult;
  String? _errorMessage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  Future<void> _verifyByQR(String qrData) async {
    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _showResult = false;
    });

    final result = await _apiService.verifyByQR(qrData, verifierType: 'AGENT');

    setState(() {
      _isVerifying = false;
      if (result['success']) {
        _verificationResult = result['data'];
        _showResult = true;
      } else {
        _errorMessage = result['error'] ?? 'Vérification échouée';
      }
    });
  }

  Future<void> _verifyById() async {
    final nationalId = _nationalIdController.text.trim();
    if (nationalId.isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un ID national';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _showResult = false;
    });

    final result = await _apiService.verifyById(nationalId, verifierType: 'AGENT');

    setState(() {
      _isVerifying = false;
      if (result['success']) {
        _verificationResult = result['data'];
        _showResult = true;
      } else {
        _errorMessage = result['error'] ?? 'Acte non trouvé';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text(
          'Vérification d\'acte',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scanner QR'),
            Tab(icon: Icon(Icons.keyboard), text: 'Saisie manuelle'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQRScannerTab(primaryColor),
          _buildManualEntryTab(primaryColor),
        ],
      ),
    );
  }

  Widget _buildQRScannerTab(Color primaryColor) {
    return Column(
      children: [
        if (_isScanning)
          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: (capture) {
                    final List<Barcode> barcodes = capture.barcodes;
                    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                      final String code = barcodes.first.rawValue!;
                      setState(() {
                        _isScanning = false;
                      });
                      _verifyByQR(code);
                    }
                  },
                ),
                // Overlay de scan
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                // Bouton fermer
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        _isScanning = false;
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_showResult && _verificationResult != null)
                    _buildResultCard(_verificationResult!, primaryColor)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.2, end: 0)
                  else if (_errorMessage != null)
                    _buildErrorCard(_errorMessage!, primaryColor)
                        .animate()
                        .shake(duration: 400.ms)
                  else
                    _buildScannerIntro(primaryColor),
                ],
              ),
            ),
          ),

        if (!_isScanning && !_showResult)
          Container(
            padding: const EdgeInsets.all(24),
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
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isScanning = true;
                    _errorMessage = null;
                    _showResult = false;
                  });
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: Text(
                  'Scanner un QR Code',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

        if (_isVerifying)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Vérification en cours...',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildManualEntryTab(Color primaryColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_showResult && _verificationResult != null)
            _buildResultCard(_verificationResult!, primaryColor)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.2, end: 0)
          else if (_errorMessage != null)
            _buildErrorCard(_errorMessage!, primaryColor)
                .animate()
                .shake(duration: 400.ms)
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Entrez l\'ID national de l\'acte à vérifier (format: GN-2026-XXX-XXXXXXX)',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms),

          const SizedBox(height: 24),

          TextField(
            controller: _nationalIdController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: 'ID National',
              hintText: 'GN-2026-CONA-0000001',
              prefixIcon: const Icon(Icons.badge),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 24),

          if (_isVerifying)
            Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Vérification en cours...',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _verifyById,
              icon: const Icon(Icons.search),
              label: Text(
                'Vérifier',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }

  Widget _buildScannerIntro(Color primaryColor) {
    return Column(
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.qr_code_scanner,
            size: 80,
            color: primaryColor,
          ),
        )
            .animate()
            .scale(duration: 600.ms, curve: Curves.elasticOut),

        const SizedBox(height: 24),

        Text(
          'Scanner un QR Code',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 200.ms),

        const SizedBox(height: 12),

        Text(
          'Scannez le QR code d\'un acte de naissance pour vérifier son authenticité sur la blockchain',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 300.ms),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data, Color primaryColor) {
    final isValid = data['isValid'] ?? true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isValid ? Colors.green : Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isValid ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isValid ? Icons.verified : Icons.error,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isValid ? 'Acte Authentique' : 'Vérification Échouée',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isValid ? Colors.green[700] : Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          if (data['childFirstName'] != null)
            Text(
              '${data['childFirstName']} ${data['childLastName'] ?? ''}',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          _buildResultRow('ID National', data['nationalId'] ?? 'N/A'),
          _buildResultRow('Date de naissance', data['dateOfBirth'] ?? 'N/A'),
          _buildResultRow('Lieu', data['placeOfBirth'] ?? 'N/A'),
          if (data['blockchainHash'] != null)
            _buildResultRow('Hash Blockchain', '${data['blockchainHash'].toString().substring(0, 20)}...'),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error, Color primaryColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Erreur',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.red[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
