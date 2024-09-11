import 'package:flutter/material.dart';
import 'package:smart_bite/data/comments.dart';
import 'package:smart_bite/data/constant.dart';
import 'package:smart_bite/data/dishes_info.dart';
import 'package:smart_bite/data/under_fifteen_dailyneeds.dart';


class DataProvider extends ChangeNotifier {
  Meal _meal = Meal.lunch;
  ActivityLevel _activityLevel = ActivityLevel.miderate;
  Sex _sex = Sex.female;
  Age _age = Age.zeroToNine;
  
  List<String> orderNames = [];

  // Needed analyze results
  int _neededCalariePerDay = 0;
  int _neededCalarieThisMeal = 0;
  Map<NutritionType, double> _intakeFoodTypeDailyProportion = {
    NutritionType.grains: 0,
    NutritionType.meat: 0,
    NutritionType.vegetables: 0,
    NutritionType.fruits: 0,
    NutritionType.oils: 0,
    NutritionType.dairy: 0,
  };
  Map<NutritionType, double> _intakeTotalNutritionWithoutFoddType = {
    NutritionType.calorie: 0,
    NutritionType.carb: 0,
    NutritionType.protein: 0,
    NutritionType.fat: 0,
    NutritionType.na: 0,
    NutritionType.ca: 0,
    NutritionType.fiber: 0,
  };

  // Needed comments
  String _overallComment = '';
  Map<NutritionType, String> _commentsByFoodType = {
    NutritionType.grains: '',
    NutritionType.meat: '',
    NutritionType.vegetables: '',
    NutritionType.fruits: '',
    NutritionType.oils: '',
    NutritionType.dairy: '',
  };

  Meal get meal => _meal;
  ActivityLevel get activityLevel => _activityLevel;
  Sex get sex => _sex;
  Age get age => _age;
  int get neededCalariePerDay => _neededCalariePerDay;
  int get neededCalarieThisMeal => _neededCalarieThisMeal;
  Map<NutritionType, double> get intakeFoodTypeDailyProportion => _intakeFoodTypeDailyProportion;
  Map<NutritionType, double> get intakeTotalNutritionWithoutFoddType => _intakeTotalNutritionWithoutFoddType;
  String get overallComment => _overallComment ;
  Map<NutritionType, String> get commentsByFoodType => _commentsByFoodType;

  set meal (Meal value){
    _meal = value;
    notifyListeners();
  }
  
  set activityLevel (ActivityLevel value){
    _activityLevel = value;
    notifyListeners();
  }

  set sex (Sex value){
    _sex = value;
    notifyListeners();
  }

  set age (Age value){
    _age = value;
    notifyListeners();
  }

  String getOverallComment() {
     if (_intakeFoodTypeDailyProportion.values.where((value) => value > 100).isNotEmpty) {
      //單一食物超過當天所需的份量
      return overallCommentsByRank[Rank.tooMuch]!;
    } else if (_intakeFoodTypeDailyProportion.values.where((value) => value < 10).isNotEmpty) {
      //任一食物選擇少於當天所需的10％以內
      return overallCommentsByRank[Rank.tooLess]!; 
    } else {
      // 六大類食物都有選，且都大於當天所需的10％以上，並且沒有超過單一天的份量
      return overallCommentsByRank[Rank.good]!;
    }
  } 

  Map<NutritionType, String> getCommentByFoodType() {
    return _commentsByFoodType.map((key, value) {
      if (_intakeFoodTypeDailyProportion[key]! > 100) {
        // ignore: collection_methods_unrelated_type
        return MapEntry(key, commentsForFoodTypeByRank[key]![Rank.tooMuch]!);
      } else if (_intakeFoodTypeDailyProportion[key]! > 100) {
        // ignore: collection_methods_unrelated_type
        return MapEntry(key, commentsForFoodTypeByRank[key]![Rank.tooLess]!);
      } else {
        // ignore: collection_methods_unrelated_type
        return MapEntry(key, commentsForFoodTypeByRank[key]![Rank.good]!);
      }

    });
  }
  
  void analyze() {

    // Needed nutririons
    Map<NutritionType, double> todayNeeds = underFifteenFood[_sex]![_age]![_activityLevel]!;
    Map<NutritionType, double> thisMealNeeds = todayNeeds.map((key, value) => MapEntry(key, value*mealProportion[_meal]!));
    debugPrint('todayNeeds = $todayNeeds');
    debugPrint('thisMealNeeds = $thisMealNeeds');

    // Intake meal nutririon
    List<Map<NutritionType, double>?> eachMealNutrition =  orderNames.map((name) => dishesInfo[name]).toList();
    Map<NutritionType, double> intakeTotalNutrition = {};
    intakeTotalNutrition.addEntries(NutritionType.values.map((key) => MapEntry(key, eachMealNutrition.map((meal) => meal![key]).fold(0.0, (previousValue, element) => previousValue + element!))));
    debugPrint('intakeTotalNutrition = $intakeTotalNutrition');


    // Needed Result
    _neededCalariePerDay = todayNeeds[NutritionType.calorie]!.round();
    _neededCalarieThisMeal = thisMealNeeds[NutritionType.calorie]!.round();
    _intakeFoodTypeDailyProportion = intakeFoodTypeDailyProportion.map((key, _) => MapEntry(key, intakeTotalNutrition[key]!/todayNeeds[key]!*100));
    _intakeTotalNutritionWithoutFoddType = intakeTotalNutritionWithoutFoddType.map((key, _) => MapEntry(key, intakeTotalNutrition[key]!));
    debugPrint('neededCalariePerDay = $_neededCalariePerDay');
    debugPrint('neededCalarieThisMeal = $_neededCalarieThisMeal');
    debugPrint('intakeFoodTypeDailyProportion = $_intakeFoodTypeDailyProportion');
    debugPrint('intakeTotalNutritionWithoutFoddType = $_intakeTotalNutritionWithoutFoddType');

    // Needed comments
    _overallComment = getOverallComment();
    _commentsByFoodType = getCommentByFoodType();
    debugPrint('overallComment = $_overallComment');
    debugPrint('commentsByFoodType = $_commentsByFoodType');
  }



}