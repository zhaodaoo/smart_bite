import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:screenshot/screenshot.dart';

import 'package:smart_bite/data/comments.dart';
import 'package:smart_bite/data/constant.dart';
import 'package:smart_bite/data/dailyneeds_for_sixteen_above.dart';
import 'package:smart_bite/data/dishes_info.dart';
import 'package:smart_bite/data/dailyneeds_for_under_fifteen.dart';


class DataProvider extends ChangeNotifier {
  String _printerName = 'Brother DCP-T420W Printer';
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
  
  get screenshotController => null;

  String get printerName => _printerName;
  set printerName (String input) {
    _printerName = input;
    notifyListeners();
  }

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
      } else if (_intakeFoodTypeDailyProportion[key]! < 100) {
        // ignore: collection_methods_unrelated_type
        return MapEntry(key, commentsForFoodTypeByRank[key]![Rank.tooLess]!);
      } else {
        // ignore: collection_methods_unrelated_type
        return MapEntry(key, commentsForFoodTypeByRank[key]![Rank.good]!);
      }

    });
  }

  Map<NutritionType, String> getRanksLabelByFoodType() {
    return _ranksByFoodType.map((key, value) {
      if (_intakeFoodTypeDailyProportion[key]! > 100) {
        // ignore: collection_methods_unrelated_type
        return MapEntry(key, getRankLabel(Rank.tooMuch));
      } else if (_intakeFoodTypeDailyProportion[key]! < 100) {
        // ignore: collection_methods_unrelated_type
        return MapEntry(key, getRankLabel(Rank.tooLess));
      } else {
        // ignore: collection_methods_unrelated_type
        return MapEntry(key, getRankLabel(Rank.good));
      }

    });
  }
  
  Future<void> analyze() async{
    // Intake meal nutririon
    List<Map<NutritionType, double>?> eachMealNutrition =  orderNames.map((name) => dishesInfo[name]).toList();
    Map<NutritionType, double> intakeTotalNutrition = {};
    intakeTotalNutrition.addEntries(NutritionType.values.map((key) => MapEntry(key, eachMealNutrition.map((meal) => meal![key]).fold(0.0, (previousValue, element) => previousValue + element!))));
    debugPrint('intakeTotalNutrition = $intakeTotalNutrition');

    if ([Age.zeroToNine, Age.tenToTwelve, Age.thirteenToFifteen].contains(_age)) {
      // Needed nutririons
      Map<NutritionType, double> todayNeeds = dailyNeedsForUnderFifteen[_sex]![_age]![_activityLevel]!;
      debugPrint('todayNeeds = $todayNeeds');

      // Needed Result
      _neededCalariePerDay = todayNeeds[NutritionType.calorie]!.round();
      _neededCalarieThisMeal = (_neededCalariePerDay * mealProportion[_meal]!).round();
      _intakeFoodTypeDailyProportion = intakeFoodTypeDailyProportion.map((key, _) => MapEntry(key, intakeTotalNutrition[key]!/todayNeeds[key]!*100));
      _intakeTotalNutritionWithoutFoddType = intakeTotalNutritionWithoutFoddType.map((key, _) => MapEntry(key, intakeTotalNutrition[key]!));
    } else {
      _neededCalariePerDay = dailyCalorieNeedsForAboveSixteen[_sex]![_age]![_activityLevel]!;
      _neededCalarieThisMeal = (_neededCalariePerDay * mealProportion[_meal]!).round();
      Map<NutritionType, double> todayNeededFoodType = dailyFoodTypeNeedsForAboveSixteen[(_neededCalariePerDay/100).floor()*100]!;

      // Needed Result
      _intakeFoodTypeDailyProportion = intakeFoodTypeDailyProportion.map((key, _) => MapEntry(key, intakeTotalNutrition[key]!/todayNeededFoodType[key]!*100));
      _intakeFoodType = _intakeFoodType.map((key, _) => MapEntry(key, intakeTotalNutrition[key]!));
      _intakeTotalNutritionWithoutFoddType = intakeTotalNutritionWithoutFoddType.map((key, _) => MapEntry(key, intakeTotalNutrition[key]!));
      
    }
    
    debugPrint('neededCalariePerDay = $_neededCalariePerDay');
    debugPrint('neededCalarieThisMeal = $_neededCalarieThisMeal');
    debugPrint('intakeFoodTypeDailyProportion = $_intakeFoodTypeDailyProportion');
    debugPrint('intakeTotalNutritionWithoutFoddType = $_intakeTotalNutritionWithoutFoddType');

    // Needed comments
    _overallComment = getOverallComment();
    _commentsByFoodType = getCommentByFoodType();
    _ranksByFoodType = getRanksLabelByFoodType();
    debugPrint('overallComment = $_overallComment');
    debugPrint('commentsByFoodType = $_commentsByFoodType');
  }

  Future<Uint8List> generatePdf(PdfPageFormat format) async {
    
    Widget myContainer = Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/printing_layout.png"),
          fit: BoxFit.contain,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 100, child: Container(color: Colors.blue.withOpacity(0.0))),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 480, height: 64, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(height: 80, child: Center(child: NormalPrintingText(getSexLabel(_sex)))),
                  SizedBox(height: 18, width: 200, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(height: 80, child: Center(child: NormalPrintingText('${getAgeLabel(_age)}歲'))),
                  SizedBox(height: 18, width: 200, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(height: 80, child: Center(child: NormalPrintingText(getActivityLevelLabel(_activityLevel)))),
                  SizedBox(height: 18, width: 200, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(height: 80, child: Center(child: NormalPrintingText(getMealLabel(_meal)))),
                ],
              ),
              SizedBox(width: 120, height: 100, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 1160, height: 56, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 1160, child: 
                    Container(color: Colors.blue.withOpacity(0.0), 
                    child: Center(child: NormalPrintingText(orderNames.join('、'))
                  ))),
                ],
              ),
              SizedBox(width: 160, height: 100, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 1160, height: 56, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 1160, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText(_overallComment)
                  )),
                ],
              ),
            
            ],
          ),
          SizedBox(height: 18, child: Container(color: Colors.blue.withOpacity(0.0))),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 720, height: 50, child: Container(color: Colors.blue.withOpacity(0.0))),
              SizedBox(width: 360, child: Container(
                color: Colors.blue.withOpacity(0.0), 
                child: HighlightPrintingText(_neededCalariePerDay.toStringAsFixed(0)))
              ),
              SizedBox(width: 560, height: 50, child: Container(color: Colors.blue.withOpacity(0.0))),
              SizedBox(width: 810, child: Container(
                color: Colors.blue.withOpacity(0.0), 
                child: HighlightPrintingText('${(_neededCalarieThisMeal/100).floor()*100}-${(_neededCalarieThisMeal/100).ceil()*100}')
              )),
            ],
          ),
          SizedBox(height: 136, child: Container(color: Colors.blue.withOpacity(0.0))),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 454, height: 40, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 100, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_intakeFoodType[NutritionType.grains]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 100, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_intakeFoodType[NutritionType.meat]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 100, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_intakeFoodType[NutritionType.vegetables]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 100, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_intakeFoodType[NutritionType.fruits]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 100, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_intakeFoodType[NutritionType.oils]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 100, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_intakeFoodType[NutritionType.dairy]!.toStringAsFixed(1))
                  )),
                ],
              ),
              SizedBox(width: 254, height: 50, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(height: 33, child: Container(color: Colors.blue.withOpacity(0.0))),
                  PrintingBar(
                    _intakeFoodTypeDailyProportion[NutritionType.grains]!.round(), 
                    color: const Color.fromARGB(1, 236, 176, 30)
                  ),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  PrintingBar(
                    _intakeFoodTypeDailyProportion[NutritionType.meat]!.round(), 
                    color: const Color.fromARGB(1, 236, 176, 30)
                  ),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  PrintingBar(
                    _intakeFoodTypeDailyProportion[NutritionType.vegetables]!.round(), 
                    color: const Color.fromARGB(1, 236, 176, 30)
                  ),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  PrintingBar(
                    _intakeFoodTypeDailyProportion[NutritionType.fruits]!.round(), 
                    color: const Color.fromARGB(1, 236, 176, 30)
                  ),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  PrintingBar(
                    _intakeFoodTypeDailyProportion[NutritionType.oils]!.round(), 
                    color: const Color.fromARGB(1, 236, 176, 30)
                  ),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  PrintingBar(
                    _intakeFoodTypeDailyProportion[NutritionType.dairy]!.round(), 
                    color: const Color.fromARGB(1, 236, 176, 30)
                  ),
                  SizedBox(height: 33, child: Container(color: Colors.blue.withOpacity(0.0))),
                ],
              ),
              // SizedBox(width: 70, height: 35, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 180, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText('${_intakeFoodTypeDailyProportion[NutritionType.grains]!.round()}%')
                  )),
                  SizedBox(width: 180, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText('${_intakeFoodTypeDailyProportion[NutritionType.meat]!.round()}%')
                  )),
                  SizedBox(width: 180, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText('${_intakeFoodTypeDailyProportion[NutritionType.vegetables]!.round()}%')
                  )),
                  SizedBox(width: 180, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText('${_intakeFoodTypeDailyProportion[NutritionType.fruits]!.round()}%')
                  )),
                  SizedBox(width: 180, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText('${_intakeFoodTypeDailyProportion[NutritionType.oils]!.round()}%')
                  )),
                  SizedBox(width: 180, height: 132, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText('${_intakeFoodTypeDailyProportion[NutritionType.dairy]!.round()}%')
                  )),
                ],
              ),
              SizedBox(width: 550, height: 35, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 300, height: 105, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText(_intakeTotalNutritionWithoutFoddType[NutritionType.calorie]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 300, height: 105, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText(_intakeTotalNutritionWithoutFoddType[NutritionType.carb]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 300, height: 105, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText(_intakeTotalNutritionWithoutFoddType[NutritionType.protein]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 300, height: 105, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText(_intakeTotalNutritionWithoutFoddType[NutritionType.fat]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 300, height: 105, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText(_intakeTotalNutritionWithoutFoddType[NutritionType.na]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 300, height: 105, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText(_intakeTotalNutritionWithoutFoddType[NutritionType.ca]!.toStringAsFixed(1))
                  )),
                  SizedBox(width: 300, height: 105, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: NormalPrintingText(_intakeTotalNutritionWithoutFoddType[NutritionType.fiber]!.toStringAsFixed(1))
                  )),
                ],
              ),
            
            ],
          ),
          SizedBox(height: 192, child: Container(color: Colors.blue.withOpacity(0.0))),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 592, height: 50, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 64, height: 4, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 64, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: MidPrintingText(_ranksByFoodType[NutritionType.grains]!)
                  )),
                  SizedBox(width: 64, height: 36, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 64, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: MidPrintingText(_ranksByFoodType[NutritionType.meat]!)
                  )),
                  SizedBox(width: 64, height: 36, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 64, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: MidPrintingText(_ranksByFoodType[NutritionType.vegetables]!)
                  )),
                ],
              ),
              
              SizedBox(width: 56, height: 50, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 1000, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_commentsByFoodType[NutritionType.grains]!)
                  )),
                  SizedBox(width: 50, height: 36, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 1000, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_commentsByFoodType[NutritionType.meat]!)
                  )),SizedBox(width: 50, height: 36, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 1000, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_commentsByFoodType[NutritionType.vegetables]!)
                  )),
                ],
              ),
              SizedBox(width: 472, height: 50, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 64, height: 4, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 64, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: MidPrintingText(_ranksByFoodType[NutritionType.fruits]!)
                  )),
                  SizedBox(width: 64, height: 36, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 64, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: MidPrintingText(_ranksByFoodType[NutritionType.oils]!)
                  )),
                  SizedBox(width: 64, height: 36, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 64, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: MidPrintingText(_ranksByFoodType[NutritionType.dairy]!)
                  )),
                ],
              ),
              
              SizedBox(width: 60, height: 50, child: Container(color: Colors.blue.withOpacity(0.0))),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 1000, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_commentsByFoodType[NutritionType.fruits]!)
                  )),
                  SizedBox(width: 50, height: 36, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 1000, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_commentsByFoodType[NutritionType.oils]!)
                  )),SizedBox(width: 50, height: 36, child: Container(color: Colors.blue.withOpacity(0.0))),
                  SizedBox(width: 1000, height: 180, child: Container(
                    color: Colors.blue.withOpacity(0.0), 
                    child: SmallPrintingText(_commentsByFoodType[NutritionType.dairy]!)
                  )),
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
      targetSize: const Size(3508,2480),
      delay: const Duration(seconds: 3)
    );

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: format.copyWith(
          marginBottom: 0.3 * PdfPageFormat.cm,
          marginLeft: 0.3 * PdfPageFormat.cm,
          marginRight: 0.3 * PdfPageFormat.cm,
          marginTop: 0.3 * PdfPageFormat.cm
        ),
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
  
  Future<void> initialize() async{
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
}


class NormalPrintingText extends StatelessWidget {
  final String text;

  const NormalPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(fontSize: 46, color: Colors.red)));
  }
}

class HighlightPrintingText extends StatelessWidget {
  final String text;

  const HighlightPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(fontSize: 120, color: Colors.red)));
  }
}

class SmallPrintingText extends StatelessWidget {
  final String text;

  const SmallPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(fontSize: 40, color: Colors.red)));
  }
}

class MidPrintingText extends StatelessWidget {
  final String text;

  const MidPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(fontSize: 56, color: Colors.red)));
  }
}

class PrintingBar extends StatelessWidget {
  final int percent;
  final Color color;

  const PrintingBar(this.percent, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: 1222.0*percent/100.0, height: 66, child: Container(color: color.withOpacity(0.7))),
        SizedBox(width: 1222.0*(1.0-percent/100.0), height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
      ],
    );
  }
  
}
