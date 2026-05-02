import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/birth_record.dart';

class BirthStorageService {
  static const String _birthRecordsKey = 'birth_records';
  
  // Singleton pattern
  static final BirthStorageService _instance = BirthStorageService._internal();
  factory BirthStorageService() => _instance;
  BirthStorageService._internal();

  // Get all birth records
  Future<List<BirthRecord>> getAllBirthRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList(_birthRecordsKey) ?? [];
      
      return recordsJson
          .map((json) => BirthRecord.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error loading birth records: $e');
      return [];
    }
  }

  // Save a birth record
  Future<bool> saveBirthRecord(BirthRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getAllBirthRecords();
      
      // Add new record
      records.add(record);
      
      // Convert to JSON and save
      final recordsJson = records.map((r) => jsonEncode(r.toJson())).toList();
      return await prefs.setStringList(_birthRecordsKey, recordsJson);
    } catch (e) {
      print('Error saving birth record: $e');
      return false;
    }
  }

  // Update a birth record
  Future<bool> updateBirthRecord(BirthRecord record) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getAllBirthRecords();
      
      // Find and update the record
      final index = records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        records[index] = record;
        
        final recordsJson = records.map((r) => jsonEncode(r.toJson())).toList();
        return await prefs.setStringList(_birthRecordsKey, recordsJson);
      }
      return false;
    } catch (e) {
      print('Error updating birth record: $e');
      return false;
    }
  }

  // Delete a birth record
  Future<bool> deleteBirthRecord(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final records = await getAllBirthRecords();
      
      // Remove the record
      records.removeWhere((r) => r.id == id);
      
      final recordsJson = records.map((r) => jsonEncode(r.toJson())).toList();
      return await prefs.setStringList(_birthRecordsKey, recordsJson);
    } catch (e) {
      print('Error deleting birth record: $e');
      return false;
    }
  }

  // Get birth record by ID
  Future<BirthRecord?> getBirthRecordById(String id) async {
    try {
      final records = await getAllBirthRecords();
      return records.firstWhere((r) => r.id == id);
    } catch (e) {
      print('Error finding birth record: $e');
      return null;
    }
  }

  // Search birth records
  Future<List<BirthRecord>> searchBirthRecords(String query) async {
    try {
      final records = await getAllBirthRecords();
      final lowerQuery = query.toLowerCase();
      
      return records.where((record) {
        return record.babyFullName.toLowerCase().contains(lowerQuery) ||
               record.birthPlace.toLowerCase().contains(lowerQuery) ||
               record.fatherName.toLowerCase().contains(lowerQuery) ||
               record.motherName.toLowerCase().contains(lowerQuery) ||
               record.blockchainId.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      print('Error searching birth records: $e');
      return [];
    }
  }

  // Get records count
  Future<int> getRecordsCount() async {
    try {
      final records = await getAllBirthRecords();
      return records.length;
    } catch (e) {
      print('Error getting records count: $e');
      return 0;
    }
  }

  // Get records from current month
  Future<List<BirthRecord>> getCurrentMonthRecords() async {
    try {
      final records = await getAllBirthRecords();
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      
      return records.where((record) {
        return record.registrationDate.isAfter(currentMonth) && 
               record.registrationDate.isBefore(nextMonth);
      }).toList();
    } catch (e) {
      print('Error getting current month records: $e');
      return [];
    }
  }

  // Clear all records (for testing purposes)
  Future<bool> clearAllRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_birthRecordsKey);
    } catch (e) {
      print('Error clearing records: $e');
      return false;
    }
  }

  // Initialize with sample data (for testing)
  Future<void> initializeSampleData() async {
    try {
      final existingRecords = await getAllBirthRecords();
      if (existingRecords.isEmpty) {
        final sampleRecords = [
          BirthRecord(
            id: '1',
            babyFirstName: 'Mamadou',
            babyLastName: 'Diallo',
            birthDate: '12/04/2026',
            birthPlace: 'Conakry',
            fatherName: 'Ibrahim Diallo',
            fatherAge: '35',
            motherName: 'Aminata Bah',
            motherAge: '28',
            blockchainId: 'BC-1714567890123-123456',
            registrationDate: DateTime.now().subtract(const Duration(days: 5)),
            qrCodeData: 'sample_qr_data_1',
          ),
          BirthRecord(
            id: '2',
            babyFirstName: 'Aissatou',
            babyLastName: 'Bah',
            birthDate: '10/04/2026',
            birthPlace: 'Labé',
            fatherName: 'Oumar Bah',
            fatherAge: '42',
            motherName: 'Fatoumata Diallo',
            motherAge: '31',
            blockchainId: 'BC-1714389012345-789012',
            registrationDate: DateTime.now().subtract(const Duration(days: 7)),
            qrCodeData: 'sample_qr_data_2',
          ),
        ];
        
        for (final record in sampleRecords) {
          await saveBirthRecord(record);
        }
      }
    } catch (e) {
      print('Error initializing sample data: $e');
    }
  }
}
