import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

/// Écran de gestion des agents avec vraies données
class AdminAgentsScreen extends StatefulWidget {
  final Map<String, dynamic>? agentsData;

  const AdminAgentsScreen({super.key, this.agentsData});

  @override
  State<AdminAgentsScreen> createState() => _AdminAgentsScreenState();
}

class _AdminAgentsScreenState extends State<AdminAgentsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allAgents = [];
  List<Map<String, dynamic>> _filteredAgents = [];
  int _totalAgents = 0;
  int _onlineAgents = 0;
  
  String _selectedRegion = 'Toutes les régions';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAgentsFromAPI();
    _searchController.addListener(_runFilter);
  }

  Future<void> _loadAgentsFromAPI() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final response = await api.getFast('/dashboard/agents');
      if (mounted) {
        setState(() {
          final data = response?['data'] as Map<String, dynamic>?;
          _allAgents = (data?['agents'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _filteredAgents = List.from(_allAgents);
          
          _totalAgents = _allAgents.length;
          _onlineAgents = _allAgents.where((a) => a['status'] == 'ACTIVE').length;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur chargement agents: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _runFilter() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAgents = _allAgents.where((agent) {
        final nameMatches = (agent['fullName'] ?? '').toString().toLowerCase().contains(query);
        final idMatches = (agent['agentId'] ?? '').toString().toLowerCase().contains(query);
        final regionMatches = _selectedRegion == 'Toutes les régions' || agent['region'] == _selectedRegion;
        return (nameMatches || idMatches) && regionMatches;
      }).toList();
    });
  }

  void _showAddAgentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AgentFormDialog(
        onSave: (data) async {
          final api = ApiService();
          final res = await api.post('/agents', data);
          if (res['success'] == true && mounted) {
            setState(() {}); // Refresh list
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Agent créé avec succès'), backgroundColor: Colors.green),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Erreur lors de la création'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  void _showEditAgentDialog(BuildContext context, Map<String, dynamic> agent) {
    showDialog(
      context: context,
      builder: (context) => _AgentFormDialog(
        agent: agent,
        onSave: (data) async {
          final api = ApiService();
          final res = await api.patch('/agents/${agent['id']}', data); // Use patch or put
          if (res['success'] == true && mounted) {
            setState(() {}); // Refresh list
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Agent mis à jour'), backgroundColor: Colors.blue),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(res['error'] ?? 'Erreur lors de la modification'), backgroundColor: Colors.red),
            );
          }
        },
      ),
    );
  }

  Future<void> _deleteAgent(BuildContext context, String id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'agent'),
        content: Text('Voulez-vous vraiment supprimer $name ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final api = ApiService();
      final res = await api.delete('/agents/$id');
      if (res['success'] == true && mounted) {
        setState(() {}); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agent supprimé'), backgroundColor: Colors.orange),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['error'] ?? 'Erreur lors de la suppression'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des Agents',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Administration des registres d\'état civil sur la blockchain',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bouton Ajouter
                  ElevatedButton.icon(
                    onPressed: () => _showAddAgentDialog(context),
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: Text(
                      'Ajouter un Agent',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Barre de recherche et filtres
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher par nom ou ID...',
                      hintStyle: GoogleFonts.poppins(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF94A3B8),
                        size: 18,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filtre région
                  Row(
                    children: [
                      const Icon(
                        Icons.filter_list,
                        color: Color(0xFF64748B),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'RÉGION',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedRegion,
                                  isDense: true,
                                  icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B), size: 18),
                                  style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF475569)),
                                  items: ['Toutes les régions', 'Conakry', 'Kindia', 'Boké', 'Labé', 'Kankan', 'Mamou', 'Faranah', 'Nzérékoré']
                                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                                      .toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedRegion = val);
                                      _runFilter();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Liste des agents
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                      ),
                    )
                  : _filteredAgents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 48,
                                color: Colors.grey.withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Aucun agent trouvé',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredAgents.length,
                          itemBuilder: (context, index) {
                            return _AgentCard(
                              agent: _filteredAgents[index],
                              onEdit: (a) => _showEditAgentDialog(context, a),
                              onDelete: (id, name) => _deleteAgent(context, id, name),
                            ).animate().fadeIn(
                                  delay: (index * 50).ms,
                                );
                          },
                        ),
            ),

            // Stats footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'TOTAL',
                      value: '$_totalAgents',
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white24,
                  ),
                  Expanded(
                    child: _StatBox(
                      label: 'EN LIGNE',
                      value: '$_onlineAgents',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
  }
}

class _AgentCard extends StatelessWidget {
  final Map<String, dynamic> agent;
  final Function(Map<String, dynamic>) onEdit;
  final Function(String, String) onDelete;

  const _AgentCard({
    required this.agent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = agent['status'] ?? 'OFFLINE';
    final isActive = status == 'ACTIVE';
    final statusColor = isActive ? const Color(0xFF10B981) : const Color(0xFF94A3B8);
    final statusLabel = isActive ? 'ACTIF' : (status == 'OFFLINE' ? 'HORS LIGNE' : status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: statusColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent['fullName'] ?? 'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      agent['agentId'] ?? 'ID-000',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined,
                  size: 14, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${agent['region'] ?? 'N/A'} • ${agent['establishment'] ?? 'N/A'}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Actes: ${agent['birthsCount'] ?? 0}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_outlined, size: 18),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit(agent);
                    } else if (value == 'delete') {
                      onDelete(agent['id'], agent['fullName']);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Modifier'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Supprimer'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }
}

class _AgentFormDialog extends StatefulWidget {
  final Map<String, dynamic>? agent;
  final Function(Map<String, dynamic>) onSave;

  const _AgentFormDialog({this.agent, required this.onSave});

  @override
  State<_AgentFormDialog> createState() => _AgentFormDialogState();
}

class _AgentFormDialogState extends State<_AgentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _idController;
  late TextEditingController _passController;
  String _selectedPrefecture = 'Conakry';

  @override
  void initState() {
    super.initState();
    final names = (widget.agent?['fullName'] as String?)?.split(' ') ?? ['', ''];
    _firstNameController = TextEditingController(text: widget.agent != null ? names[0] : '');
    _lastNameController = TextEditingController(text: widget.agent != null ? (names.length > 1 ? names.sublist(1).join(' ') : '') : '');
    _idController = TextEditingController(text: widget.agent?['agentId'] ?? '');
    _passController = TextEditingController();
    _selectedPrefecture = widget.agent?['region'] ?? 'Conakry';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.agent != null;

    return AlertDialog(
      title: Text(isEdit ? 'Modifier l\'agent' : 'Ajouter un Agent', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'Prénom'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
              ),
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'ID National (ex: AGENT-XXXX)'),
                validator: (v) => v!.isEmpty ? 'Requis' : null,
                enabled: !isEdit,
              ),
              TextFormField(
                controller: _passController,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Nouveau mot de passe (optionnel)' : 'Mot de passe',
                ),
                obscureText: true,
                validator: (v) => !isEdit && v!.isEmpty ? 'Requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPrefecture,
                decoration: const InputDecoration(labelText: 'Préfecture d\'affectation'),
                items: ['Conakry', 'Kindia', 'Boké', 'Labé', 'Kankan', 'Mamou', 'Faranah', 'Nzérékoré']
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedPrefecture = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave({
                'firstName': _firstNameController.text.trim(),
                'lastName': _lastNameController.text.trim(),
                'nationalAgentId': _idController.text.trim(),
                'password': _passController.text.trim(),
                'prefectureAssignment': _selectedPrefecture,
                'role': 'AGENT',
              });
              Navigator.pop(context);
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
