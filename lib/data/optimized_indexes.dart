/// Optimized Static Data Indexes
///
/// Pre-computed data structures for fast lookup and reduced memory overhead.
/// Initialized at app startup to convert raw data maps into indexed structures.
library;

import 'package:smart_bite/data/constant.dart';
import 'package:smart_bite/data/dishes_info.dart';
import 'package:smart_bite/data/dishes_label.dart';

/// Debug flag to disable caching for testing
/// Set via environment variable: DISABLE_CACHE=true
bool get cacheDisabled =>
    const bool.fromEnvironment('DISABLE_CACHE', defaultValue: false);

/// Type-safe nutrition data structure
class DishNutrition {
  final String name;
  final double grains;
  final double meat;
  final double vegetables;
  final double fruits;
  final double dairy;
  final double oils;
  final double calorie;
  final double carb;
  final double protein;
  final double fat;
  final double na;
  final double ca;
  final double fiber;

  const DishNutrition({
    required this.name,
    required this.grains,
    required this.meat,
    required this.vegetables,
    required this.fruits,
    required this.dairy,
    required this.oils,
    required this.calorie,
    required this.carb,
    required this.protein,
    required this.fat,
    required this.na,
    required this.ca,
    required this.fiber,
  });

  /// Create from raw map data
  factory DishNutrition.fromMap(String name, Map<NutritionType, double> data) {
    return DishNutrition(
      name: name,
      grains: data[NutritionType.grains] ?? 0.0,
      meat: data[NutritionType.meat] ?? 0.0,
      vegetables: data[NutritionType.vegetables] ?? 0.0,
      fruits: data[NutritionType.fruits] ?? 0.0,
      dairy: data[NutritionType.dairy] ?? 0.0,
      oils: data[NutritionType.oils] ?? 0.0,
      calorie: data[NutritionType.calorie] ?? 0.0,
      carb: data[NutritionType.carb] ?? 0.0,
      protein: data[NutritionType.protein] ?? 0.0,
      fat: data[NutritionType.fat] ?? 0.0,
      na: data[NutritionType.na] ?? 0.0,
      ca: data[NutritionType.ca] ?? 0.0,
      fiber: data[NutritionType.fiber] ?? 0.0,
    );
  }

  /// Convert to raw map format (for backward compatibility)
  Map<NutritionType, double> toMap() {
    return {
      NutritionType.grains: grains,
      NutritionType.meat: meat,
      NutritionType.vegetables: vegetables,
      NutritionType.fruits: fruits,
      NutritionType.dairy: dairy,
      NutritionType.oils: oils,
      NutritionType.calorie: calorie,
      NutritionType.carb: carb,
      NutritionType.protein: protein,
      NutritionType.fat: fat,
      NutritionType.na: na,
      NutritionType.ca: ca,
      NutritionType.fiber: fiber,
    };
  }

  /// Get specific nutrition value by type
  double getValue(NutritionType type) {
    return switch (type) {
      NutritionType.grains => grains,
      NutritionType.meat => meat,
      NutritionType.vegetables => vegetables,
      NutritionType.fruits => fruits,
      NutritionType.dairy => dairy,
      NutritionType.oils => oils,
      NutritionType.calorie => calorie,
      NutritionType.carb => carb,
      NutritionType.protein => protein,
      NutritionType.fat => fat,
      NutritionType.na => na,
      NutritionType.ca => ca,
      NutritionType.fiber => fiber,
    };
  }
}

/// Optimized dish information index
class OptimizedDishesInfo {
  static Map<String, DishNutrition>? _index;
  static List<String>? _dishNames;

  /// Initialize the index from raw data
  static void initialize() {
    if (_index != null) return; // Already initialized

    _index = {};
    for (final entry in dishesInfo.entries) {
      _index![entry.key] = DishNutrition.fromMap(entry.key, entry.value);
    }

    _dishNames = _index!.keys.toList()..sort();
  }

  /// Get nutrition data for a dish (fast indexed lookup)
  static DishNutrition? get(String dishName) {
    return _index?[dishName];
  }

  /// Get raw map format for a dish (for compatibility)
  static Map<NutritionType, double>? getMap(String dishName) {
    return _index?[dishName]?.toMap();
  }

  /// Check if a dish exists
  static bool contains(String dishName) {
    return _index?.containsKey(dishName) ?? false;
  }

  /// Get all dish names (sorted)
  static List<String> get allDishNames => _dishNames ?? [];

  /// Get total number of dishes
  static int get count => _index?.length ?? 0;

  /// Clear the index (for testing)
  static void clear() {
    _index = null;
    _dishNames = null;
  }
}

/// Optimized dish label index
class OptimizedDishesLabel {
  static Map<String, Map<Label, String>>? _index;

  /// Initialize the index from raw data
  static void initialize() {
    if (_index != null) return; // Already initialized
    _index = Map.from(dishesLabel);
  }

  /// Get label info for a dish (fast indexed lookup)
  static Map<Label, String>? get(String dishName) {
    return _index?[dishName];
  }

  /// Get specific label value
  static String? getLabel(String dishName, Label labelType) {
    return _index?[dishName]?[labelType];
  }

  /// Check if a dish has label info
  static bool contains(String dishName) {
    return _index?.containsKey(dishName) ?? false;
  }

  /// Clear the index (for testing)
  static void clear() {
    _index = null;
  }
}

/// Initialize all optimized indexes
/// Call this at app startup before running the app
Future<void> initializeOptimizedIndexes() async {
  OptimizedDishesInfo.initialize();
  OptimizedDishesLabel.initialize();
}
