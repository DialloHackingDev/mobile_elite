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
  List<Map<String, dynamic>> _births = [];
  List<Map<String, dynamic>> _offlineBirths = [];
  bool _isLoading = true;
  String _filter = 'Tous';
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final api = ApiService();
      final offlineService = OfflineService();
      
      final result = await api.get('/births?limit=50');
      final offline = await offlineService.getOfflineBirths();
      final pending = await offlineService.getPendingSyncCount();
      
      if (mounted) {
        setState(() {
          _births = List<Map<String, dynamic>>.from(result['data']?['births'] ?? []);
          _offlineBirths = offline;
          _pendingCount = pending;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Map<String, dynamic>> get _filteredBirths {
    if (_filter == 'Tous') return [..._births, ..._offlineBirths];
    if (_filter == 'Synchronisés') return _births.where((b) => b['blockchainHash'] != null).toList();
    if (_filter == 'En attente') return _offlineBirths;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Text(
                        'Historique',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => _loadData(),
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Description
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Suivez l\'état de synchronisation des enregistrements sur la blockchain.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              
              // Filtres
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'Tous',
                        isActive: _filter == 'Tous',
                        onTap: () => setState(() => _filter = 'Tous'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Synchronisés',
                        isActive: _filter == 'Synchronisés',
                        onTap: () => setState(() => _filter = 'Synchronisés'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'En attente',
                        isActive: _filter == 'En attente',
                        count: _pendingCount > 0 ? _pendingCount : null,
                        onTap: () => setState(() => _filter = 'En attente'),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              
              // File d'attente Card
              if (_pendingCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AgentSyncScreen()),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FILE D\'ATTENTE',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF94A3B8),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _pendingCount.toString().padLeft(2, '0'),
                                    style: GoogleFonts.poppins(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'Enregistrements en\nattente',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF059669),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.sync, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'SYNCHRONISER\nTOUT',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
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
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              
              // Liste
              _isLoading
                  ? const SliverToBoxAdapter(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : _filteredBirths.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(60),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucun enregistrement',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final birth = _filteredBirths[index];
                              final isOffline = birth['syncStatus'] == 'PENDING' || birth['id'] == null;
                              
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isOffline 
                                          ? const Color(0xFFFCD34D) 
                                          : const Color(0xFF059669),
                                      width: isOffline ? 2 : 2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: isOffline 
                                              ? const Color(0xFFFEF3C7) 
                                              : const Color(0xFFD1FAE5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          birth['childGender'] == 'F' 
                                              ? Icons.face_3 
                                              : Icons.face,
                                          color: isOffline 
                                              ? const Color(0xFFF59E0B) 
                                              : const Color(0xFF059669),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${birth['childLastName'] ?? 'Inconnu'}, ${birth['childFirstName'] ?? ''}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              isOffline 
                                                  ? 'Stocké localement' 
                                                  : 'Hier, ${_formatTime(birth['createdAt'])}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Icon(
                                            isOffline ? Icons.wifi_off : Icons.cloud_done,
                                            color: isOffline 
                                                ? const Color(0xFFF59E0B) 
                                                : const Color(0xFF059669),
                                            size: 20,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            isOffline ? 'HORS LIGNE' : 'SÉCURISÉ',
                                            style: GoogleFonts.poppins(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: isOffline 
                                                  ? const Color(0xFFF59E0B) 
                                                  : const Color(0xFF059669),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: (index * 80).ms);
                            },
                            childCount: _filteredBirths.length,
                          ),
                        ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AgentSyncScreen()),
        ),
        backgroundColor: const Color(0xFF0F172A),
        child: const Icon(Icons.sync),
      ),
    );
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return '--:--';
    try {
      final dt = DateTime.parse(dateTime);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '--:--';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final int? count;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
