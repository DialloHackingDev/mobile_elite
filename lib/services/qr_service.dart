import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRService {
  static String generateBlockchainId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return 'BC-${timestamp.toString()}-$random';
  }

  static String generateBirthCertificateData({
    required String babyName,
    required String birthDate,
    required String birthPlace,
    required String fatherName,
    required String motherName,
    required String blockchainId,
  }) {
    return '''
{
  "blockchainId": "$blockchainId",
  "babyName": "$babyName",
  "birthDate": "$birthDate",
  "birthPlace": "$birthPlace",
  "fatherName": "$fatherName",
  "motherName": "$motherName",
  "timestamp": "${DateTime.now().toIso8601String()}",
  "verified": true,
  "documentType": "BIRTH_CERTIFICATE"
}''';
  }

  static Widget generateQRCode(String data, {double size = 200.0}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  static Map<String, dynamic> parseBirthCertificateData(String qrData) {
    try {
      // For a real app, you'd use dart:convert's jsonDecode
      // This is a simplified version for demonstration
      return {
        'success': true,
        'blockchainId': 'BC-1234567890-123456',
        'babyName': 'Sample Name',
        'birthDate': '2026-04-12',
        'birthPlace': 'Conakry',
        'documentType': 'BIRTH_CERTIFICATE'
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Invalid QR code data'
      };
    }
  }
}
