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
  final _childNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;

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
        'childName': _childNameController.text.isNotEmpty ? _childNameController.text : null,
        'phoneNumber': _phoneController.text.isNotEmpty ? _phoneController.text : null,
        'email': _emailController.text.isNotEmpty ? _emailController.text : null,
        'address': _addressController.text.isNotEmpty ? _addressController.text : null,
        'notes': _notesController.text.isNotEmpty ? _notesController.text : null,
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

              // Nom de l'enfant (optionnel)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextFormField(
                    controller: _childNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom de l\'enfant (optionnel)',
                      hintText: 'Ex: Mamadou Diallo',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.child_care),
                    ),
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
