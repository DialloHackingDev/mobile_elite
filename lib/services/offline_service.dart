import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_service.dart';

/// Service de gestion du mode hors-ligne avec SQLite
class OfflineService {
  static const String _databaseName = 'naissancechain.db';
  static const int _databaseVersion = 1;

  // Tables
  static const String _birthsTable = 'offline_births';
  static const String _syncQueueTable = 'sync_queue';
  static const String _settingsTable = 'app_settings';

  // Singleton
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  Database? _database;
  final ApiService _apiService = ApiService();
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  bool _isOnline = true;

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;

  /// Initialiser la base de données SQLite
  Future<void> initialize() async {
    if (kIsWeb) {
      print('🌐 Mode Web détecté : SQLite désactivé');
      return;
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _databaseName);

    _database = await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // Écouter les changements de connectivité
    Connectivity().onConnectivityChanged.listen((result) {
      final wasOffline = !_isOnline;
      _isOnline = result != ConnectivityResult.none;
      _connectivityController.add(_isOnline);

      // Si on revient en ligne, tenter la synchronisation
      if (wasOffline && _isOnline) {
        syncPendingBirths();
      }
    });

    // Vérifier l'état initial
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
  }

  /// Créer les tables
  Future<void> _onCreate(Database db, int version) async {
    // Table des naissances hors-ligne
    await db.execute('''
      CREATE TABLE $_birthsTable (
        id TEXT PRIMARY KEY,
        local_id TEXT UNIQUE NOT NULL,
        child_first_name TEXT NOT NULL,
        child_last_name TEXT NOT NULL,
        child_gender TEXT NOT NULL,
        date_of_birth TEXT NOT NULL,
        time_of_birth TEXT,
        place_of_birth TEXT NOT NULL,
        mother_full_name TEXT NOT NULL,
        mother_dob TEXT NOT NULL,
        mother_prefecture TEXT NOT NULL,
        mother_cni TEXT,
        father_full_name TEXT,
        father_dob TEXT,
        father_cni TEXT,
        establishment_code TEXT NOT NULL,
        gps_coordinates TEXT,
        parent_phone_number TEXT,
        is_late_registration INTEGER DEFAULT 0,
        witness1_full_name TEXT,
        witness1_cni TEXT,
        witness2_full_name TEXT,
        witness2_cni TEXT,
        status TEXT DEFAULT 'pending',
        sync_status TEXT DEFAULT 'pending',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_error TEXT,
        retry_count INTEGER DEFAULT 0,
        agent_id TEXT NOT NULL
      )
    ''');

    // File de synchronisation
    await db.execute('''
      CREATE TABLE $_syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        birth_local_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        priority INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        processed_at TEXT,
        error_message TEXT,
        FOREIGN KEY (birth_local_id) REFERENCES $_birthsTable(local_id)
      )
    ''');

    // Paramètres de l'application
    await db.execute('''
      CREATE TABLE $_settingsTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Index pour optimiser les recherches
    await db.execute('CREATE INDEX idx_births_status ON $_birthsTable(sync_status)');
    await db.execute('CREATE INDEX idx_births_agent ON $_birthsTable(agent_id)');
    await db.execute('CREATE INDEX idx_sync_queue ON $_syncQueueTable(processed_at)');
  }

  /// Mise à jour de la base de données
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gérer les migrations futures ici
  }

  // ==================== CRUD NAISSANCES ====================

  /// Sauvegarder une naissance en mode hors-ligne
  Future<String> saveOfflineBirth({
    required String childFirstName,
    required String childLastName,
    required String childGender,
    required String dateOfBirth,
    required String placeOfBirth,
    required String motherFullName,
    required String motherDob,
    required String motherPrefecture,
    required String establishmentCode,
    required String agentId,
    String? timeOfBirth,
    String? motherCni,
    String? fatherFullName,
    String? fatherDob,
    String? fatherCni,
    String? gpsCoordinates,
    String? parentPhoneNumber,
    bool isLateRegistration = false,
    String? witness1FullName,
    String? witness1Cni,
    String? witness2FullName,
    String? witness2Cni,
  }) async {
    if (_database == null) return 'WEB-MODE-NO-SAVE';
    final db = _database!;
    final now = DateTime.now().toIso8601String();
    final localId = 'LOCAL-${DateTime.now().millisecondsSinceEpoch}';

    await db.insert(_birthsTable, {
      'id': localId,
      'local_id': localId,
      'child_first_name': childFirstName,
      'child_last_name': childLastName,
      'child_gender': childGender,
      'date_of_birth': dateOfBirth,
      'time_of_birth': timeOfBirth,
      'place_of_birth': placeOfBirth,
      'mother_full_name': motherFullName,
      'mother_dob': motherDob,
      'mother_prefecture': motherPrefecture,
      'mother_cni': motherCni,
      'father_full_name': fatherFullName,
      'father_dob': fatherDob,
      'father_cni': fatherCni,
      'establishment_code': establishmentCode,
      'gps_coordinates': gpsCoordinates,
      'parent_phone_number': parentPhoneNumber,
      'is_late_registration': isLateRegistration ? 1 : 0,
      'witness1_full_name': witness1FullName,
      'witness1_cni': witness1Cni,
      'witness2_full_name': witness2FullName,
      'witness2_cni': witness2Cni,
      'status': 'pending',
      'sync_status': 'pending',
      'created_at': now,
      'updated_at': now,
      'agent_id': agentId,
      'retry_count': 0,
    });

    // Ajouter à la file de synchronisation
    await db.insert(_syncQueueTable, {
      'birth_local_id': localId,
      'operation': 'CREATE',
      'priority': isLateRegistration ? 1 : 0, // Priorité plus haute pour les actes tardifs
      'created_at': now,
    });

    return localId;
  }

  /// Récupérer toutes les naissances hors-ligne
  Future<List<Map<String, dynamic>>> getOfflineBirths() async {
    if (_database == null) return [];
    final db = _database!;

    final results = await db.query(
      _birthsTable,
      orderBy: 'created_at DESC',
    );

    return results.map((row) => _mapBirthRow(row)).toList();
  }

  /// Récupérer une naissance par ID local
  Future<Map<String, dynamic>?> getOfflineBirthById(String localId) async {
    if (_database == null) return null;
    final db = _database!;

    final results = await db.query(
      _birthsTable,
      where: 'local_id = ?',
      whereArgs: [localId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _mapBirthRow(results.first);
  }

  /// Mettre à jour une naissance
  Future<void> updateOfflineBirth(String localId, Map<String, dynamic> updates) async {
    if (_database == null) return;
    final db = _database!;
    final now = DateTime.now().toIso8601String();

    updates['updated_at'] = now;

    await db.update(
      _birthsTable,
      updates,
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Supprimer une naissance
  Future<void> deleteOfflineBirth(String localId) async {
    if (_database == null) return;
    final db = _database!;

    await db.delete(
      _birthsTable,
      where: 'local_id = ?',
      whereArgs: [localId],
    );

    // Supprimer aussi de la file de sync
    await db.delete(
      _syncQueueTable,
      where: 'birth_local_id = ? AND processed_at IS NULL',
      whereArgs: [localId],
    );
  }

  /// Mapper une ligne de base de données vers un objet
  Map<String, dynamic> _mapBirthRow(Map<String, dynamic> row) {
    return {
      'id': row['id'],
      'localId': row['local_id'],
      'childFirstName': row['child_first_name'],
      'childLastName': row['child_last_name'],
      'childGender': row['child_gender'],
      'dateOfBirth': row['date_of_birth'],
      'timeOfBirth': row['time_of_birth'],
      'placeOfBirth': row['place_of_birth'],
      'motherFullName': row['mother_full_name'],
      'motherDob': row['mother_dob'],
      'motherPrefecture': row['mother_prefecture'],
      'motherCni': row['mother_cni'],
      'fatherFullName': row['father_full_name'],
      'fatherDob': row['father_dob'],
      'fatherCni': row['father_cni'],
      'establishmentCode': row['establishment_code'],
      'gpsCoordinates': row['gps_coordinates'],
      'parentPhoneNumber': row['parent_phone_number'],
      'isLateRegistration': row['is_late_registration'] == 1,
      'witness1FullName': row['witness1_full_name'],
      'witness1Cni': row['witness1_cni'],
      'witness2FullName': row['witness2_full_name'],
      'witness2Cni': row['witness2_cni'],
      'status': row['status'],
      'syncStatus': row['sync_status'],
      'createdAt': row['created_at'],
      'updatedAt': row['updated_at'],
      'syncError': row['sync_error'],
      'retryCount': row['retry_count'],
      'agentId': row['agent_id'],
    };
  }

  // ==================== SYNCHRONISATION ====================

  /// Synchroniser les naissances en attente
  Future<Map<String, dynamic>> syncPendingBirths() async {
    if (!_isOnline) {
      return {'success': false, 'error': 'Pas de connexion internet'};
    }

    final allBirths = await getOfflineBirths();
    final pendingBirths = allBirths.where((birth) => birth['syncStatus'] == 'pending').toList();

    if (pendingBirths.isEmpty) {
      return {'success': true, 'message': 'Rien à synchroniser', 'synced': 0};
    }

    int syncedCount = 0;
    int failedCount = 0;
    List<String> errors = [];

    for (final birth in pendingBirths) {
      try {
        final result = await _syncSingleBirth(birth);

        if (result['success']) {
          syncedCount++;
          await updateOfflineBirth(birth['localId'], {
            'sync_status': 'synced',
            'national_id': result['data']?['nationalId'],
            'blockchain_hash': result['data']?['blockchainHash'],
            'ipfs_cid': result['data']?['ipfsCid'],
          });
        } else {
          failedCount++;
          errors.add('${birth['localId']}: ${result['error']}');

          final newRetryCount = (birth['retryCount'] ?? 0) + 1;
          await updateOfflineBirth(birth['localId'], {
            'sync_status': newRetryCount >= 3 ? 'failed' : 'pending',
            'sync_error': result['error'],
            'retry_count': newRetryCount,
          });
        }
      } catch (e) {
        failedCount++;
        errors.add('${birth['localId']}: $e');
      }
    }

    return {
      'success': failedCount == 0,
      'synced': syncedCount,
      'failed': failedCount,
      'errors': errors,
    };
  }

  /// Synchroniser une naissance individuelle
  Future<Map<String, dynamic>> _syncSingleBirth(Map<String, dynamic> birth) async {
    final birthData = {
      'childFirstName': birth['childFirstName'],
      'childLastName': birth['childLastName'],
      'childGender': birth['childGender'],
      'dateOfBirth': birth['dateOfBirth'],
      'timeOfBirth': birth['timeOfBirth'],
      'placeOfBirth': birth['placeOfBirth'],
      'motherFullName': birth['motherFullName'],
      'motherDob': birth['motherDob'],
      'motherPrefecture': birth['motherPrefecture'],
      'motherCni': birth['motherCni'],
      'fatherFullName': birth['fatherFullName'],
      'fatherDob': birth['fatherDob'],
      'fatherCni': birth['fatherCni'],
      'establishmentCode': birth['establishmentCode'],
      'gpsCoordinates': birth['gpsCoordinates'],
      'parentPhoneNumber': birth['parentPhoneNumber'],
      'isLateRegistration': birth['isLateRegistration'],
      'witness1FullName': birth['witness1FullName'],
      'witness1Cni':      birth['witness1Cni'],
      'witness2FullName': birth['witness2FullName'],
      'witness2Cni':      birth['witness2Cni'],
      'localId':          birth['localId'],
    };

    return await _apiService.registerBirth(birthData);
  }

  /// Obtenir les statistiques de synchronisation
  Future<Map<String, dynamic>> getSyncStats() async {
    if (_database == null) return {'total': 0, 'pending': 0, 'synced': 0, 'failed': 0};
    final db = _database!;

    final totalResult = await db.rawQuery('SELECT COUNT(*) as count FROM $_birthsTable');
    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_birthsTable WHERE sync_status = ?',
      ['pending'],
    );
    final syncedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_birthsTable WHERE sync_status = ?',
      ['synced'],
    );
    final failedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_birthsTable WHERE sync_status = ?',
      ['failed'],
    );

    return {
      'total': totalResult.first['count'] as int,
      'pending': pendingResult.first['count'] as int,
      'synced': syncedResult.first['count'] as int,
      'failed': failedResult.first['count'] as int,
    };
  }

  // ==================== GPS & LOCALISATION ====================

  /// Obtenir la position GPS actuelle
  Future<Position?> getCurrentPosition() async {
    try {
      // Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Erreur GPS: $e');
      return null;
    }
  }

  /// Formater les coordonnées GPS
  String formatCoordinates(Position position) {
    return '${position.latitude},${position.longitude}';
  }

  // ==================== PARAMÈTRES ====================

  /// Sauvegarder un paramètre
  Future<void> setSetting(String key, String value) async {
    if (_database == null) return;
    final db = _database!;
    final now = DateTime.now().toIso8601String();

    await db.insert(
      _settingsTable,
      {
        'key': key,
        'value': value,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Récupérer un paramètre
  Future<String?> getSetting(String key) async {
    if (_database == null) return null;
    final db = _database!;

    final results = await db.query(
      _settingsTable,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return results.first['value'] as String;
  }

  // ==================== MÉTHODES POUR UI ====================

  /// Récupérer le nombre de naissances en attente de synchronisation
  Future<int> getPendingSyncCount() async {
    if (_database == null) return 0;
    final db = _database!;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $_birthsTable WHERE sync_status = ?',
      ['pending'],
    );
    return result.first['count'] as int? ?? 0;
  }

  /// Marquer une naissance comme synchronisée
  Future<void> markAsSynced(String localId, String serverId) async {
    if (_database == null) return;
    final db = _database!;
    final now = DateTime.now().toIso8601String();

    await db.update(
      _birthsTable,
      {
        'sync_status': 'synced',
        'status': 'completed',
        'updated_at': now,
      },
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  /// Fermer la base de données
  Future<void> close() async {
    _connectivityController.close();
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}