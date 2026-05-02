/// Modèle représentant un agent d'état civil
class Agent {
  final String id;
  final String nationalAgentId;
  final String firstName;
  final String lastName;
  final String role;
  final String status;
  final String prefectureAssignment;
  final bool twoFactorEnabled;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final String? email;
  final String? phoneNumber;
  final String? establishmentId;

  Agent({
    required this.id,
    required this.nationalAgentId,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.status,
    required this.prefectureAssignment,
    this.twoFactorEnabled = false,
    this.lastLogin,
    required this.createdAt,
    this.email,
    this.phoneNumber,
    this.establishmentId,
  });

  /// Nom complet de l'agent
  String get fullName => '$firstName $lastName';

  /// Alias pour nationalAgentId (pour compatibilité UI)
  String get nationalId => nationalAgentId;

  /// Vérifier si l'agent est actif
  bool get isActive => status == 'ACTIVE';

  /// Vérifier si l'agent est admin
  bool get isAdmin => role == 'ADMIN' || role == 'MINISTRY';

  /// Convertir en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nationalAgentId': nationalAgentId,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'status': status,
      'prefectureAssignment': prefectureAssignment,
      'twoFactorEnabled': twoFactorEnabled,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'email': email,
      'phoneNumber': phoneNumber,
      'establishmentId': establishmentId,
    };
  }

  /// Créer un Agent depuis JSON
  factory Agent.fromJson(Map<String, dynamic> json) {
    final agentData = json['agent'] ?? json;
    return Agent(
      id: agentData['id'] ?? '',
      nationalAgentId: agentData['nationalAgentId'] ?? agentData['nationalId'] ?? '',
      firstName: agentData['firstName'] ?? '',
      lastName: agentData['lastName'] ?? '',
      role: agentData['role'] ?? 'AGENT',
      status: agentData['status'] ?? 'ACTIVE',
      prefectureAssignment: agentData['prefectureAssignment'] ?? '',
      twoFactorEnabled: agentData['twoFactorEnabled'] ?? false,
      lastLogin: agentData['lastLogin'] != null 
          ? DateTime.parse(agentData['lastLogin'])
          : null,
      createdAt: agentData['createdAt'] != null
          ? DateTime.parse(agentData['createdAt'])
          : DateTime.now(),
      email: agentData['email'],
      phoneNumber: agentData['phoneNumber'],
      establishmentId: agentData['establishmentId'],
    );
  }

  /// Créer une copie avec des champs modifiés
  Agent copyWith({
    String? id,
    String? nationalAgentId,
    String? firstName,
    String? lastName,
    String? role,
    String? status,
    String? prefectureAssignment,
    bool? twoFactorEnabled,
    DateTime? lastLogin,
    DateTime? createdAt,
    String? email,
    String? phoneNumber,
    String? establishmentId,
  }) {
    return Agent(
      id: id ?? this.id,
      nationalAgentId: nationalAgentId ?? this.nationalAgentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
      status: status ?? this.status,
      prefectureAssignment: prefectureAssignment ?? this.prefectureAssignment,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      establishmentId: establishmentId ?? this.establishmentId,
    );
  }

  @override
  String toString() {
    return 'Agent(id: $id, name: $fullName, role: $role, status: $status)';
  }
}

/// Rôles disponibles pour les agents
class AgentRoles {
  static const String AGENT = 'AGENT';
  static const String ADMIN = 'ADMIN';
  static const String MINISTRY = 'MINISTRY';
  static const String JUSTICE = 'JUSTICE';
  static const String CITIZEN = 'CITIZEN';
}

/// Statuts possibles pour les agents
class AgentStatus {
  static const String ACTIVE = 'ACTIVE';
  static const String INACTIVE = 'INACTIVE';
  static const String SUSPENDED = 'SUSPENDED';
}
