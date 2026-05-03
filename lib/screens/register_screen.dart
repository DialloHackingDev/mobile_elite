import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/offline_service.dart';
import '../services/qr_service.dart';
import 'success_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final OfflineService _offlineService = OfflineService();
  final ApiService _apiService = ApiService();

  // Contrôleurs
  final name = TextEditingController();
  final prenom = TextEditingController();
  final date = TextEditingController();
  final lieu = TextEditingController();
  final pere = TextEditingController();
  final agePere = TextEditingController();
  final mere = TextEditingController();
  final ageMere = TextEditingController();
  final sexe = TextEditingController(text: 'M');
  final timeOfBirth = TextEditingController();
  final motherPrefecture = TextEditingController();
  final establishmentCode = TextEditingController();
  final parentPhone = TextEditingController();

  bool _isLoading = false;
  bool _isOnline = true;
  String? _gpsCoordinates;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _getCurrentLocation();
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await _apiService.hasInternetConnection();
    setState(() {
      _isOnline = isOnline;
    });
  }

  Future<void> _getCurrentLocation() async {
    final position = await _offlineService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _gpsCoordinates = _offlineService.formatCoordinates(position);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false, // Pas de bouton retour — on est dans le dashboard
        title: Text(
          'Nouvelle Naissance',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Indicateur de connectivité
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: _isOnline ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 6),
                Text(
                  _isOnline ? 'En ligne' : 'Hors-ligne',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    _isOnline
                        ? 'Enregistrement en cours...'
                        : 'Sauvegarde locale en cours...',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header avec GPS
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor,
                                primaryColor.withOpacity(0.8),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.child_care,
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
                                          "Nouvelle Naissance",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "Enregistrement des informations",
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (_gpsCoordinates != null) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Colors.white70,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'GPS: $_gpsCoordinates',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white70,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 24),

                        // Section Informations bébé
                        _buildSectionHeader(context, "Informations du bébé", Icons.child_care, primaryColor),
                        const SizedBox(height: 12),

                        _buildCard(
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: prenom,
                                label: "Prénom(s) *",
                                icon: Icons.badge_outlined,
                                validator: true,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: name,
                                label: "Nom *",
                                icon: Icons.person_outline,
                                validator: true,
                              ),
                              const SizedBox(height: 16),
                              _buildDropdown(
                                label: "Sexe *",
                                value: sexe.text,
                                items: const [
                                  DropdownMenuItem(value: 'M', child: Text('Masculin')),
                                  DropdownMenuItem(value: 'F', child: Text('Féminin')),
                                ],
                                onChanged: (value) => setState(() => sexe.text = value!),
                                icon: Icons.wc_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildDateField(
                                controller: date,
                                label: "Date de naissance *",
                                icon: Icons.calendar_today_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: timeOfBirth,
                                label: "Heure de naissance",
                                icon: Icons.access_time_outlined,
                                hintText: "HH:MM",
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: lieu,
                                label: "Lieu de naissance *",
                                icon: Icons.location_on_outlined,
                                validator: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section Mère
                        _buildSectionHeader(context, "Informations de la mère", Icons.pregnant_woman, primaryColor),
                        const SizedBox(height: 12),

                        _buildCard(
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: mere,
                                label: "Nom complet de la mère *",
                                icon: Icons.person_outline,
                                validator: true,
                              ),
                              const SizedBox(height: 16),
                              _buildDateField(
                                controller: ageMere,
                                label: "Date de naissance de la mère *",
                                icon: Icons.calendar_today_outlined,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: motherPrefecture,
                                label: "Préfecture de la mère *",
                                icon: Icons.map_outlined,
                                validator: true,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section Père
                        _buildSectionHeader(context, "Informations du père", Icons.person, primaryColor),
                        const SizedBox(height: 12),

                        _buildCard(
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: pere,
                                label: "Nom complet du père",
                                icon: Icons.person_outline,
                              ),
                              const SizedBox(height: 16),
                              _buildDateField(
                                controller: agePere,
                                label: "Date de naissance du père",
                                icon: Icons.calendar_today_outlined,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Section Établissement
                        _buildSectionHeader(context, "Établissement", Icons.business, primaryColor),
                        const SizedBox(height: 12),

                        _buildCard(
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: establishmentCode,
                                label: "Code établissement *",
                                icon: Icons.local_hospital_outlined,
                                hintText: "EX: IGN-001",
                                validator: true,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: parentPhone,
                                label: "Téléphone des parents",
                                icon: Icons.phone_outlined,
                                hintText: "+224621XXXXXX",
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Bouton d'enregistrement premium
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.save_outlined),
                                const SizedBox(width: 12),
                                Text(
                                  _isOnline ? "Enregistrer" : "Sauvegarder localement",
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: 200.ms),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
  
  // ==================== WIDGETS PREMIUM ====================

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, Color primaryColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: primaryColor,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool validator = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: validator
          ? (value) => value!.isEmpty ? "Ce champ est obligatoire" : null
          : null,
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(date);
        }
      },
      validator: (value) => value!.isEmpty ? "Ce champ est obligatoire" : null,
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // ==================== SOUMISSION DU FORMULAIRE ====================

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Format de date pour l'API
      final birthDateFormatted = date.text;
      final motherDobFormatted = ageMere.text;
      final fatherDobFormatted = agePere.text.isEmpty ? null : agePere.text;

      if (_isOnline) {
        // Mode en ligne - envoyer directement au backend
        final birthData = <String, dynamic>{
          'childFirstName':    prenom.text.trim(),
          'childLastName':     name.text.trim(),
          'childGender':       sexe.text,
          'dateOfBirth':       date.text,
          'placeOfBirth':      lieu.text.trim(),
          'motherFullName':    mere.text.trim(),
          'motherDob':         ageMere.text,
          'motherPrefecture':  motherPrefecture.text.trim(),
          'establishmentCode': establishmentCode.text.trim(),
          'isLateRegistration': false,
        };

        // Champs optionnels : n'ajouter que s'ils ont une valeur
        if (timeOfBirth.text.isNotEmpty) birthData['timeOfBirth'] = timeOfBirth.text;
        if (pere.text.isNotEmpty)        birthData['fatherFullName'] = pere.text.trim();
        if (agePere.text.isNotEmpty)     birthData['fatherDob'] = agePere.text;
        if (_gpsCoordinates != null)     birthData['gpsCoordinates'] = _gpsCoordinates;
        if (parentPhone.text.isNotEmpty) birthData['parentPhoneNumber'] = parentPhone.text.trim();

        final result = await _apiService.registerBirth(birthData);

        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          final data = result['data'] as Map<String, dynamic>? ?? {};
          final blockchainId = (data['blockchainHash'] as String?) ?? QRService.generateBlockchainId();

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SuccessScreen(
                  babyName: "${prenom.text} ${name.text}",
                  birthDate: date.text,
                  birthPlace: lieu.text,
                  fatherName: pere.text.isEmpty ? "Non renseigné" : pere.text,
                  motherName: mere.text,
                  blockchainId: blockchainId,
                  nationalId: data['nationalId'] as String?,
                  isOffline: false,
                ),
              ),
            );
          }
        } else {
          // Afficher le message d'erreur précis du backend
          final errMsg = result['message'] as String?
              ?? result['error'] as String?
              ?? 'Erreur d\'enregistrement';
          _showError(errMsg);
        }
      } else {
        // Mode hors-ligne - sauvegarder localement
        final agent = AuthService.currentAgent;
        final agentId = agent?.id ?? 'unknown';

        await _offlineService.saveOfflineBirth(
          childFirstName: prenom.text,
          childLastName: name.text,
          childGender: sexe.text,
          dateOfBirth: birthDateFormatted,
          placeOfBirth: lieu.text,
          motherFullName: mere.text,
          motherDob: motherDobFormatted,
          motherPrefecture: motherPrefecture.text,
          establishmentCode: establishmentCode.text,
          agentId: agentId,
          timeOfBirth: timeOfBirth.text.isEmpty ? null : timeOfBirth.text,
          fatherFullName: pere.text.isEmpty ? null : pere.text,
          fatherDob: fatherDobFormatted,
          gpsCoordinates: _gpsCoordinates,
          parentPhoneNumber: parentPhone.text.isEmpty ? null : parentPhone.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          final blockchainId = QRService.generateBlockchainId();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => SuccessScreen(
                babyName: "${prenom.text} ${name.text}",
                birthDate: date.text,
                birthPlace: lieu.text,
                fatherName: pere.text.isEmpty ? "Non renseigné" : pere.text,
                motherName: mere.text,
                blockchainId: blockchainId,
                isOffline: true,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Erreur: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}