import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smart_bite/data/constant.dart';

/// Service responsible for persisting analysis data to files.
/// Separated from UI/state management for better testability and maintainability.
class DataPersistenceService {
  /// Saves nutrition analysis data to a CSV file.
  ///
  /// Throws [DataPersistenceException] if file operations fail.
  static Future<void> saveAnalysisData({
    required Age age,
    required Sex sex,
    required ActivityLevel activityLevel,
    required List<String> orderNames,
    required String overallComment,
    required Map<NutritionType, double> intakeFoodType,
    required Map<NutritionType, double> intakeFoodTypeDailyProportion,
    required Map<NutritionType, String> ranksByFoodType,
  }) async {
    File? file;
    try {
      file = await _getLocalFile();
      var dateUtc = DateTime.now().toUtc();
      var dateLocal = dateUtc.toLocal();
      
      // Handle empty orderNames (acceptable scenario - user didn't order)
      final orderNamesStr = orderNames.isEmpty ? '未點餐' : orderNames.join(',');
      if (orderNames.isEmpty) {
        debugPrint('📋 Saving analysis record with zero meals (user did not order)');
      }
      
      String outputString =
          '$dateLocal, ${getAgeLabel(age)}, ${getSexLabel(sex)}, ${getActivityLevelLabel(activityLevel)}, $orderNamesStr, "$overallComment", "$intakeFoodType", "$intakeFoodTypeDailyProportion", "$ranksByFoodType"\r\n';
      debugPrint('outputString = $outputString');

      if (await file.exists()) {
        await file.writeAsString(outputString, mode: FileMode.append);
      } else {
        await file.writeAsString(outputString);
      }
      await file.writeAsString(Platform.lineTerminator, mode: FileMode.append);

      debugPrint('✓ Data saved successfully to ${file.path}');
    } catch (e) {
      debugPrint('❌ Error saving data: $e');
      // Ensure proper error propagation with context
      throw DataPersistenceException('Failed to save analysis data to ${file?.path ?? "unknown path"}: ${e.toString()}');
    }
    // Note: Dart automatically closes file handles, but we maintain reference for error reporting
  }

  /// Gets the local path for application documents.
  static Future<String> _getLocalPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  /// Gets the local file for saving data.
  static Future<File> _getLocalFile() async {
    final path = await _getLocalPath();
    debugPrint('Data will be saved under "$path"');
    return File('$path/data.csv');
  }

  /// Reads all saved data from the CSV file.
  ///
  /// Returns an empty list if file doesn't exist.
  /// Throws [DataPersistenceException] if reading fails.
  static Future<List<String>> readAllData() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        return await file.readAsLines();
      }
      return [];
    } catch (e) {
      debugPrint('Error reading data: $e');
      throw DataPersistenceException('Failed to read data: ${e.toString()}');
    }
  }

  /// Deletes the data file.
  ///
  /// Throws [DataPersistenceException] if deletion fails.
  static Future<void> deleteData() async {
    try {
      final file = await _getLocalFile();
      if (await file.exists()) {
        await file.delete();
        debugPrint('Data file deleted successfully');
      }
    } catch (e) {
      debugPrint('Error deleting data: $e');
      throw DataPersistenceException('Failed to delete data: ${e.toString()}');
    }
  }

  /// Saves the includeLabelPage preference.
  ///
  /// Throws [DataPersistenceException] if save fails.
  static Future<void> saveIncludeLabelPage(bool value) async {
    try {
      final file = await _getPreferencesFile();
      await file.writeAsString(value ? '1' : '0');
      debugPrint('✓ includeLabelPage preference saved: $value');
    } catch (e) {
      debugPrint('❌ Error saving includeLabelPage preference: $e');
      throw DataPersistenceException('Failed to save includeLabelPage preference: ${e.toString()}');
    }
  }

  /// Loads the includeLabelPage preference.
  ///
  /// Returns false (default) if file doesn't exist or contains invalid data.
  static Future<bool> loadIncludeLabelPage() async {
    try {
      final file = await _getPreferencesFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final value = content.trim() == '1';
        debugPrint('✓ includeLabelPage preference loaded: $value');
        return value;
      }
      debugPrint('ℹ includeLabelPage preference file not found, using default: false');
      return false; // Default: only print report
    } catch (e) {
      debugPrint('❌ Error loading includeLabelPage preference: $e, using default: false');
      return false; // Default on error
    }
  }

  /// Gets the preferences file for storing settings.
  static Future<File> _getPreferencesFile() async {
    final path = await _getLocalPath();
    return File('$path/preferences.txt');
  }
}

/// Exception thrown when data persistence operations fail.
class DataPersistenceException implements Exception {
  final String message;

  DataPersistenceException(this.message);

  @override
  String toString() => 'DataPersistenceException: $message';
}
