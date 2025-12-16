import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

import 'package:smart_bite/data/comments.dart';
import 'package:smart_bite/data/constant.dart';
import 'package:smart_bite/data/dailyneeds_for_sixteen_above.dart';
import 'package:smart_bite/data/dishes_info.dart';
import 'package:smart_bite/data/dishes_label.dart';
import 'package:smart_bite/data/dailyneeds_for_under_fifteen.dart';
import 'package:smart_bite/data/three_label_one_code.dart';

class DataProvider extends ChangeNotifier {
  String _printerName = 'DCPT426W';
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
  Map<NutritionType, double> _intakeFoodType = {
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
  Map<NutritionType, String> _ranksByFoodType = {
    NutritionType.grains: '',
    NutritionType.meat: '',
    NutritionType.vegetables: '',
    NutritionType.fruits: '',
    NutritionType.oils: '',
    NutritionType.dairy: '',
  };

  Map<NutritionType, String> _commentsByFoodType = {
    NutritionType.grains: '',
    NutritionType.meat: '',
    NutritionType.vegetables: '',
    NutritionType.fruits: '',
    NutritionType.oils: '',
    NutritionType.dairy: '',
  };

  // Needed 3Label and 1 QR Code
  String _productResumeLabelDishes = '';
  String _productResumeLabelFood = '甘藷（地瓜）';
  bool _productResumeLabelDishesIsDefault = true;
  String _casLabelDishes = '';
  String _casLabelFood = '雞蛋';
  bool _casLabelDishesIsDefault = true;
  String _organicLabelDishes = '';
  String _organicLabelFood = '菠菜';
  bool _organicLabelDishesIsDefault = true;
  String _traceableLabelDishes = '櫛瓜蒸蛋（舉例）';
  String _traceableLabelFood = '櫛瓜';
  bool _traceableLabelDishesIsDefault = true;

  Meal get meal => _meal;
  ActivityLevel get activityLevel => _activityLevel;
  Sex get sex => _sex;
  Age get age => _age;
  int get neededCalariePerDay => _neededCalariePerDay;
  int get neededCalarieThisMeal => _neededCalarieThisMeal;
  Map<NutritionType, double> get intakeFoodTypeDailyProportion =>
      _intakeFoodTypeDailyProportion;
  Map<NutritionType, double> get intakeTotalNutritionWithoutFoddType =>
      _intakeTotalNutritionWithoutFoddType;
  String get overallComment => _overallComment;
  Map<NutritionType, String> get commentsByFoodType => _commentsByFoodType;

  get screenshotController => null;

  String get printerName => _printerName;
  set printerName(String input) {
    _printerName = input;
    notifyListeners();
  }

  set meal(Meal value) {
    _meal = value;
    notifyListeners();
  }

  set activityLevel(ActivityLevel value) {
    _activityLevel = value;
    notifyListeners();
  }

  set sex(Sex value) {
    _sex = value;
    notifyListeners();
  }

  set age(Age value) {
    _age = value;
    notifyListeners();
  }

  String getOverallComment() {
    if (_intakeFoodTypeDailyProportion.values
        .where((value) => value > 100)
        .isNotEmpty) {
      //單一食物超過當天所需的份量
      return overallCommentsByRank[Rank.tooMuch] ?? '請檢查攝取量';
    } else if (_intakeFoodTypeDailyProportion.values
        .where((value) => value < 10)
        .isNotEmpty) {
      //任一食物選擇少於當天所需的10％以內
      return overallCommentsByRank[Rank.tooLess] ?? '請檢查攝取量';
    } else {
      // 六大類食物都有選，且都大於當天所需的10％以上，並且沒有超過單一天的份量
      return overallCommentsByRank[Rank.good] ?? '攝取均衡';
    }
  }

  Map<NutritionType, String> getCommentByFoodType() {
    return _commentsByFoodType.map((key, value) {
      final proportion = _intakeFoodTypeDailyProportion[key] ?? 0;
      if (proportion > 100) {
        final comment = commentsForFoodTypeByRank[key]?[Rank.tooMuch];
        return MapEntry(key, comment ?? '攝取過量');
      } else if (proportion < 100) {
        final comment = commentsForFoodTypeByRank[key]?[Rank.tooLess];
        return MapEntry(key, comment ?? '攝取不足');
      } else {
        final comment = commentsForFoodTypeByRank[key]?[Rank.good];
        return MapEntry(key, comment ?? '攝取適量');
      }
    });
  }

  Map<NutritionType, String> getRanksLabelByFoodType() {
    return _ranksByFoodType.map((key, value) {
      final proportion = _intakeFoodTypeDailyProportion[key] ?? 0;
      if (proportion > 100) {
        return MapEntry(key, getRankLabel(Rank.tooMuch));
      } else if (proportion < 100) {
        return MapEntry(key, getRankLabel(Rank.tooLess));
      } else {
        return MapEntry(key, getRankLabel(Rank.good));
      }
    });
  }

  Future<void> analyze() async {
    // Intake meal labels and foods
    for (var name in orderNames) {
      Map<Label, String>? dishLabelInfo = dishesLabel[name];
      if (dishLabelInfo == null) continue;
      if (_productResumeLabelDishesIsDefault &&
          dishLabelInfo[Label.type] == '產銷履歷農產品') {
        _productResumeLabelDishesIsDefault = false;
        _productResumeLabelDishes = name;
        _productResumeLabelFood = dishLabelInfo[Label.food] ?? '';
      } else if (_casLabelDishesIsDefault &&
          dishLabelInfo[Label.type] == '台灣優良農產品') {
        _casLabelDishesIsDefault = false;
        _casLabelDishes = name;
        _casLabelFood = dishLabelInfo[Label.food] ?? '';
      } else if (_organicLabelDishesIsDefault &&
          dishLabelInfo[Label.type] == '有機農產品') {
        _organicLabelDishesIsDefault = false;
        _organicLabelDishes = name;
        _organicLabelFood = dishLabelInfo[Label.food] ?? '';
      } else if (_traceableLabelDishesIsDefault &&
          dishLabelInfo[Label.type] == '溯源農糧產品') {
        _traceableLabelDishesIsDefault = false;
        _traceableLabelDishes = name;
        _traceableLabelFood = dishLabelInfo[Label.food] ?? '';
      }
      if (!(_productResumeLabelDishesIsDefault ||
          _casLabelDishesIsDefault ||
          _organicLabelDishesIsDefault ||
          _traceableLabelDishesIsDefault)) {
        break;
      }
    }

    // Intake meal nutririon
    List<Map<NutritionType, double>?> eachMealNutrition =
        orderNames.map((name) => dishesInfo[name]).toList();
    Map<NutritionType, double> intakeTotalNutrition = {};
    intakeTotalNutrition.addEntries(NutritionType.values.map((key) => MapEntry(
        key,
        eachMealNutrition
            .where((meal) => meal != null)
            .map((meal) => meal![key] ?? 0.0)
            .fold(0.0, (previousValue, element) => previousValue + element))));
    debugPrint('intakeTotalNutrition = $intakeTotalNutrition');

    if ([Age.zeroToNine, Age.tenToTwelve, Age.thirteenToFifteen]
        .contains(_age)) {
      // Needed nutririons
      final sexData = dailyNeedsForUnderFifteen[_sex];
      final ageData = sexData?[_age];
      final activityData = ageData?[_activityLevel];

      if (activityData == null) {
        debugPrint('Error: No data found for $_sex, $_age, $_activityLevel');
        return;
      }

      Map<NutritionType, double> todayNeeds = activityData;
      debugPrint('todayNeeds = $todayNeeds');

      // Needed Result
      _neededCalariePerDay = (todayNeeds[NutritionType.calorie] ?? 0).round();
      _neededCalarieThisMeal =
          (_neededCalariePerDay * (mealProportion[_meal] ?? 0)).round();
      _intakeFoodTypeDailyProportion =
          _intakeFoodTypeDailyProportion.map((key, _) {
        final intake = intakeTotalNutrition[key] ?? 0;
        final need = todayNeeds[key] ?? 1; // Avoid division by zero
        return MapEntry(key, intake / need * 100);
      });
      _intakeFoodType = _intakeFoodType
          .map((key, _) => MapEntry(key, intakeTotalNutrition[key] ?? 0));
      _intakeTotalNutritionWithoutFoddType =
          _intakeTotalNutritionWithoutFoddType
              .map((key, _) => MapEntry(key, intakeTotalNutrition[key] ?? 0));
    } else {
      final sexData = dailyCalorieNeedsForAboveSixteen[_sex];
      final ageData = sexData?[_age];
      final calorieNeed = ageData?[_activityLevel];

      if (calorieNeed == null) {
        debugPrint(
            'Error: No calorie data found for $_sex, $_age, $_activityLevel');
        return;
      }

      _neededCalariePerDay = calorieNeed;
      _neededCalarieThisMeal =
          (_neededCalariePerDay * (mealProportion[_meal] ?? 0)).round();

      final foodTypeData = dailyFoodTypeNeedsForAboveSixteen[
          (_neededCalariePerDay / 100).floor() * 100];

      if (foodTypeData == null) {
        debugPrint(
            'Error: No food type data found for calorie level ${(_neededCalariePerDay / 100).floor() * 100}');
        return;
      }

      Map<NutritionType, double> todayNeededFoodType = foodTypeData;

      // Needed Result
      _intakeFoodTypeDailyProportion =
          _intakeFoodTypeDailyProportion.map((key, _) {
        final intake = intakeTotalNutrition[key] ?? 0;
        final need = todayNeededFoodType[key] ?? 1; // Avoid division by zero
        return MapEntry(key, intake / need * 100);
      });
      _intakeFoodType = _intakeFoodType
          .map((key, _) => MapEntry(key, intakeTotalNutrition[key] ?? 0));
      _intakeTotalNutritionWithoutFoddType =
          _intakeTotalNutritionWithoutFoddType
              .map((key, _) => MapEntry(key, intakeTotalNutrition[key] ?? 0));
    }

    debugPrint('neededCalariePerDay = $_neededCalariePerDay');
    debugPrint('neededCalarieThisMeal = $_neededCalarieThisMeal');
    debugPrint(
        'intakeFoodTypeDailyProportion = $_intakeFoodTypeDailyProportion');
    debugPrint(
        'intakeFoodType = $_intakeFoodType');
    debugPrint(
        'intakeTotalNutritionWithoutFoddType = $_intakeTotalNutritionWithoutFoddType');

    // Needed comments
    _overallComment = getOverallComment();
    _commentsByFoodType = getCommentByFoodType();
    _ranksByFoodType = getRanksLabelByFoodType();
    debugPrint('overallComment = $_overallComment');
    debugPrint('commentsByFoodType = $_commentsByFoodType');
  }

  Future<Uint8List> generateReportPdf(PdfPageFormat format) async {
    // 載入中文字體
    final fontData = await rootBundle.load('assets/fonts/NotoSansCJK-Regular.otf');
    final ttf = pw.Font.ttf(fontData);
    const frameOpacity = 0.0;

    Widget myContainer = Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/printing_layout_1.png"),
          fit: BoxFit.contain,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
              height: 100,
              child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                  width: 480,
                  height: 64,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              // Basic Info
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                      height: 80,
                      child:
                          Center(child: NormalRedPrintingText(getSexLabel(_sex)))),
                  SizedBox(
                      height: 18,
                      width: 200,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      height: 80,
                      child: Center(
                          child: NormalRedPrintingText('${getAgeLabel(_age)}歲'))),
                  SizedBox(
                      height: 18,
                      width: 200,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      height: 80,
                      child: Center(
                          child: NormalRedPrintingText(
                              getActivityLevelLabel(_activityLevel)))),
                  SizedBox(
                      height: 18,
                      width: 200,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      height: 80,
                      child: Center(
                          child: NormalRedPrintingText(getMealLabel(_meal)))),
                ],
              ),
              SizedBox(
                  width: 120,
                  height: 100,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              // Ordered Dishes
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 1160,
                      height: 56,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 1160,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: Center(
                              child:
                                  NormalRedPrintingText(orderNames.join('、'))))),
                ],
              ),
              SizedBox(
                  width: 160,
                  height: 100,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              // Overall Comment
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 1160,
                      height: 56,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 1160,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(_overallComment))),
                ],
              ),
            ],
          ),
          SizedBox(
              height: 18,
              child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                  width: 720,
                  height: 50,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              // Needed Calorie Per Day
              SizedBox(
                  width: 360,
                  child: Container(
                      color: Colors.blue.withValues(alpha: frameOpacity),
                      child: HighlightPrintingText(
                          _neededCalariePerDay.toStringAsFixed(0)))),
              SizedBox(
                  width: 560,
                  height: 50,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              // Needed Calorie Range for This Meal
              SizedBox(
                  width: 810,
                  child: Container(
                      color: Colors.blue.withValues(alpha: frameOpacity),
                      child: HighlightPrintingText(
                          '${(_neededCalarieThisMeal / 100).floor() * 100}-${(_neededCalarieThisMeal / 100).ceil() * 100}'))),
            ],
          ),
          SizedBox(
              height: 118,
              child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                  width: 456,
                  height: 32,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              // Intake Food Type Amount
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 0, child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 100,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _intakeFoodType[NutritionType.grains]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 100,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _intakeFoodType[NutritionType.meat]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 100,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _intakeFoodType[NutritionType.vegetables]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 100,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _intakeFoodType[NutritionType.fruits]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 100,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _intakeFoodType[NutritionType.oils]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 100,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _intakeFoodType[NutritionType.dairy]!
                                  .toStringAsFixed(1)))),
                ],
              ),
              SizedBox(
                  width: 263,
                  height: 5,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              // Intake Food Type Daily Proportion Bars
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                      height: 14,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  PrintingBar(
                      (_intakeFoodTypeDailyProportion[NutritionType.grains]! >
                                  100
                              ? 100
                              : _intakeFoodTypeDailyProportion[
                                  NutritionType.grains]!)
                          .round(),
                      color: const Color.fromARGB(190, 247, 172, 0)),
                  SizedBox(
                      height: 66,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  PrintingBar(
                      (_intakeFoodTypeDailyProportion[NutritionType.meat]! > 100
                              ? 100
                              : _intakeFoodTypeDailyProportion[
                                  NutritionType.meat]!)
                          .round(),
                      color: const Color.fromARGB(190, 236, 67,115)),
                  SizedBox(
                      height: 66,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  PrintingBar(
                      (_intakeFoodTypeDailyProportion[
                                      NutritionType.vegetables]! >
                                  100
                              ? 100
                              : _intakeFoodTypeDailyProportion[
                                  NutritionType.vegetables]!)
                          .round(),
                      color: const Color.fromARGB(190, 126, 187, 0)),
                  SizedBox(
                      height: 66,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  PrintingBar(
                      (_intakeFoodTypeDailyProportion[NutritionType.fruits]! >
                                  100
                              ? 100
                              : _intakeFoodTypeDailyProportion[
                                  NutritionType.fruits]!)
                          .round(),
                      color: const Color.fromARGB(190, 236, 94, 0)),
                  SizedBox(
                      height: 66,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  PrintingBar(
                      (_intakeFoodTypeDailyProportion[NutritionType.oils]! > 100
                              ? 100
                              : _intakeFoodTypeDailyProportion[
                                  NutritionType.oils]!)
                          .round(),
                      color: const Color.fromARGB(190, 220, 178, 86)),
                  SizedBox(
                      height: 66,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  PrintingBar(
                      (_intakeFoodTypeDailyProportion[NutritionType.dairy]! >
                                  100
                              ? 100
                              : _intakeFoodTypeDailyProportion[
                                  NutritionType.dairy]!)
                          .round(),
                      color: const Color.fromARGB(190, 130, 206, 236)),
                ],
              ),
              // Intake Food Type Daily Proportion Percentage
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(height: 0, child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 180,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              '${_intakeFoodTypeDailyProportion[NutritionType.grains]!.round()}%'))),
                  SizedBox(
                      width: 180,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              '${_intakeFoodTypeDailyProportion[NutritionType.meat]!.round()}%'))),
                  SizedBox(
                      width: 180,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              '${_intakeFoodTypeDailyProportion[NutritionType.vegetables]!.round()}%'))),
                  SizedBox(
                      width: 180,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              '${_intakeFoodTypeDailyProportion[NutritionType.fruits]!.round()}%'))),
                  SizedBox(
                      width: 180,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              '${_intakeFoodTypeDailyProportion[NutritionType.oils]!.round()}%'))),
                  SizedBox(
                      width: 180,
                      height: 132,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              '${_intakeFoodTypeDailyProportion[NutritionType.dairy]!.round()}%'))),
                ],
              ),
              SizedBox(
                  width: 550,
                  height: 5,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              // Intake Total Nutrition Without Food Type
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 300,
                      height: 105,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              _intakeTotalNutritionWithoutFoddType[
                                      NutritionType.calorie]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 300,
                      height: 105,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              _intakeTotalNutritionWithoutFoddType[
                                      NutritionType.carb]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 300,
                      height: 105,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              _intakeTotalNutritionWithoutFoddType[
                                      NutritionType.protein]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 300,
                      height: 105,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              _intakeTotalNutritionWithoutFoddType[
                                      NutritionType.fat]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 300,
                      height: 105,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              _intakeTotalNutritionWithoutFoddType[
                                      NutritionType.na]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 300,
                      height: 105,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              _intakeTotalNutritionWithoutFoddType[
                                      NutritionType.ca]!
                                  .toStringAsFixed(1)))),
                  SizedBox(
                      width: 300,
                      height: 105,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: NormalRedPrintingText(
                              _intakeTotalNutritionWithoutFoddType[
                                      NutritionType.fiber]!
                                  .toStringAsFixed(1)))),
                ],
              ),
            ],
          ),
          SizedBox(
              height: 199,
              child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
          // Ranks by Food Type and Comments
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(
                  width: 592,
                  height: 50,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 64,
                      height: 4,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 64,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: MidPrintingText(
                              _ranksByFoodType[NutritionType.grains]!))),
                  SizedBox(
                      width: 64,
                      height: 36,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 64,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: MidPrintingText(
                              _ranksByFoodType[NutritionType.meat]!))),
                  SizedBox(
                      width: 64,
                      height: 36,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 64,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: MidPrintingText(
                              _ranksByFoodType[NutritionType.vegetables]!))),
                ],
              ),
              SizedBox(
                  width: 56,
                  height: 50,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 1000,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _commentsByFoodType[NutritionType.grains]!))),
                  SizedBox(
                      width: 50,
                      height: 36,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 1000,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _commentsByFoodType[NutritionType.meat]!))),
                  SizedBox(
                      width: 50,
                      height: 36,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 1000,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _commentsByFoodType[NutritionType.vegetables]!))),
                ],
              ),
              SizedBox(
                  width: 472,
                  height: 50,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 64,
                      height: 4,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 64,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: MidPrintingText(
                              _ranksByFoodType[NutritionType.fruits]!))),
                  SizedBox(
                      width: 64,
                      height: 36,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 64,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: MidPrintingText(
                              _ranksByFoodType[NutritionType.oils]!))),
                  SizedBox(
                      width: 64,
                      height: 36,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 64,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: MidPrintingText(
                              _ranksByFoodType[NutritionType.dairy]!))),
                ],
              ),
              SizedBox(
                  width: 60,
                  height: 50,
                  child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                      width: 1000,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _commentsByFoodType[NutritionType.fruits]!))),
                  SizedBox(
                      width: 50,
                      height: 36,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 1000,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _commentsByFoodType[NutritionType.oils]!))),
                  SizedBox(
                      width: 50,
                      height: 36,
                      child:
                          Container(color: Colors.blue.withValues(alpha: frameOpacity))),
                  SizedBox(
                      width: 1000,
                      height: 180,
                      child: Container(
                          color: Colors.blue.withValues(alpha: frameOpacity),
                          child: SmallPrintingText(
                              _commentsByFoodType[NutritionType.dairy]!))),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    ScreenshotController screenshotController = ScreenshotController();
    var capturedImage = await screenshotController.captureFromWidget(
        myContainer,
        pixelRatio: 1,
        targetSize: const Size(3508, 2480),
        delay: const Duration(seconds: 3));

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        orientation: pw.PageOrientation.landscape,
        pageFormat: format.copyWith(
            marginBottom: 0.3 * PdfPageFormat.cm,
            marginLeft: 0.3 * PdfPageFormat.cm,
            marginRight: 0.3 * PdfPageFormat.cm,
            marginTop: 0.3 * PdfPageFormat.cm),
        theme: pw.ThemeData.withFont(base: ttf),
        build: (context) {
          return pw.Center(
            child: pw.Image(
              pw.MemoryImage(capturedImage),
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );
    return pdf.save();
  }

  Future<Uint8List> generateLabelPdf(PdfPageFormat format) async {
    // 載入中文字體
  final fontData = await rootBundle.load('assets/fonts/NotoSansCJK-Regular.otf');
  final ttf = pw.Font.ttf(fontData);
  const frameOpacity = 0.0;
  Widget myContainer = Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/images/printing_layout_2.png"),
        fit: BoxFit.contain,
      ),
    ),
    child: Column(
      children: [
        // Title hight
        SizedBox(
            height: 640,
            child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Product Resume
            SizedBox(
                width: 1000,
                height: 5,
                child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                    height: 825,
                    child: Align(alignment: Alignment.topLeft, child: NormalBlackPrintingText('料理： $_productResumeLabelDishes\n追溯編號：${foodToLabelInfo[_productResumeLabelFood]?["trace_code"]}\n產品名稱：$_productResumeLabelFood\n農產品經營者：${foodToLabelInfo[_productResumeLabelFood]?["operator"]}\n包裝日期：${foodToLabelInfo[_productResumeLabelFood]?["packaging_date"]}\n電話：${foodToLabelInfo[_productResumeLabelFood]?["phone"]}\n地址：${foodToLabelInfo[_productResumeLabelFood]?["address"]}'))),
                SizedBox(
                    height: 5,
                    width: 740,
                    child:
                        Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              ],
            ),
            // CAS Label
            SizedBox(
                width: 600,
                height: 5,
                child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                    height: 825,
                    child: Align(alignment: Alignment.topLeft, child: NormalBlackPrintingText('料理：$_casLabelDishes\n標章編號：${foodToLabelInfo[_casLabelFood]?["certification_id"]}\n產品種類：${foodToLabelInfo[_casLabelFood]?["product_type"]}\n產品名稱：$_casLabelFood\n產品類別：${foodToLabelInfo[_casLabelFood]?["category"]}\n廠商名稱：${foodToLabelInfo[_casLabelFood]?["manufacturer"]}\n地址：${foodToLabelInfo[_casLabelFood]?["address"]}\n電話：${foodToLabelInfo[_casLabelFood]?["phone"]}\n負責人：${foodToLabelInfo[_casLabelFood]?["representative"]}\n驗證機構：${foodToLabelInfo[_casLabelFood]?["certification_body"]}'))),
                // space between label group 2
                SizedBox(
                    height: 5,
                    width: 1155,
                    child:
                        Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              ],
            ),
            SizedBox(
                width: 5,
                height: 830,
                child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
          ],
        ),
        // Organic Label
        SizedBox(
            height: 80,
            child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(
                width: 650,
                height: 5,
                child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                    height: 800,
                    child: Center(child: NormalBlackPrintingText('料理：$_organicLabelDishes\n品項：${foodToLabelInfo[_organicLabelFood]?["category"]} \n產品範圍：$_organicLabelFood\n農產品經營者：${foodToLabelInfo[_organicLabelFood]?["operator"]}\n驗證機構名稱：${foodToLabelInfo[_organicLabelFood]?["certification_body"]}\n證書字號(有機)：${foodToLabelInfo[_organicLabelFood]?["certificate_number"]}\n驗證效期：${foodToLabelInfo[_organicLabelFood]?["expiration_date"]}\n電話：${foodToLabelInfo[_organicLabelFood]?["phone"]}\n驗證場所地址(有機)：${foodToLabelInfo[_organicLabelFood]?["address"]}'))),
                SizedBox(
                    height: 30,
                    width: 1100,
                    child:
                        Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              ],
            ),
            // Traceable Label
            SizedBox(
                width: 550,
                height: 5,
                child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(
                    height: 800,
                    child: Center(child: NormalBlackPrintingText('料理：$_traceableLabelDishes\n追溯編號：${foodToLabelInfo[_traceableLabelFood]?["trace_code"]}\n品名：$_traceableLabelFood\n生產者：${foodToLabelInfo[_traceableLabelFood]?["operator"]}\n電話：${foodToLabelInfo[_traceableLabelFood]?["phone"]}\n地址：${foodToLabelInfo[_traceableLabelFood]?["address"]}\n簡介：${foodToLabelInfo[_traceableLabelFood]?["description"]}'))),
                SizedBox(
                    height: 30,
                    width: 1200,
                    child:
                        Container(color: Colors.blue.withValues(alpha: frameOpacity))),
              ],
            ),
             SizedBox(
                width: 5,
                height: 830,
                child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
          ],
        ),
      ],
    ),
  );

  ScreenshotController screenshotController = ScreenshotController();
  var capturedImage = await screenshotController.captureFromWidget(myContainer,
      pixelRatio: 1,
      targetSize: const Size(3508, 2480),
      delay: const Duration(seconds: 3));

  final pdf = pw.Document();
  pdf.addPage(
    pw.Page(
      orientation: pw.PageOrientation.landscape,
      pageFormat: format.copyWith(
          marginBottom: 0.3 * PdfPageFormat.cm,
          marginLeft: 0.3 * PdfPageFormat.cm,
          marginRight: 0.3 * PdfPageFormat.cm,
          marginTop: 0.3 * PdfPageFormat.cm),
      theme: pw.ThemeData.withFont(base: ttf),
      build: (context) {
        return pw.Center(
          child: pw.Image(
            pw.MemoryImage(capturedImage),
            fit: pw.BoxFit.contain,
          ),
        );
      },
    ),
  );
  return pdf.save();
  }

  Future<void> initialize() async {
    _meal = Meal.lunch;
    _activityLevel = ActivityLevel.miderate;
    _sex = Sex.female;
    _age = Age.zeroToNine;

    orderNames = [];

    // Needed analyze results
    _neededCalariePerDay = 0;
    _neededCalarieThisMeal = 0;
    _intakeFoodTypeDailyProportion = {
      NutritionType.grains: 0,
      NutritionType.meat: 0,
      NutritionType.vegetables: 0,
      NutritionType.fruits: 0,
      NutritionType.oils: 0,
      NutritionType.dairy: 0,
    };

    _intakeFoodType = {
      NutritionType.grains: 0,
      NutritionType.meat: 0,
      NutritionType.vegetables: 0,
      NutritionType.fruits: 0,
      NutritionType.oils: 0,
      NutritionType.dairy: 0,
    };

    _intakeTotalNutritionWithoutFoddType = {
      NutritionType.calorie: 0,
      NutritionType.carb: 0,
      NutritionType.protein: 0,
      NutritionType.fat: 0,
      NutritionType.na: 0,
      NutritionType.ca: 0,
      NutritionType.fiber: 0,
    };

    // Needed comments
    _overallComment = '';
    _commentsByFoodType = {
      NutritionType.grains: '',
      NutritionType.meat: '',
      NutritionType.vegetables: '',
      NutritionType.fruits: '',
      NutritionType.oils: '',
      NutritionType.dairy: '',
    };
    _ranksByFoodType = {
      NutritionType.grains: '',
      NutritionType.meat: '',
      NutritionType.vegetables: '',
      NutritionType.fruits: '',
      NutritionType.oils: '',
      NutritionType.dairy: '',
    };
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    debugPrint('Data will be saved under "$path"');
    return File('$path/data.csv');
  }

  Future<void> saveData() async {
    final file = await _localFile;
    var dateUtc = DateTime.now().toUtc();
    var dateLocal = dateUtc.toLocal();
    String outputString =
        '$dateLocal, ${getAgeLabel(_age)}, ${getSexLabel(_sex)}, ${getActivityLevelLabel(_activityLevel)}, ${orderNames.join(',')}, "$_overallComment", "$_intakeFoodType", "$_intakeFoodTypeDailyProportion", "$_ranksByFoodType"\r\n';
    debugPrint('outputString = $outputString');
    if (await file.exists()) {
      file.writeAsString(outputString, mode: FileMode.append);
    } else {
      file.writeAsString(outputString);
    }
    file.writeAsString(Platform.lineTerminator, mode: FileMode.append);
  }
}

class NormalBlackPrintingText extends StatelessWidget {
  final String text;

  const NormalBlackPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 50,
                color: Colors.black,
                fontFamily: 'NotoSansCJK')));
  }
}

class NormalRedPrintingText extends StatelessWidget {
  final String text;

  const NormalRedPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 46,
                color: Colors.red,
                fontFamily: 'NotoSansCJK')));
  }
}

class HighlightPrintingText extends StatelessWidget {
  final String text;

  const HighlightPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 120,
                color: Colors.red,
                fontFamily: 'NotoSansCJK')));
  }
}

class SmallPrintingText extends StatelessWidget {
  final String text;

  const SmallPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 40,
                color: Colors.red,
                fontFamily: 'NotoSansCJK')));
  }
}

class MidPrintingText extends StatelessWidget {
  final String text;

  const MidPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 56,
                color: Colors.red,
                fontFamily: 'NotoSansCJK')));
  }
}

class PrintingBar extends StatelessWidget {
  final int percent;
  final Color color;

  const PrintingBar(this.percent, {super.key, required this.color});
  static const frameOpacity = 0.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
            width: 1225.5 * percent / 100.0,
            height: 66,
            child: Container(color: color.withValues(alpha: 0.7))),
        SizedBox(
            width: 1225.5 * (1.0 - percent / 100.0),
            height: 66,
            child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
      ],
    );
  }
}
