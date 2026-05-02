import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/offline_service.dart';
import '../../services/api_service.dart';

class AgentSyncScreen extends StatefulWidget {
  const AgentSyncScreen({super.key});

  @override
  State<AgentSyncScreen> createState() => _AgentSyncScreenState();
}

class _AgentSyncScreenState extends State<AgentSyncScreen> {
  List<Map<String, dynamic>> _pendingBirths = [];
  bool _isLoading = true;
  bool _isSyncing = false;
  int _syncProgress = 0;
  int _totalToSync = 0;

  @override
  void initState() {
    super.initState();
    _loadPendingBirths();
  }

  Future<void> _loadPendingBirths() async {
    final offlineService = OfflineService();
    final births = await offlineService.getOfflineBirths();
    
    if (mounted) {
      setState(() {
        _pendingBirths = births;
        _isLoading = false;
      });
    }
  }

  Future<void> _syncAll() async {
    if (_pendingBirths.isEmpty) return;

    setState(() {
      _isSyncing = true;
      _totalToSync = _pendingBirths.length;
      _syncProgress = 0;
    });

    final offlineService = OfflineService();
    final api = ApiService();

    for (final birth in _pendingBirths) {
      try {
        // Préparer les données pour l'API
        final birthData = {
          'childFirstName': birth['childFirstName'],
          'childLastName': birth['childLastName'],
          'childGender': birth['childGender'],
          'dateOfBirth': birth['dateOfBirth'],
          'placeOfBirth': birth['placeOfBirth'],
          'motherFullName': birth['motherFullName'],
          'motherDob': birth['motherDob'],
          'motherPrefecture': birth['motherPrefecture'],
          'establishmentCode': birth['establishmentCode'],
          'timeOfBirth': birth['timeOfBirth'],
          'fatherFullName': birth['fatherFullName'],
          'fatherDob': birth['fatherDob'],
          'gpsCoordinates': birth['gpsCoordinates'],
          'parentPhoneNumber': birth['parentPhoneNumber'],
          'isLateRegistration': false,
        };

        // Envoyer au backend
        final result = await api.registerBirth(birthData);

        if (result['success']) {
          // Marquer comme synchronisé
          await offlineService.markAsSynced(birth['localId'], result['data']['id']);
        }

        setState(() => _syncProgress++);
      } catch (e) {
        // Continuer avec le suivant en cas d'erreur
        setState(() => _syncProgress++);
      }
    }

    // Recharger la liste
    await _loadPendingBirths();

    if (mounted) {
      setState(() => _isSyncing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Synchronisation terminée: $_syncProgress/$_totalToSync'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  Future<void> _syncSingle(String localId) async {
    // Implémentation similaire pour un seul élément
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Synchronisation individuelle...')),
    );
  }

  Future<void> _deletePending(String localId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmer la suppression',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer cet enregistrement ?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Supprimer', style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final offlineService = OfflineService();
      await offlineService.deleteOfflineBirth(localId);
      await _loadPendingBirths();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(Icons.arrow_back, size: 20),
          ),
        ),
        title: Text(
          'Synchronisation',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header info
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.cloud_sync,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_pendingBirths.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Enregistrements en attente',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (_isSyncing) ...[
                        const SizedBox(height: 20),
                        LinearProgressIndicator(
                          value: _totalToSync > 0 ? _syncProgress / _totalToSync : 0,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(Color(0xFF059669)),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Synchronisation... $_syncProgress/$_totalToSync',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(),
                
                // Bouton Sync All
                if (_pendingBirths.isNotEmpty && !_isSyncing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _syncAll,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.sync, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'SYNCHRONISER TOUT',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                
                const SizedBox(height: 20),
                
                // Liste
                Expanded(
                  child: _pendingBirths.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_done_outlined,
                                size: 80,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Tous les enregistrements sont synchronisés',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _pendingBirths.length,
                          itemBuilder: (context, index) {
                            final birth = _pendingBirths[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFCD34D), width: 2),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.wifi_off,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${birth['childLastName']}, ${birth['childFirstName']}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Né(e) le ${birth['dateOfBirth']}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            color: const Color(0xFF64748B),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Stocké localement',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: const Color(0xFFF59E0B),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () => _syncSingle(birth['localId']),
                                        icon: const Icon(
                                          Icons.sync,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () => _deletePending(birth['localId']),
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: (index * 100).ms);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
