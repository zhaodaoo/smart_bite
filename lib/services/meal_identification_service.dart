/// Meal Identification Service
/// 
/// Extracts the business logic of converting RFID card UIDs to meal names
/// from the UI layer. This service acts as a bridge between the hardware
/// abstraction layer (RFID readers) and the domain layer (meal data).
library;

import '../data/id_to_meal.dart';
import '../interfaces/rfid_reader.dart';

/// Service for identifying meals from RFID card readings
class MealIdentificationService {
  /// Default meal name for unknown/unrecognized RFID cards
  static const String unknownMealName = '未知料理';

  /// Convert an RFID card UID to a meal name
  /// 
  /// Returns the meal name if found in the database, otherwise returns [unknownMealName]
  String identifyMeal(String rfidUid) {
    if (rfidUid.isEmpty) {
      return '';
    }
    return idToMealName[rfidUid] ?? unknownMealName;
  }

  /// Convert a list of RFID readings to meal names
  /// 
  /// Only processes readings with valid cards (hasCard == true)
  /// Returns a list of meal names in the same order as the readings
  List<String> identifyMealsFromReadings(List<RFIDReading> readings) {
    return readings
        .where((reading) => reading.hasCard)
        .map((reading) => identifyMeal(reading.rfid))
        .toList();
  }

  /// Get meal identification statistics
  /// 
  /// Returns a map with:
  /// - 'total': Total number of readings
  /// - 'valid': Number of readings with cards
  /// - 'identified': Number of successfully identified meals
  /// - 'unknown': Number of unknown/unrecognized cards
  Map<String, int> getIdentificationStats(List<RFIDReading> readings) {
    final validReadings = readings.where((r) => r.hasCard).toList();
    final identifiedMeals = identifyMealsFromReadings(readings);
    final unknownCount = identifiedMeals.where((name) => name == unknownMealName).length;

    return {
      'total': readings.length,
      'valid': validReadings.length,
      'identified': validReadings.length - unknownCount,
      'unknown': unknownCount,
    };
  }

  /// Check if an RFID UID is registered in the meal database
  bool isRfidRegistered(String rfidUid) {
    return idToMealName.containsKey(rfidUid);
  }

  /// Get all registered RFID UIDs for a specific meal name
  /// 
  /// Useful for finding duplicate/backup cards for the same meal
  List<String> getRfidsForMeal(String mealName) {
    return idToMealName.entries
        .where((entry) => entry.value == mealName)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get total number of registered meals in the database
  int get totalRegisteredMeals => idToMealName.length;

  /// Get list of all unique meal names
  Set<String> get uniqueMealNames => idToMealName.values.toSet();
}
