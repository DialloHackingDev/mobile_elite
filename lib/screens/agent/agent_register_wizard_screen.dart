import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/qr_service.dart';
import '../../services/offline_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../success_screen.dart';

class AgentRegisterWizardScreen extends StatefulWidget {
  final Map<String, dynamic>? initialRequest;

  const AgentRegisterWizardScreen({super.key, this.initialRequest});

  @override
  State<AgentRegisterWizardScreen> createState() => _AgentRegisterWizardScreenState();
}

class _AgentRegisterWizardScreenState extends State<AgentRegisterWizardScreen> {
  final _offlineService = OfflineService();
  final _apiService = ApiService();
  
  int _currentStep = 0;
  bool _isLoading = false;
  bool _isOnline = true;
  String? _gpsCoordinates;

  final List<String> _stepTitles = ['ENFANT', 'PARENTS', 'TÉMOINS', 'VALIDATION'];
  final List<String> _stepDescriptions = [
    'Saisissez les informations de\n\'enfant né.',
    'Informations des parents',
    'Informations des témoins',
    'Vérification finale'
  ];

  // Controllers
  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _sexe = TextEditingController(text: 'M');
  final _dateNaissance = TextEditingController();
  final _heureNaissance = TextEditingController();
  final _lieuNaissance = TextEditingController();
  
  final _nomMere = TextEditingController();
  final _dateMere = TextEditingController();
  final _prefectureMere = TextEditingController();
  final _cniMere = TextEditingController();
  final _nomPere = TextEditingController();
  final _datePere = TextEditingController();
  final _cniPere = TextEditingController();
  
  final _temoin1Nom = TextEditingController();
  final _temoin1Cni = TextEditingController();
  final _temoin2Nom = TextEditingController();
  final _temoin2Cni = TextEditingController();
  
  final _codeEtablissement = TextEditingController();
  final _telephoneParent = TextEditingController();

  final List<GlobalKey<FormState>> _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _getCurrentLocation();
    
    // Si une demande a été passée, on pré-remplit les champs
    if (widget.initialRequest != null) {
      final req = widget.initialRequest!;
      _prenom.text = req['childFirstName'] ?? '';
      _nom.text = req['childLastName'] ?? '';
      _sexe.text = req['childGender'] ?? 'M';
      
      if (req['birthDate'] != null) {
        _dateNaissance.text = DateFormat('yyyy-MM-dd').format(DateTime.parse(req['birthDate']));
      }
      _heureNaissance.text = req['timeOfBirth'] ?? '';
      _lieuNaissance.text = req['placeOfBirth'] ?? '';
      
      _nomMere.text = req['motherFullName'] ?? '';
      if (req['motherDob'] != null) {
        _dateMere.text = DateFormat('yyyy-MM-dd').format(DateTime.parse(req['motherDob']));
      }
      _prefectureMere.text = req['motherPrefecture'] ?? '';
      _cniMere.text = req['motherCni'] ?? '';
      
      _nomPere.text = req['fatherFullName'] ?? '';
      if (req['fatherDob'] != null) {
        _datePere.text = DateFormat('yyyy-MM-dd').format(DateTime.parse(req['fatherDob']));
      }
      _cniPere.text = req['fatherCni'] ?? '';
      
      _temoin1Nom.text = req['witness1FullName'] ?? '';
      _temoin1Cni.text = req['witness1Cni'] ?? '';
      _temoin2Nom.text = req['witness2FullName'] ?? '';
      _temoin2Cni.text = req['witness2Cni'] ?? '';
      
      _telephoneParent.text = req['phoneNumber'] ?? '';
    }
  }

  Future<void> _checkConnectivity() async {
    final isOnline = await _apiService.hasInternetConnection();
    setState(() => _isOnline = isOnline);
  }

  Future<void> _getCurrentLocation() async {
    final position = await _offlineService.getCurrentPosition();
    if (position != null) {
      setState(() => _gpsCoordinates = '${position.latitude},${position.longitude}');
    }
  }

  void _nextStep() {
    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      if (_currentStep < 3) {
        setState(() => _currentStep++);
      } else {
        _submitForm();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submitForm() async {
    setState(() => _isLoading = true);

    try {
      final birthData = {
        'childFirstName': _prenom.text,
        'childLastName': _nom.text,
        'childGender': _sexe.text,
        'dateOfBirth': _dateNaissance.text,
        'timeOfBirth': _heureNaissance.text.isEmpty ? null : _heureNaissance.text,
        'placeOfBirth': _lieuNaissance.text,
        'motherFullName': _nomMere.text,
        'motherDob': _dateMere.text,
        'motherPrefecture': _prefectureMere.text,
        'motherCni': _cniMere.text.isEmpty ? null : _cniMere.text,
        'fatherFullName': _nomPere.text.isEmpty ? null : _nomPere.text,
        'fatherDob': _datePere.text.isEmpty ? null : _datePere.text,
        'fatherCni': _cniPere.text.isEmpty ? null : _cniPere.text,
        'witness1FullName': _temoin1Nom.text.isEmpty ? null : _temoin1Nom.text,
        'witness1Cni': _temoin1Cni.text.isEmpty ? null : _temoin1Cni.text,
        'witness2FullName': _temoin2Nom.text.isEmpty ? null : _temoin2Nom.text,
        'witness2Cni': _temoin2Cni.text.isEmpty ? null : _temoin2Cni.text,
        'establishmentCode': _codeEtablissement.text,
        'gpsCoordinates': _gpsCoordinates,
        'parentPhoneNumber': _telephoneParent.text.isEmpty ? null : _telephoneParent.text,
        'isLateRegistration': false,
      };

      if (widget.initialRequest != null) {
        // Appeler le endpoint de validation de demande
        final res = await _apiService.post('/requests/${widget.initialRequest!['id']}/validate', birthData);
        setState(() => _isLoading = false);
        
        if (mounted && res != null && res['status'] == 'success') {
          // Extraire le birth ID et le national ID pour la suite si nécessaire
          final nationalId = res['data']?['birth']?['nationalId'] ?? 'N/A';
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SuccessScreen(
                babyName: "${_prenom.text} ${_nom.text}",
                birthDate: _dateNaissance.text,
                birthPlace: _lieuNaissance.text,
                fatherName: _nomPere.text.isEmpty ? "Non renseigné" : _nomPere.text,
                motherName: _nomMere.text,
                blockchainId: QRService.generateBlockchainId(),
                nationalId: nationalId,
                isOffline: false,
              ),
            ),
          );
        } else {
          throw Exception(res?['message'] ?? 'Erreur lors de la validation');
        }
      } else {
        // Flux standard
        if (_isOnline) {
          final result = await _apiService.registerBirth(birthData);
          setState(() => _isLoading = false);

          if (result['success'] && mounted) {
            final data = result['data'];
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SuccessScreen(
                  babyName: "${_prenom.text} ${_nom.text}",
                  birthDate: _dateNaissance.text,
                  birthPlace: _lieuNaissance.text,
                  fatherName: _nomPere.text.isEmpty ? "Non renseigné" : _nomPere.text,
                  motherName: _nomMere.text,
                  blockchainId: data['blockchainHash'] ?? QRService.generateBlockchainId(),
                  nationalId: data['nationalId'],
                  isOffline: false,
                ),
              ),
            );
          } else {
            _showError(result['error'] ?? 'Erreur d\'enregistrement');
          }
        } else {
          // Mode hors-ligne
          final agent = AuthService.currentAgent;
          await _offlineService.saveOfflineBirth(
            childFirstName: _prenom.text,
            childLastName: _nom.text,
            childGender: _sexe.text,
            dateOfBirth: _dateNaissance.text,
            placeOfBirth: _lieuNaissance.text,
            motherFullName: _nomMere.text,
            motherDob: _dateMere.text,
            motherPrefecture: _prefectureMere.text,
            establishmentCode: _codeEtablissement.text,
            agentId: agent?.id ?? 'unknown',
            timeOfBirth: _heureNaissance.text.isEmpty ? null : _heureNaissance.text,
            motherCni: _cniMere.text.isEmpty ? null : _cniMere.text,
            fatherFullName: _nomPere.text.isEmpty ? null : _nomPere.text,
            fatherDob: _datePere.text.isEmpty ? null : _datePere.text,
            fatherCni: _cniPere.text.isEmpty ? null : _cniPere.text,
            gpsCoordinates: _gpsCoordinates,
            parentPhoneNumber: _telephoneParent.text.isEmpty ? null : _telephoneParent.text,
            witness1FullName: _temoin1Nom.text.isEmpty ? null : _temoin1Nom.text,
            witness1Cni: _temoin1Cni.text.isEmpty ? null : _temoin1Cni.text,
            witness2FullName: _temoin2Nom.text.isEmpty ? null : _temoin2Nom.text,
            witness2Cni: _temoin2Cni.text.isEmpty ? null : _temoin2Cni.text,
          );
          setState(() => _isLoading = false);

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => SuccessScreen(
                  babyName: "${_prenom.text} ${_nom.text}",
                  birthDate: _dateNaissance.text,
                  birthPlace: _lieuNaissance.text,
                  fatherName: _nomPere.text.isEmpty ? "Non renseigné" : _nomPere.text,
                  motherName: _nomMere.text,
                  blockchainId: QRService.generateBlockchainId(),
                  nationalId: null,
                  isOffline: true,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec steps
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Steps indicator
                  Row(
                    children: List.generate(4, (index) {
                      final isActive = index == _currentStep;
                      final isCompleted = index < _currentStep;
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFF059669)
                                          : isCompleted
                                              ? const Color(0xFF059669).withOpacity(0.2)
                                              : Colors.grey[200],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isActive || isCompleted
                                            ? const Color(0xFF059669)
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? const Icon(Icons.check, color: Color(0xFF059669), size: 20)
                                          : Text(
                                              '${index + 1}',
                                              style: GoogleFonts.poppins(
                                                color: isActive ? Colors.white : Colors.grey[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _stepTitles[index],
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      color: isActive ? const Color(0xFF059669) : Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (index < 3)
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: index < _currentStep
                                      ? const Color(0xFF059669)
                                      : Colors.grey[300],
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre
                    Text(
                      _stepDescriptions[_currentStep].split('\n')[0],
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    if (_stepDescriptions[_currentStep].contains('\n'))
                      Text(
                        _stepDescriptions[_currentStep].split('\n')[1],
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      'Veuillez remplir soigneusement les détails pour\n\'enregistrement au registre civil blockchain.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Form content
                    _buildStepContent(),
                  ],
                ),
              ),
            ),

            // Footer avec boutons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // Indicateur connexion
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? const Color(0xFF059669).withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _isOnline ? const Color(0xFF059669) : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isOnline ? 'CONNEXION LEDGER ACTIVE' : 'MODE HORS-LIGNE',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _isOnline ? const Color(0xFF059669) : Colors.orange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Boutons navigation
                    Row(
                      children: [
                        if (_currentStep > 0)
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _previousStep,
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Retour'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: Color(0xFF059669)),
                                foregroundColor: const Color(0xFF059669),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        if (_currentStep > 0) const SizedBox(width: 12),
                        Expanded(
                          flex: _currentStep == 0 ? 2 : 1,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _nextStep,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Icon(_currentStep == 3 ? Icons.check : Icons.arrow_forward),
                            label: Text(
                              _currentStep == 3
                                  ? 'Valider l\'enregistrement'
                                  : 'Suivant',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildEnfantStep();
      case 1:
        return _buildParentsStep();
      case 2:
        return _buildTemoinsStep();
      case 3:
        return _buildValidationStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildEnfantStep() {
    return Form(
      key: _formKeys[0],
      child: Column(
        children: [
          _buildTextField(
            controller: _prenom,
            label: 'PRÉNOM(S)',
            hint: 'Ex: Jean-Luc',
            icon: Icons.person_outline,
            validator: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nom,
            label: 'NOM',
            hint: 'Ex: Diallo',
            icon: Icons.person_outline,
            validator: true,
          ),
          const SizedBox(height: 20),
          
          // Sexe
          Text(
            'SEXE',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSexeCard('M', 'Masculin', Icons.male),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSexeCard('F', 'Féminin', Icons.female),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  controller: _dateNaissance,
                  label: 'DATE DE NAISSANCE',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _heureNaissance,
                  label: 'HEURE',
                  hint: '--:--',
                  icon: Icons.access_time_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _lieuNaissance,
            label: 'LIEU DE NAISSANCE (HÔPITAL / DISTRICT)',
            hint: 'Sélectionnez un lieu',
            icon: Icons.location_on_outlined,
            validator: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSexeCard(String value, String label, IconData icon) {
    final isSelected = _sexe.text == value;
    return GestureDetector(
      onTap: () => setState(() => _sexe.text = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF059669).withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFF059669) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF059669) : Colors.grey[500],
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? const Color(0xFF059669) : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentsStep() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mère
          Text(
            'INFORMATIONS DE LA MÈRE',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nomMere,
            label: 'Nom complet de la mère *',
            icon: Icons.pregnant_woman_outlined,
            validator: true,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  controller: _dateMere,
                  label: 'Date de naissance *',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _prefectureMere,
                  label: 'Préfecture *',
                  icon: Icons.location_city_outlined,
                  validator: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _cniMere,
            label: 'Numéro CNI',
            icon: Icons.credit_card_outlined,
          ),
          const SizedBox(height: 24),

          // Père
          Text(
            'INFORMATIONS DU PÈRE (OPTIONNEL)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nomPere,
            label: 'Nom complet du père',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  controller: _datePere,
                  label: 'Date de naissance',
                  icon: Icons.calendar_today_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _cniPere,
                  label: 'Numéro CNI',
                  icon: Icons.credit_card_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _telephoneParent,
            label: 'Téléphone des parents (pour notification)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildTemoinsStep() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TÉMOIN 1',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _temoin1Nom,
            label: 'Nom complet du témoin 1',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _temoin1Cni,
            label: 'Numéro CNI',
            icon: Icons.credit_card_outlined,
          ),
          const SizedBox(height: 24),

          Text(
            'TÉMOIN 2',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _temoin2Nom,
            label: 'Nom complet du témoin 2',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _temoin2Cni,
            label: 'Numéro CNI',
            icon: Icons.credit_card_outlined,
          ),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _codeEtablissement,
            label: 'Code établissement *',
            hint: 'Ex: MAT-CNK-001',
            icon: Icons.local_hospital_outlined,
            validator: true,
          ),
        ],
      ),
    );
  }

  Widget _buildValidationStep() {
    return Form(
      key: _formKeys[3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Text(
                      'Résumé de l\'enregistrement',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryItem('Enfant', '${_prenom.text} ${_nom.text}'),
                _buildSummaryItem('Sexe', _sexe.text == 'M' ? 'Masculin' : 'Féminin'),
                _buildSummaryItem('Date de naissance', _dateNaissance.text),
                _buildSummaryItem('Lieu', _lieuNaissance.text),
                _buildSummaryItem('Mère', _nomMere.text),
                if (_nomPere.text.isNotEmpty)
                  _buildSummaryItem('Père', _nomPere.text),
                if (_temoin1Nom.text.isNotEmpty)
                  _buildSummaryItem('Témoin 1', _temoin1Nom.text),
                if (_gpsCoordinates != null)
                  _buildSummaryItem('Coordonnées GPS', _gpsCoordinates!),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'En validant, vous confirmez que toutes les informations sont exactes et conformes au registre civil.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    bool validator = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[400]),
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
          borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        hintText: 'mm/dd/yyyy',
        prefixIcon: Icon(icon, color: Colors.grey[400]),
        suffixIcon: Icon(Icons.calendar_today, color: Colors.grey[400], size: 18),
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
          borderSide: const BorderSide(color: Color(0xFF059669), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
}
