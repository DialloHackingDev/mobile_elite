import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/offline_service.dart';

class AgentSyncScreen extends StatefulWidget {
  const AgentSyncScreen({super.key});

  @override
  State<AgentSyncScreen> createState() => _AgentSyncScreenState();
}

class _AgentSyncScreenState extends State<AgentSyncScreen> {
  List<Map<String, dynamic>> _pending = [];
  bool _loading  = true;
  bool _syncing  = false;
  int  _progress = 0;
  int  _total    = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await OfflineService().getOfflineBirths();
    if (!mounted) return;
    setState(() {
      _pending = list.where((b) => b['syncStatus'] != 'synced').toList();
      _loading = false;
    });
  }

  // ── Sync tout ──────────────────────────────────────────────────────────────
  Future<void> _syncAll() async {
    if (_pending.isEmpty) return;
    setState(() { _syncing = true; _total = _pending.length; _progress = 0; });

    for (final birth in _pending) {
      await _syncOne(birth);
      if (mounted) setState(() => _progress++);
    }

    await _load();
    if (!mounted) return;
    setState(() => _syncing = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Synchronisation terminée : $_progress/$_total'),
      backgroundColor: const Color(0xFF059669),
    ));
  }

  // ── Sync individuel ────────────────────────────────────────────────────────
  Future<void> _syncSingle(Map<String, dynamic> birth) async {
    final localId = birth['localId'] as String;
    try {
      final result = await _syncOne(birth);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result
            ? 'Acte synchronisé avec succès'
            : 'Échec de la synchronisation'),
        backgroundColor:
            result ? const Color(0xFF059669) : Colors.red,
      ));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  /// Retourne true si succès
  Future<bool> _syncOne(Map<String, dynamic> birth) async {
    final api     = ApiService();
    final offline = OfflineService();
    final localId = birth['localId'] as String;

    final payload = {
      'childFirstName':    birth['childFirstName'],
      'childLastName':     birth['childLastName'],
      'childGender':       birth['childGender'],
      'dateOfBirth':       birth['dateOfBirth'],
      'timeOfBirth':       birth['timeOfBirth'],
      'placeOfBirth':      birth['placeOfBirth'],
      'motherFullName':    birth['motherFullName'],
      'motherDob':         birth['motherDob'],
      'motherPrefecture':  birth['motherPrefecture'],
      'motherCni':         birth['motherCni'],
      'fatherFullName':    birth['fatherFullName'],
      'fatherDob':         birth['fatherDob'],
      'fatherCni':         birth['fatherCni'],
      'establishmentCode': birth['establishmentCode'],
      'gpsCoordinates':    birth['gpsCoordinates'],
      'parentPhoneNumber': birth['parentPhoneNumber'],
      'isLateRegistration': birth['isLateRegistration'] ?? false,
      'witness1FullName':   birth['witness1FullName'],
      'witness1Cni':        birth['witness1Cni'],
      'witness2FullName':   birth['witness2FullName'],
      'witness2Cni':        birth['witness2Cni'],
      'localId':            birth['localId'],
    };

    final res = await api.registerBirth(payload);
    if (res['success'] == true) {
      final serverId = (res['data'] as Map<String, dynamic>?)?['id'] ?? '';
      await offline.markAsSynced(localId, serverId);
      return true;
    }
    // Incrémenter le compteur d'erreurs
    final retries = (birth['retryCount'] as int? ?? 0) + 1;
    await offline.updateOfflineBirth(localId, {
      'sync_status': retries >= 3 ? 'failed' : 'pending',
      'sync_error':  res['error'],
      'retry_count': retries,
    });
    return false;
  }

  Future<void> _delete(String localId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer ?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Cet enregistrement local sera définitivement supprimé.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      await OfflineService().deleteOfflineBirth(localId);
      await _load();
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
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: const Icon(Icons.arrow_back_ios_new, size: 18),
          ),
        ),
        title: Text('Synchronisation',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // ── Header card ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF047857)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.cloud_sync_rounded,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_pending.length}',
                                style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text('acte(s) en attente',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color:
                                          Colors.white.withOpacity(0.7))),
                            ]),
                      ),
                    ]),
                    if (_syncing) ...[
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _total > 0 ? _progress / _total : 0,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation(
                              Color(0xFF059669)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('$_progress / $_total synchronisés...',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.7))),
                    ],
                  ]),
                ).animate().fadeIn(),
              ),

              // ── Bouton sync all ────────────────────────────────────────────
              if (_pending.isNotEmpty && !_syncing)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _syncAll,
                      icon: const Icon(Icons.sync_rounded, size: 20),
                      label: Text('SYNCHRONISER TOUT',
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: const Color(0xFF059669).withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ),

              const SizedBox(height: 16),

              // ── Liste ──────────────────────────────────────────────────────
              Expanded(
                child: _pending.isEmpty
                    ? Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_done_outlined,
                                  size: 72, color: Colors.grey[300]),
                              const SizedBox(height: 14),
                              Text(
                                'Tout est synchronisé !',
                                style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color(0xFF64748B)),
                              ),
                            ]),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _pending.length,
                        itemBuilder: (ctx, i) {
                          final b = _pending[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFFCD34D),
                                  width: 1.5),
                            ),
                            child: Row(children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius:
                                        BorderRadius.circular(10)),
                                child: const Icon(Icons.wifi_off,
                                    color: Color(0xFFF59E0B)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${b['childLastName']}, ${b['childFirstName']}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                const Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        'Né(e) le ${b['dateOfBirth']}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color:
                                                const Color(0xFF64748B)),
                                      ),
                                      Text('Stocké localement',
                                          style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(
                                                  0xFFF59E0B))),
                                    ]),
                              ),
                              Row(children: [
                                IconButton(
                                  onPressed: _syncing
                                      ? null
                                      : () => _syncSingle(b),
                                  icon: const Icon(Icons.sync_rounded,
                                      color: Color(0xFF059669)),
                                  tooltip: 'Synchroniser',
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _delete(b['localId'] as String),
                                  icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Color(0xFFDC2626)),
                                  tooltip: 'Supprimer',
                                ),
                              ]),
                            ]),
                          ).animate().fadeIn(delay: (i * 80).ms);
                        },
                      ),
              ),
            ]),
    );
  }
}
