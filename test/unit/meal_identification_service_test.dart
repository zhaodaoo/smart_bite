import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bite/services/meal_identification_service.dart';
import 'package:smart_bite/interfaces/rfid_reader.dart';

void main() {
  group('MealIdentificationService', () {
    late MealIdentificationService service;

    setUp(() {
      service = MealIdentificationService();
    });

    test('should identify known meal from RFID', () {
      // Test with known RFIDs from id_to_meal.dart
      final meal1 = service.identifyMeal('A22038F6');
      expect(meal1, '八寶良糧粥');

      final meal2 = service.identifyMeal('A22438F6');
      expect(meal2, '三杯鬼頭刀魚');
    });

    test('should return "未知料理" for unknown RFID', () {
      final unknownMeal = service.identifyMeal('UNKNOWN1');
      expect(unknownMeal, '未知料理');
    });

    test('should handle null or empty RFID', () {
      final emptyMeal = service.identifyMeal('');
      expect(emptyMeal, ''); // Empty RFID returns empty string
    });

    test('should identify meals from list of readings', () {
      final readings = [
        RFIDReading.success('01', 'A22038F6'),
        RFIDReading.success('02', 'A22438F6'),
        RFIDReading.init('03'),
        RFIDReading.success('04', 'UNKNOWN1'),
      ];

      final meals = service.identifyMealsFromReadings(readings);

      expect(meals.length, 3); // Only success readings
      expect(meals[0], '八寶良糧粥');
      expect(meals[1], '三杯鬼頭刀魚');
      expect(meals[2], '未知料理'); // Unknown RFID
    });

    test('should generate accurate statistics', () {
      final readings = [
        RFIDReading.success('01', 'A22038F6'),
        RFIDReading.success('02', 'A22438F6'),
        RFIDReading.init('03'),
        RFIDReading.success('04', 'UNKNOWN1'),
        RFIDReading.error('05', 'Error'),
      ];

      final stats = service.getIdentificationStats(readings);

      expect(stats['total'], 5);
      expect(stats['valid'], 3); // 3 success readings
      expect(stats['identified'], 2); // 2 known meals
      expect(stats['unknown'], 1); // 1 unknown RFID
    });

    test('should check if RFID is registered', () {
      expect(service.isRfidRegistered('A22038F6'), true);
      expect(service.isRfidRegistered('UNKNOWN1'), false);
      expect(service.isRfidRegistered(''), false);
    });

    test('should find RFIDs for a given meal', () {
      final rfids = service.getRfidsForMeal('八寶良糧粥');
      
      expect(rfids, isNotEmpty);
      expect(rfids, contains('A22038F6'));
    });

    test('should return empty list for non-existent meal', () {
      final rfids = service.getRfidsForMeal('不存在的料理');
      expect(rfids, isEmpty);
    });

    test('should handle empty readings list', () {
      final meals = service.identifyMealsFromReadings([]);
      expect(meals, isEmpty);

      final stats = service.getIdentificationStats([]);
      expect(stats['total'], 0);
      expect(stats['valid'], 0);
      expect(stats['identified'], 0);
      expect(stats['unknown'], 0);
    });
  });
}
