import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/qr_service.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text("QR Code Généré"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _shareQRCode(context, qrData),
            icon: const Icon(Icons.share),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Certificat de Naissance",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Enregistré sur la blockchain",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // QR Code Card
              Card(
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: QRService.generateQRCode(qrData, size: 250),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Text(
                        "ID Blockchain: $blockchainId",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        "Scannez ce QR code pour vérifier l'authenticité du certificat",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Baby Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Informations du Bébé",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow("Nom", babyName),
                      _buildInfoRow("Date de naissance", birthDate),
                      _buildInfoRow("Lieu de naissance", birthPlace),
                      _buildInfoRow("Nom du père", fatherName),
                      _buildInfoRow("Nom de la mère", motherName),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _shareQRCode(context, qrData),
                      icon: const Icon(Icons.share),
                      label: const Text("Partager"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text("Accueil"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareQRCode(BuildContext context, String qrData) {
    Share.share(
      'Certificat de naissance enregistré sur la blockchain\nID: $blockchainId\n\nScannez le QR code pour vérifier l\'authenticité.',
      subject: 'Certificat de Naissance - $babyName',
    );
  }
}
