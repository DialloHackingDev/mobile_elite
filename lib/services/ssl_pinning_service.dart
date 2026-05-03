import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

class SslPinningService {
  static const _pinnedCertificates = <String>[
    'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];

  static Future<void> verifyCertificate(String url) async {
    final uri = Uri.parse(url);
    final host = uri.host;
    final port = uri.port == 0 ? 443 : uri.port;

    final socket = await SecureSocket.connect(
      host,
      port,
      onBadCertificate: (_) => true,
      timeout: const Duration(seconds: 10),
    );

    try {
      final certificate = socket.peerCertificate;
      if (certificate == null) {
        throw Exception('Le certificat serveur est introuvable.');
      }

      final fingerprint = sha256.convert(certificate.der).bytes;
      final fingerprintBase64 = base64Encode(fingerprint);
      final expected = 'sha256/$fingerprintBase64';

      if (!_pinnedCertificates.contains(expected)) {
        throw Exception('Échec du SSL pinning. Certificat non reconnu.');
      }
    } finally {
      socket.destroy();
    }
  }
}
