import 'package:flutter/material.dart';
import 'package:smart_bite/data/constant.dart';


class DataProvider extends ChangeNotifier {
  Meal _meal = Meal.lunch;
  ActivityLevel _activityLevel = ActivityLevel.miderate;
  Sex _sex = Sex.female;
  Age _age = Age.zeroToNine;
  
  List<String> orderNames = [];
  String _mealLabel = '午餐';
  String _activityLevelLabel = '適度';
  String _sexLabel = '女';
  String _ageLabel = '0-9';

  String get mealLabel => _mealLabel;
  String get activityLevelLabel => _activityLevelLabel;
  String get sexLabel => _sexLabel;
  String get ageLabel => _ageLabel;

  Meal get meal => _meal;
  ActivityLevel get activityLevel => _activityLevel;
  Sex get sex => _sex;
  Age get age => _age;

  set meal (Meal value){
    _meal = value;
    _mealLabel = getMealLabel(value);
    notifyListeners();
  }
  
  set activityLevel (ActivityLevel value){
    _activityLevel = value;
    _activityLevelLabel = getActivityLevelLabel(value);
    notifyListeners();
  }

  set sex (Sex value){
    _sex = value;
    _sexLabel = getSexLabel(value);
    notifyListeners();
  }

  set age (Age value){
    _age = value;
    _ageLabel = getAgeLabel(value);
    notifyListeners();
  }
}