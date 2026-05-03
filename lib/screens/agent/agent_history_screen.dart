import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../services/offline_service.dart';
import 'agent_sync_screen.dart';

class AgentHistoryScreen extends StatefulWidget {
  const AgentHistoryScreen({super.key});

  @override
  State<AgentHistoryScreen> createState() => _AgentHistoryScreenState();
}

class _AgentHistoryScreenState extends State<AgentHistoryScreen> {
  List<Map<String, dynamic>> _online  = [];
  List<Map<String, dynamic>> _offline = [];
  bool   _loading = true;
  String _filter  = 'Tous';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final api     = ApiService();
      final offline = OfflineService();

      final res     = await api.getBirths(limit: 50);
      final offList = await offline.getOfflineBirths();

      if (!mounted) return;
      setState(() {
        final data = res['data'] as Map<String, dynamic>?;
        _online  = List<Map<String, dynamic>>.from(data?['births'] ?? []);
        // Garder seulement les actes offline non encore synchronisés
        _offline = offList
            .where((b) => b['syncStatus'] != 'synced')
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_filter) {
      case 'Synchronisés':
        return _online.where((b) => b['blockchainHash'] != null).toList();
      case 'En attente':
        return _offline;
      default:
        return [..._online, ..._offline];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(slivers: [
            // ── Header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(children: [
                  Text('Historique',
                      style: GoogleFonts.poppins(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A))),
                  const Spacer(),
                  IconButton(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh_rounded)),
                ]),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Text(
                  'Suivi des enregistrements et synchronisation blockchain.',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: const Color(0xFF64748B)),
                ),
              ),
            ),

            // ── Filtres ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(children: [
                  _Chip(label: 'Tous',          active: _filter == 'Tous',          onTap: () => setState(() => _filter = 'Tous')),
                  const SizedBox(width: 8),
                  _Chip(label: 'Synchronisés',  active: _filter == 'Synchronisés',  onTap: () => setState(() => _filter = 'Synchronisés')),
                  const SizedBox(width: 8),
                  _Chip(label: 'En attente',    active: _filter == 'En attente',    onTap: () => setState(() => _filter = 'En attente'),
                      badge: _offline.length),
                ]),
              ),
            ),

            // ── Bannière sync ────────────────────────────────────────────────
            if (_offline.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AgentSyncScreen()))
                        .then((_) => _load()),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('FILE D\'ATTENTE',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF94A3B8),
                                        letterSpacing: 0.5)),
                                const SizedBox(height: 6),
                                Text(
                                  _offline.length.toString().padLeft(2, '0'),
                                  style: GoogleFonts.poppins(
                                      fontSize: 36,
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(children: [
                            const Icon(Icons.sync_rounded,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text('SYNC',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white)),
                          ]),
                        ),
                      ]),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Liste ────────────────────────────────────────────────────────
            if (_loading)
              const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()))
            else if (_filtered.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(60),
                  child: Column(children: [
                    Icon(Icons.inbox_outlined,
                        size: 56, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('Aucun enregistrement',
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: const Color(0xFF64748B))),
                  ]),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                    final b = _filtered[i];
                    // Un acte est offline s'il a un syncStatus (champ SQLite local)
                    final isOffline = b.containsKey('syncStatus');
                    final synced    = !isOffline &&
                        b['blockchainHash'] != null;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 5),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isOffline
                                ? const Color(0xFFFCD34D)
                                : synced
                                    ? const Color(0xFF059669)
                                    : const Color(0xFFE2E8F0),
                            width: isOffline || synced ? 1.5 : 1,
                          ),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isOffline
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              b['childGender'] == 'F'
                                  ? Icons.face_3
                                  : Icons.face,
                              color: isOffline
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF059669),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${b['childLastName'] ?? '—'}, ${b['childFirstName'] ?? ''}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F172A)),
                                  ),
                                  Text(
                                    isOffline
                                        ? 'Stocké localement'
                                        : _fmtDate(b['createdAt']),
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF64748B)),
                                  ),
                                ]),
                          ),
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Icon(
                                  isOffline
                                      ? Icons.wifi_off
                                      : synced
                                          ? Icons.cloud_done
                                          : Icons.access_time,
                                  color: isOffline
                                      ? const Color(0xFFF59E0B)
                                      : synced
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isOffline
                                      ? 'LOCAL'
                                      : synced
                                          ? 'BLOCKCHAIN'
                                          : 'EN ATTENTE',
                                  style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: isOffline
                                        ? const Color(0xFFF59E0B)
                                        : synced
                                            ? const Color(0xFF059669)
                                            : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ]),
                        ]),
                      ),
                    ).animate().fadeIn(delay: (i * 60).ms);
                  },
                  childCount: _filtered.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ]),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AgentSyncScreen()))
            .then((_) => _load()),
        backgroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.sync_rounded),
      ),
    );
  }

  String _fmtDate(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString());
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) {
      return raw.toString();
    }
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badge;
  const _Chip({required this.label, required this.active, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : const Color(0xFF64748B))),
            if (badge > 0) ...[
              const SizedBox(width: 6),
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Color(0xFFF59E0B), shape: BoxShape.circle)),
            ],
          ]),
        ),
      );
}
