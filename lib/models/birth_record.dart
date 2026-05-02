class BirthRecord {
  final String id;
  final String babyFirstName;
  final String babyLastName;
  final String birthDate;
  final String birthPlace;
  final String fatherName;
  final String fatherAge;
  final String motherName;
  final String motherAge;
  final String blockchainId;
  final DateTime registrationDate;
  final String qrCodeData;

  BirthRecord({
    required this.id,
    required this.babyFirstName,
    required this.babyLastName,
    required this.birthDate,
    required this.birthPlace,
    required this.fatherName,
    required this.fatherAge,
    required this.motherName,
    required this.motherAge,
    required this.blockchainId,
    required this.registrationDate,
    required this.qrCodeData,
  });

  // Getters
  String get babyFullName => '$babyFirstName $babyLastName';
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'babyFirstName': babyFirstName,
      'babyLastName': babyLastName,
      'birthDate': birthDate,
      'birthPlace': birthPlace,
      'fatherName': fatherName,
      'fatherAge': fatherAge,
      'motherName': motherName,
      'motherAge': motherAge,
      'blockchainId': blockchainId,
      'registrationDate': registrationDate.toIso8601String(),
      'qrCodeData': qrCodeData,
    };
  }

  factory BirthRecord.fromJson(Map<String, dynamic> json) {
    return BirthRecord(
      id: json['id'],
      babyFirstName: json['babyFirstName'],
      babyLastName: json['babyLastName'],
      birthDate: json['birthDate'],
      birthPlace: json['birthPlace'],
      fatherName: json['fatherName'],
      fatherAge: json['fatherAge'],
      motherName: json['motherName'],
      motherAge: json['motherAge'],
      blockchainId: json['blockchainId'],
      registrationDate: DateTime.parse(json['registrationDate']),
      qrCodeData: json['qrCodeData'],
    );
  }

  // Create a copy with updated fields
  BirthRecord copyWith({
    String? id,
    String? babyFirstName,
    String? babyLastName,
    String? birthDate,
    String? birthPlace,
    String? fatherName,
    String? fatherAge,
    String? motherName,
    String? motherAge,
    String? blockchainId,
    DateTime? registrationDate,
    String? qrCodeData,
  }) {
    return BirthRecord(
      id: id ?? this.id,
      babyFirstName: babyFirstName ?? this.babyFirstName,
      babyLastName: babyLastName ?? this.babyLastName,
      birthDate: birthDate ?? this.birthDate,
      birthPlace: birthPlace ?? this.birthPlace,
      fatherName: fatherName ?? this.fatherName,
      fatherAge: fatherAge ?? this.fatherAge,
      motherName: motherName ?? this.motherName,
      motherAge: motherAge ?? this.motherAge,
      blockchainId: blockchainId ?? this.blockchainId,
      registrationDate: registrationDate ?? this.registrationDate,
      qrCodeData: qrCodeData ?? this.qrCodeData,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BirthRecord && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'BirthRecord(id: $id, babyFullName: $babyFullName, birthDate: $birthDate, birthPlace: $birthPlace)';
  }
}
