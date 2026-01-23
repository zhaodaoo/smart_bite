import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:smart_bite/data/constant.dart';

/// Service for loading dishes information from CSV files
class DishesInfoCsvService {
  /// Loads dishes info and labels from a CSV file
  /// 
  /// CSV format expected:
  /// 菜色,全穀雜糧類（碗）,豆魚蛋肉類（份）,蔬菜類（份）,水果類（份）,乳品類（份）,油脂與堅果種子類（份）,熱量（大卡）,碳水化合物（公克）,蛋白質（公克）,脂質（公克）,鈉（毫克）,鈣（毫克）,膳食纖維（公克）,三章一Q呈現,品名
  /// 
  /// Returns a map with two keys:
  /// - 'dishesInfo': Map<String, Map<NutritionType, double>>
  /// - 'dishesLabel': Map<String, Map<Label, String>>
  /// 
  /// Throws [DishesInfoCsvException] if file operations fail.
  static Future<Map<String, dynamic>> loadFromCsv(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw DishesInfoCsvException('CSV file does not exist: $filePath');
      }

      final lines = await file.readAsLines();
      
      if (lines.isEmpty) {
        throw DishesInfoCsvException('CSV file is empty: $filePath');
      }

      // Skip header row
      if (lines.length < 2) {
        throw DishesInfoCsvException('CSV file has no data rows: $filePath');
      }

      final dishesInfo = <String, Map<NutritionType, double>>{};
      final dishesLabel = <String, Map<Label, String>>{};

      // Process data rows (skip first row which is header)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue; // Skip empty lines

        try {
          final fields = _parseCsvLine(line);
          
          if (fields.length < 16) {
            debugPrint('⚠ Skipping row ${i + 1}: insufficient columns (${fields.length} < 16)');
            continue;
          }

          final dishName = fields[0].trim();
          if (dishName.isEmpty) {
            debugPrint('⚠ Skipping row ${i + 1}: empty dish name');
            continue;
          }

          // Parse nutrition values
          final nutritionMap = <NutritionType, double>{
            NutritionType.grains: _parseDouble(fields[1], 0.0),
            NutritionType.meat: _parseDouble(fields[2], 0.0),
            NutritionType.vegetables: _parseDouble(fields[3], 0.0),
            NutritionType.fruits: _parseDouble(fields[4], 0.0),
            NutritionType.dairy: _parseDouble(fields[5], 0.0),
            NutritionType.oils: _parseDouble(fields[6], 0.0),
            NutritionType.calorie: _parseDouble(fields[7], 0.0),
            NutritionType.carb: _parseDouble(fields[8], 0.0),
            NutritionType.protein: _parseDouble(fields[9], 0.0),
            NutritionType.fat: _parseDouble(fields[10], 0.0),
            NutritionType.na: _parseDouble(fields[11], 0.0),
            NutritionType.ca: _parseDouble(fields[12], 0.0),
            NutritionType.fiber: _parseDouble(fields[13], 0.0),
          };

          dishesInfo[dishName] = nutritionMap;

          // Parse label information (columns 14 and 15)
          final labelType = fields[14].trim();
          final labelFood = fields[15].trim();
          
          if (labelType.isNotEmpty || labelFood.isNotEmpty) {
            dishesLabel[dishName] = {
              Label.type: labelType.isEmpty ? '無' : labelType,
              Label.food: labelFood,
            };
          }
        } catch (e) {
          debugPrint('⚠ Error parsing row ${i + 1}: $e');
          // Continue processing other rows
          continue;
        }
      }

      debugPrint('✓ Loaded ${dishesInfo.length} dishes from CSV: $filePath');
      if (dishesLabel.isNotEmpty) {
        debugPrint('✓ Loaded ${dishesLabel.length} labels from CSV');
      }

      return {
        'dishesInfo': dishesInfo,
        'dishesLabel': dishesLabel,
      };
    } catch (e) {
      if (e is DishesInfoCsvException) {
        rethrow;
      }
      throw DishesInfoCsvException('Failed to load CSV file: ${e.toString()}');
    }
  }

  /// Parses a CSV line, handling quoted fields
  static List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    var currentField = StringBuffer();
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          currentField.write('"');
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // Field separator
        fields.add(currentField.toString());
        currentField.clear();
      } else {
        currentField.write(char);
      }
    }

    // Add last field
    fields.add(currentField.toString());

    return fields;
  }

  /// Parses a string to double, returns default value on error
  static double _parseDouble(String value, double defaultValue) {
    if (value.trim().isEmpty) {
      return defaultValue;
    }
    try {
      return double.parse(value.trim());
    } catch (e) {
      debugPrint('⚠ Failed to parse double: "$value", using default: $defaultValue');
      return defaultValue;
    }
  }
}

/// Exception thrown when CSV loading operations fail
class DishesInfoCsvException implements Exception {
  final String message;

  DishesInfoCsvException(this.message);

  @override
  String toString() => 'DishesInfoCsvException: $message';
}
