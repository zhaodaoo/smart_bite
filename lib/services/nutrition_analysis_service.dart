import 'package:flutter/foundation.dart';
import 'package:smart_bite/data/comments.dart';
import 'package:smart_bite/data/constant.dart';
import 'package:smart_bite/data/dailyneeds_for_sixteen_above.dart';
import 'package:smart_bite/data/dailyneeds_for_under_fifteen.dart';
import 'package:smart_bite/data/optimized_indexes.dart';

/// Service responsible for analyzing nutritional data and generating health comments.
/// Separated from UI/state management for better testability and maintainability.
class NutritionAnalysisService {
  /// Analyzes nutrition data and returns analysis results.
  ///
  /// Throws [NutritionAnalysisException] if analysis fails due to missing data.
  static Future<NutritionAnalysisResult> analyzeNutrition({
    required List<String> orderNames,
    required Meal meal,
    required Sex sex,
    required Age age,
    required ActivityLevel activityLevel,
  }) async {
    try {
      // Log empty order scenario for analytics (acceptable behavior)
      if (orderNames.isEmpty) {
        debugPrint(
            '⚠️  Analysis requested with zero meals - proceeding with nutritional needs calculation only');
      }

      // Intake meal labels and foods
      final labelInfo = _extractLabelInformation(orderNames);

      // Intake meal nutrition
      final intakeTotalNutrition = _calculateTotalNutrition(orderNames);
      debugPrint('intakeTotalNutrition = $intakeTotalNutrition');

      // Calculate nutrition based on age group
      final NutritionCalculation calculation;
      if ([Age.zeroToNine, Age.tenToTwelve, Age.thirteenToFifteen]
          .contains(age)) {
        calculation = _calculateForUnderFifteen(
          sex: sex,
          age: age,
          activityLevel: activityLevel,
          intakeTotalNutrition: intakeTotalNutrition,
          meal: meal,
        );
      } else {
        calculation = _calculateForAboveSixteen(
          sex: sex,
          age: age,
          activityLevel: activityLevel,
          intakeTotalNutrition: intakeTotalNutrition,
          meal: meal,
        );
      }

      debugPrint('neededCaloriePerDay = ${calculation.neededCaloriePerDay}');
      debugPrint(
          'neededCalorieThisMeal = ${calculation.neededCalorieThisMeal}');
      debugPrint(
          'intakeFoodTypeDailyProportion = ${calculation.intakeFoodTypeDailyProportion}');
      debugPrint('intakeFoodType = ${calculation.intakeFoodType}');
      debugPrint(
          'intakeTotalNutritionWithoutFoodType = ${calculation.intakeTotalNutritionWithoutFoodType}');

      // Generate comments
      final overallComment =
          _getOverallComment(calculation.intakeFoodTypeDailyProportion);
      final commentsByFoodType =
          _getCommentByFoodType(calculation.intakeFoodTypeDailyProportion);
      final ranksByFoodType =
          _getRanksLabelByFoodType(calculation.intakeFoodTypeDailyProportion);

      debugPrint('overallComment = $overallComment');
      debugPrint('commentsByFoodType = $commentsByFoodType');

      return NutritionAnalysisResult(
        neededCaloriePerDay: calculation.neededCaloriePerDay,
        neededCalorieThisMeal: calculation.neededCalorieThisMeal,
        intakeFoodTypeDailyProportion:
            calculation.intakeFoodTypeDailyProportion,
        intakeFoodType: calculation.intakeFoodType,
        intakeTotalNutritionWithoutFoodType:
            calculation.intakeTotalNutritionWithoutFoodType,
        overallComment: overallComment,
        commentsByFoodType: commentsByFoodType,
        ranksByFoodType: ranksByFoodType,
        labelInfo: labelInfo,
      );
    } catch (e) {
      debugPrint('Error in nutrition analysis: $e');
      throw NutritionAnalysisException(
          'Failed to analyze nutrition: ${e.toString()}');
    }
  }

  /// Extracts label information from ordered meals.
  /// Optimized to use indexed lookup structures for faster access.
  static LabelInformation _extractLabelInformation(List<String> orderNames) {
    String productResumeLabelDishes = '';
    String productResumeLabelFood = '甘藷（地瓜）';
    bool productResumeLabelDishesIsDefault = true;
    String casLabelDishes = '';
    String casLabelFood = '雞蛋';
    bool casLabelDishesIsDefault = true;
    String organicLabelDishes = '';
    String organicLabelFood = '菠菜';
    bool organicLabelDishesIsDefault = true;
    String traceableLabelDishes = '';
    String traceableLabelFood = '櫛瓜';
    bool traceableLabelDishesIsDefault = true;

    for (var name in orderNames) {
      // Use optimized index for faster lookup
      Map<Label, String>? dishLabelInfo = OptimizedDishesLabel.get(name);
      if (dishLabelInfo == null) continue;

      if (productResumeLabelDishesIsDefault &&
          dishLabelInfo[Label.type] == '產銷履歷農產品') {
        productResumeLabelDishesIsDefault = false;
        productResumeLabelDishes = name;
        productResumeLabelFood = dishLabelInfo[Label.food] ?? '';
      } else if (casLabelDishesIsDefault &&
          dishLabelInfo[Label.type] == '台灣優良農產品') {
        casLabelDishesIsDefault = false;
        casLabelDishes = name;
        casLabelFood = dishLabelInfo[Label.food] ?? '';
      } else if (organicLabelDishesIsDefault &&
          dishLabelInfo[Label.type] == '有機農產品') {
        organicLabelDishesIsDefault = false;
        organicLabelDishes = name;
        organicLabelFood = dishLabelInfo[Label.food] ?? '';
      } else if (traceableLabelDishesIsDefault &&
          dishLabelInfo[Label.type] == '溯源農糧產品') {
        traceableLabelDishesIsDefault = false;
        traceableLabelDishes = name;
        traceableLabelFood = dishLabelInfo[Label.food] ?? '';
      }

      if (!(productResumeLabelDishesIsDefault ||
          casLabelDishesIsDefault ||
          organicLabelDishesIsDefault ||
          traceableLabelDishesIsDefault)) {
        break;
      }
    }

    return LabelInformation(
      productResumeLabelDishes: productResumeLabelDishes,
      productResumeLabelFood: productResumeLabelFood,
      productResumeLabelDishesIsDefault: productResumeLabelDishesIsDefault,
      casLabelDishes: casLabelDishes,
      casLabelFood: casLabelFood,
      casLabelDishesIsDefault: casLabelDishesIsDefault,
      organicLabelDishes: organicLabelDishes,
      organicLabelFood: organicLabelFood,
      organicLabelDishesIsDefault: organicLabelDishesIsDefault,
      traceableLabelDishes: traceableLabelDishes,
      traceableLabelFood: traceableLabelFood,
      traceableLabelDishesIsDefault: traceableLabelDishesIsDefault,
    );
  }

  /// Calculates total nutrition from ordered meals.
  /// Optimized to use pre-indexed DishNutrition objects for faster access.
  /// Returns zero values for all nutrients if orderNames is empty (valid scenario).
  static Map<NutritionType, double> _calculateTotalNutrition(
      List<String> orderNames) {
    // Handle empty orders - return zero nutrition (user didn't order)
    if (orderNames.isEmpty) {
      return Map.fromEntries(
          NutritionType.values.map((type) => MapEntry(type, 0.0)));
    }

    // Use optimized index for O(1) lookup instead of sequential map access
    List<DishNutrition?> eachMealNutrition =
        orderNames.map((name) => OptimizedDishesInfo.get(name)).toList();

    Map<NutritionType, double> intakeTotalNutrition = {};
    intakeTotalNutrition.addEntries(NutritionType.values.map((key) => MapEntry(
        key,
        eachMealNutrition
            .where((meal) => meal != null)
            .map((meal) => meal!.getValue(key))
            .fold(0.0, (previousValue, element) => previousValue + element))));

    return intakeTotalNutrition;
  }

  /// Calculates nutrition for children under 15 years old.
  static NutritionCalculation _calculateForUnderFifteen({
    required Sex sex,
    required Age age,
    required ActivityLevel activityLevel,
    required Map<NutritionType, double> intakeTotalNutrition,
    required Meal meal,
  }) {
    final sexData = dailyNeedsForUnderFifteen[sex];
    final ageData = sexData?[age];
    final activityData = ageData?[activityLevel];

    if (activityData == null) {
      throw NutritionAnalysisException(
          'No data found for sex: $sex, age: $age, activity: $activityLevel');
    }

    Map<NutritionType, double> todayNeeds = activityData;
    debugPrint('todayNeeds = $todayNeeds');

    final neededCaloriePerDay =
        (todayNeeds[NutritionType.calorie] ?? 0).round();
    final neededCalorieThisMeal =
        (neededCaloriePerDay * (mealProportion[meal] ?? 0)).round();

    final intakeFoodTypeDailyProportion = <NutritionType, double>{};
    for (var key in [
      NutritionType.grains,
      NutritionType.meat,
      NutritionType.vegetables,
      NutritionType.fruits,
      NutritionType.oils,
      NutritionType.dairy
    ]) {
      final intake = intakeTotalNutrition[key] ?? 0;
      final need = todayNeeds[key] ?? 1; // Avoid division by zero
      intakeFoodTypeDailyProportion[key] = intake / need * 100;
    }

    final intakeFoodType = <NutritionType, double>{};
    for (var key in [
      NutritionType.grains,
      NutritionType.meat,
      NutritionType.vegetables,
      NutritionType.fruits,
      NutritionType.oils,
      NutritionType.dairy
    ]) {
      intakeFoodType[key] = intakeTotalNutrition[key] ?? 0;
    }

    final intakeTotalNutritionWithoutFoodType = <NutritionType, double>{};
    for (var key in [
      NutritionType.calorie,
      NutritionType.carb,
      NutritionType.protein,
      NutritionType.fat,
      NutritionType.na,
      NutritionType.ca,
      NutritionType.fiber
    ]) {
      intakeTotalNutritionWithoutFoodType[key] = intakeTotalNutrition[key] ?? 0;
    }

    return NutritionCalculation(
      neededCaloriePerDay: neededCaloriePerDay,
      neededCalorieThisMeal: neededCalorieThisMeal,
      intakeFoodTypeDailyProportion: intakeFoodTypeDailyProportion,
      intakeFoodType: intakeFoodType,
      intakeTotalNutritionWithoutFoodType: intakeTotalNutritionWithoutFoodType,
    );
  }

  /// Calculates nutrition for people 16 years and older.
  static NutritionCalculation _calculateForAboveSixteen({
    required Sex sex,
    required Age age,
    required ActivityLevel activityLevel,
    required Map<NutritionType, double> intakeTotalNutrition,
    required Meal meal,
  }) {
    final sexData = dailyCalorieNeedsForAboveSixteen[sex];
    final ageData = sexData?[age];
    final calorieNeed = ageData?[activityLevel];

    if (calorieNeed == null) {
      throw NutritionAnalysisException(
          'No calorie data found for sex: $sex, age: $age, activity: $activityLevel');
    }

    final neededCaloriePerDay = calorieNeed;
    final neededCalorieThisMeal =
        (neededCaloriePerDay * (mealProportion[meal] ?? 0)).round();

    final foodTypeData = dailyFoodTypeNeedsForAboveSixteen[
        (neededCaloriePerDay / 100).floor() * 100];

    if (foodTypeData == null) {
      throw NutritionAnalysisException(
          'No food type data found for calorie level ${(neededCaloriePerDay / 100).floor() * 100}');
    }

    Map<NutritionType, double> todayNeededFoodType = foodTypeData;

    final intakeFoodTypeDailyProportion = <NutritionType, double>{};
    for (var key in [
      NutritionType.grains,
      NutritionType.meat,
      NutritionType.vegetables,
      NutritionType.fruits,
      NutritionType.oils,
      NutritionType.dairy
    ]) {
      final intake = intakeTotalNutrition[key] ?? 0;
      final need = todayNeededFoodType[key] ?? 1; // Avoid division by zero
      intakeFoodTypeDailyProportion[key] = intake / need * 100;
    }

    final intakeFoodType = <NutritionType, double>{};
    for (var key in [
      NutritionType.grains,
      NutritionType.meat,
      NutritionType.vegetables,
      NutritionType.fruits,
      NutritionType.oils,
      NutritionType.dairy
    ]) {
      intakeFoodType[key] = intakeTotalNutrition[key] ?? 0;
    }

    final intakeTotalNutritionWithoutFoodType = <NutritionType, double>{};
    for (var key in [
      NutritionType.calorie,
      NutritionType.carb,
      NutritionType.protein,
      NutritionType.fat,
      NutritionType.na,
      NutritionType.ca,
      NutritionType.fiber
    ]) {
      intakeTotalNutritionWithoutFoodType[key] = intakeTotalNutrition[key] ?? 0;
    }

    return NutritionCalculation(
      neededCaloriePerDay: neededCaloriePerDay,
      neededCalorieThisMeal: neededCalorieThisMeal,
      intakeFoodTypeDailyProportion: intakeFoodTypeDailyProportion,
      intakeFoodType: intakeFoodType,
      intakeTotalNutritionWithoutFoodType: intakeTotalNutritionWithoutFoodType,
    );
  }

  /// Generates overall health comment based on food type proportions.
  static String _getOverallComment(
      Map<NutritionType, double> intakeFoodTypeDailyProportion) {
    if (intakeFoodTypeDailyProportion.values
        .where((value) => value > 100)
        .isNotEmpty) {
      // Any single food type exceeds daily requirement
      return overallCommentsByRank[Rank.tooMuch] ?? '請檢查攝取量';
    } else if (intakeFoodTypeDailyProportion.values
        .where((value) => value < 10)
        .isNotEmpty) {
      // Any food type is less than 10% of daily requirement
      return overallCommentsByRank[Rank.tooLess] ?? '請檢查攝取量';
    } else {
      // All six food types selected, all above 10% and none exceed daily requirement
      return overallCommentsByRank[Rank.good] ?? '攝取均衡';
    }
  }

  /// Generates comments for each food type.
  static Map<NutritionType, String> _getCommentByFoodType(
      Map<NutritionType, double> intakeFoodTypeDailyProportion) {
    return intakeFoodTypeDailyProportion.map((key, _) {
      final proportion = intakeFoodTypeDailyProportion[key] ?? 0;
      if (proportion > 100) {
        final comment = commentsForFoodTypeByRank[key]?[Rank.tooMuch];
        return MapEntry(key, comment ?? '攝取過量');
      } else if (proportion < 10) {
        final comment = commentsForFoodTypeByRank[key]?[Rank.tooLess];
        return MapEntry(key, comment ?? '攝取不足');
      } else {
        final comment = commentsForFoodTypeByRank[key]?[Rank.good];
        return MapEntry(key, comment ?? '攝取適量');
      }
    });
  }

  /// Generates rank labels for each food type.
  static Map<NutritionType, String> _getRanksLabelByFoodType(
      Map<NutritionType, double> intakeFoodTypeDailyProportion) {
    return intakeFoodTypeDailyProportion.map((key, _) {
      final proportion = intakeFoodTypeDailyProportion[key] ?? 0;
      if (proportion > 100) {
        return MapEntry(key, getRankLabel(Rank.tooMuch));
      } else if (proportion < 10) {
        return MapEntry(key, getRankLabel(Rank.tooLess));
      } else {
        return MapEntry(key, getRankLabel(Rank.good));
      }
    });
  }
}

/// Result of nutrition analysis containing all calculated values.
class NutritionAnalysisResult {
  final int neededCaloriePerDay;
  final int neededCalorieThisMeal;
  final Map<NutritionType, double> intakeFoodTypeDailyProportion;
  final Map<NutritionType, double> intakeFoodType;
  final Map<NutritionType, double> intakeTotalNutritionWithoutFoodType;
  final String overallComment;
  final Map<NutritionType, String> commentsByFoodType;
  final Map<NutritionType, String> ranksByFoodType;
  final LabelInformation labelInfo;

  NutritionAnalysisResult({
    required this.neededCaloriePerDay,
    required this.neededCalorieThisMeal,
    required this.intakeFoodTypeDailyProportion,
    required this.intakeFoodType,
    required this.intakeTotalNutritionWithoutFoodType,
    required this.overallComment,
    required this.commentsByFoodType,
    required this.ranksByFoodType,
    required this.labelInfo,
  });
}

/// Internal calculation result for nutrition data.
class NutritionCalculation {
  final int neededCaloriePerDay;
  final int neededCalorieThisMeal;
  final Map<NutritionType, double> intakeFoodTypeDailyProportion;
  final Map<NutritionType, double> intakeFoodType;
  final Map<NutritionType, double> intakeTotalNutritionWithoutFoodType;

  NutritionCalculation({
    required this.neededCaloriePerDay,
    required this.neededCalorieThisMeal,
    required this.intakeFoodTypeDailyProportion,
    required this.intakeFoodType,
    required this.intakeTotalNutritionWithoutFoodType,
  });
}

/// Label information extracted from ordered meals.
class LabelInformation {
  final String productResumeLabelDishes;
  final String productResumeLabelFood;
  final bool productResumeLabelDishesIsDefault;
  final String casLabelDishes;
  final String casLabelFood;
  final bool casLabelDishesIsDefault;
  final String organicLabelDishes;
  final String organicLabelFood;
  final bool organicLabelDishesIsDefault;
  final String traceableLabelDishes;
  final String traceableLabelFood;
  final bool traceableLabelDishesIsDefault;

  LabelInformation({
    required this.productResumeLabelDishes,
    required this.productResumeLabelFood,
    required this.productResumeLabelDishesIsDefault,
    required this.casLabelDishes,
    required this.casLabelFood,
    required this.casLabelDishesIsDefault,
    required this.organicLabelDishes,
    required this.organicLabelFood,
    required this.organicLabelDishesIsDefault,
    required this.traceableLabelDishes,
    required this.traceableLabelFood,
    required this.traceableLabelDishesIsDefault,
  });
}

/// Exception thrown when nutrition analysis fails.
class NutritionAnalysisException implements Exception {
  final String message;

  NutritionAnalysisException(this.message);

  @override
  String toString() => 'NutritionAnalysisException: $message';
}
