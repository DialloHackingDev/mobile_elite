import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';

class CitizenNewRequestScreen extends StatefulWidget {
  const CitizenNewRequestScreen({super.key});

  @override
  State<CitizenNewRequestScreen> createState() => _CitizenNewRequestScreenState();
}

class _CitizenNewRequestScreenState extends State<CitizenNewRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  String _requestType = 'BIRTH_CERTIFICATE';
  String _deliveryMethod = 'DIGITAL';
  final _childFirstNameController = TextEditingController();
  final _childLastNameController = TextEditingController();
  final _timeOfBirthController = TextEditingController();
  final _placeOfBirthController = TextEditingController();
  
  final _fatherNameController = TextEditingController();
  final _fatherCniController = TextEditingController();
  
  final _motherNameController = TextEditingController();
  final _motherCniController = TextEditingController();
  final _motherPrefectureController = TextEditingController();
  
  final _witness1NameController = TextEditingController();
  final _witness1CniController = TextEditingController();
  final _witness2NameController = TextEditingController();
  final _witness2CniController = TextEditingController();

  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime? _selectedBirthDate;
  DateTime? _selectedMotherDob;
  DateTime? _selectedFatherDob;
  String _selectedGender = 'M';
  
  bool _isLoading = false;
  String? _selectedAgentId;
  String? _selectedAgentName;

  void _showAgentPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AgentPicker(
        onSelected: (agent) {
          setState(() {
            _selectedAgentId = agent['id'];
            _selectedAgentName = '${agent['firstName']} ${agent['lastName']}';
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  final List<Map<String, dynamic>> _requestTypes = [
    {'value': 'BIRTH_CERTIFICATE', 'label': 'Acte de naissance', 'icon': Icons.description},
    {'value': 'COPY_CERTIFICATE', 'label': 'Copie certifiée', 'icon': Icons.copy},
    {'value': 'CORRECTION', 'label': 'Correction d\'acte', 'icon': Icons.edit},
  ];

  final List<Map<String, dynamic>> _deliveryMethods = [
    {'value': 'DIGITAL', 'label': 'Email (Gratuit)', 'icon': Icons.email},
    {'value': 'PICKUP', 'label': 'Retrait en mairie', 'icon': Icons.store},
    {'value': 'MAIL', 'label': 'Courrier postal', 'icon': Icons.local_shipping},
  ];

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      await api.createRequest({
        'type': _requestType,
        'deliveryMethod': _deliveryMethod,
        'childFirstName': _childFirstNameController.text.trim(),
        'childLastName': _childLastNameController.text.trim(),
        'birthDate': _selectedBirthDate?.toIso8601String(),
        'timeOfBirth': _timeOfBirthController.text.trim(),
        'placeOfBirth': _placeOfBirthController.text.trim(),
        'childGender': _selectedGender,
        
        'fatherFullName': _fatherNameController.text.trim(),
        'fatherDob': _selectedFatherDob?.toIso8601String(),
        'fatherCni': _fatherCniController.text.trim(),
        
        'motherFullName': _motherNameController.text.trim(),
        'motherDob': _selectedMotherDob?.toIso8601String(),
        'motherCni': _motherCniController.text.trim(),
        'motherPrefecture': _motherPrefectureController.text.trim(),
        
        'witness1FullName': _witness1NameController.text.trim(),
        'witness1Cni': _witness1CniController.text.trim(),
        'witness2FullName': _witness2NameController.text.trim(),
        'witness2Cni': _witness2CniController.text.trim(),

        'phoneNumber': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'email': _emailController.text.isNotEmpty ? _emailController.text : null,
        'address': _addressController.text.isNotEmpty ? _addressController.text : null,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
        'assignedAgentId': _selectedAgentId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demande créée avec succès !'),
            backgroundColor: Color(0xFF059669),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nouvelle Demande',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Type de demande
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Type de demande',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _requestTypes.map((type) {
                      final isSelected = _requestType == type['value'];
                      return ChoiceChip(
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _requestType = type['value']);
                        },
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(type['icon'], size: 18),
                            const SizedBox(width: 8),
                            Text(type['label']),
                          ],
                        ),
                        selectedColor: const Color(0xFF059669).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF059669),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Sélection de l'Agent (MIS EN AVANT)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Agent à solliciter',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _showAgentPicker,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _selectedAgentId != null ? const Color(0xFF059669) : const Color(0xFFE2E8F0)),
                            boxShadow: [
                              if (_selectedAgentId != null)
                                BoxShadow(color: const Color(0xFF059669).withOpacity(0.1), blurRadius: 10)
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.person_search_rounded, color: _selectedAgentId != null ? const Color(0xFF059669) : Colors.grey),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedAgentName ?? 'Rechercher un agent municipal...',
                                  style: GoogleFonts.poppins(
                                    color: _selectedAgentId != null ? const Color(0xFF0F172A) : Colors.grey,
                                    fontWeight: _selectedAgentId != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (_selectedAgentId != null)
                                IconButton(
                                  onPressed: () => setState(() { _selectedAgentId = null; _selectedAgentName = null; }),
                                  icon: const Icon(Icons.close, size: 18),
                                )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Informations sur l'enfant
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    'Informations sur l\'enfant',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _childFirstNameController,
                              decoration: InputDecoration(
                                labelText: 'Prénom',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v!.isEmpty ? 'Requis' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _childLastNameController,
                              decoration: InputDecoration(
                                labelText: 'Nom',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              validator: (v) => v!.isEmpty ? 'Requis' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) setState(() => _selectedBirthDate = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 10),
                                    Text(_selectedBirthDate == null 
                                      ? 'Date de naissance' 
                                      : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedGender,
                              underline: const SizedBox(),
                              items: const [
                                DropdownMenuItem(value: 'M', child: Text('Masculin')),
                                DropdownMenuItem(value: 'F', child: Text('Féminin')),
                              ],
                              onChanged: (v) => setState(() => _selectedGender = v!),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _timeOfBirthController,
                              decoration: InputDecoration(
                                labelText: 'Heure de naissance (ex: 14:30)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _placeOfBirthController,
                              decoration: InputDecoration(
                                labelText: 'Lieu de naissance',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Parents
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Informations de la Mère',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _motherNameController,
                        decoration: InputDecoration(
                          labelText: 'Nom complet de la mère',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v!.isEmpty ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(1990),
                                  firstDate: DateTime(1930),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) setState(() => _selectedMotherDob = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 10),
                                    Text(_selectedMotherDob == null 
                                      ? 'Date de naissance' 
                                      : '${_selectedMotherDob!.day}/${_selectedMotherDob!.month}/${_selectedMotherDob!.year}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _motherCniController,
                        decoration: InputDecoration(
                          labelText: 'Numéro CNI Mère',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _motherPrefectureController,
                        decoration: InputDecoration(
                          labelText: 'Préfecture de résidence',
                          prefixIcon: const Icon(Icons.location_city),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Informations du Père (Optionnel)',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _fatherNameController,
                        decoration: InputDecoration(
                          labelText: 'Nom complet du père',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(1985),
                                  firstDate: DateTime(1930),
                                  lastDate: DateTime.now(),
                                );
                                if (date != null) setState(() => _selectedFatherDob = date);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 18),
                                    const SizedBox(width: 10),
                                    Text(_selectedFatherDob == null 
                                      ? 'Date de naissance' 
                                      : '${_selectedFatherDob!.day}/${_selectedFatherDob!.month}/${_selectedFatherDob!.year}'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _fatherCniController,
                        decoration: InputDecoration(
                          labelText: 'Numéro CNI Père',
                          prefixIcon: const Icon(Icons.badge),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Témoins',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _witness1NameController,
                        decoration: InputDecoration(
                          labelText: 'Nom du Témoin 1',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _witness1CniController,
                        decoration: InputDecoration(
                          labelText: 'CNI du Témoin 1',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _witness2NameController,
                        decoration: InputDecoration(
                          labelText: 'Nom du Témoin 2',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _witness2CniController,
                        decoration: InputDecoration(
                          labelText: 'CNI du Témoin 2',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Méthode de livraison
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Méthode de livraison',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: _deliveryMethods.map((method) {
                      final isSelected = _deliveryMethod == method['value'];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFF059669) : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => _deliveryMethod = method['value']),
                          leading: Icon(method['icon']),
                          title: Text(method['label']),
                          trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Color(0xFF059669))
                            : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Coordonnées
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Coordonnées',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: 'Téléphone',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (_deliveryMethod == 'MAIL') ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(
                            labelText: 'Adresse postale',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.location_on),
                          ),
                          maxLines: 3,
                          validator: (value) {
                            if (_deliveryMethod == 'MAIL' && (value == null || value.isEmpty)) {
                              return 'Adresse requise pour la livraison par courrier';
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),


              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Notes
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (optionnel)',
                      hintText: 'Informations complémentaires...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.note),
                    ),
                    maxLines: 3,
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Bouton submit
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Soumettre la demande',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgentPicker extends StatefulWidget {
  final Function(Map<String, dynamic>) onSelected;
  const _AgentPicker({required this.onSelected});

  @override
  State<_AgentPicker> createState() => _AgentPickerState();
}

class _AgentPickerState extends State<_AgentPicker> {
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final api = ApiService();
    final res = await api.listAgents();
    if (mounted) {
      setState(() {
        _agents = List<Map<String, dynamic>>.from(res['data'] ?? []);
        _filtered = _agents;
        _loading = false;
      });
    }
  }

  void _filter(String q) {
    setState(() {
      _filtered = _agents
          .where((a) =>
              '${a['firstName']} ${a['lastName']}'.toLowerCase().contains(q.toLowerCase()) ||
              a['prefectureAssignment'].toString().toLowerCase().contains(q.toLowerCase()))
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
            'Sélectionner un agent',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: _filter,
            decoration: InputDecoration(
              hintText: 'Rechercher par nom ou préfecture...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_filtered.isEmpty)
            const Center(child: Text('Aucun agent trouvé'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (ctx, i) {
                  final a = _filtered[i];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFD1FAE5),
                      child: Icon(Icons.person, color: Color(0xFF059669)),
                    ),
                    title: Text('${a['firstName']} ${a['lastName']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Préfecture: ${a['prefectureAssignment']}'),
                    onTap: () => widget.onSelected(a),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
