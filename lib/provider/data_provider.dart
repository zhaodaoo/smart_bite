import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import 'package:smart_bite/data/constant.dart';
import 'package:smart_bite/data/comments.dart';
import 'package:smart_bite/services/nutrition_analysis_service.dart';
import 'package:smart_bite/services/pdf_generation_service.dart';
import 'package:smart_bite/services/data_persistence_service.dart';

/// DataProvider now focuses purely on UI state management.
/// Business logic has been extracted to service classes.
class DataProvider extends ChangeNotifier {
  String _printerName = 'DCPT426W';
  bool _includeLabelPage = false; // Default: only print report, not label
  Meal _meal = Meal.lunch;
  ActivityLevel _activityLevel = ActivityLevel.miderate;
  Sex _sex = Sex.female;
  Age _age = Age.zeroToNine;

  List<String> orderNames = [];

  // Analysis results from service (cached after analyze() is called)
  NutritionAnalysisResult? _analysisResult;

  // Getters for UI state
  Meal get meal => _meal;
  ActivityLevel get activityLevel => _activityLevel;
  Sex get sex => _sex;
  Age get age => _age;

  // Getters for analysis results (with safe defaults)
  int get neededCaloriePerDay => _analysisResult?.neededCaloriePerDay ?? 0;
  int get neededCalorieThisMeal => _analysisResult?.neededCalorieThisMeal ?? 0;
  Map<NutritionType, double> get intakeFoodTypeDailyProportion =>
      _analysisResult?.intakeFoodTypeDailyProportion ??
      {
        NutritionType.grains: 0,
        NutritionType.meat: 0,
        NutritionType.vegetables: 0,
        NutritionType.fruits: 0,
        NutritionType.oils: 0,
        NutritionType.dairy: 0,
      };
  Map<NutritionType, double> get intakeTotalNutritionWithoutFoodType =>
      _analysisResult?.intakeTotalNutritionWithoutFoodType ??
      {
        NutritionType.calorie: 0,
        NutritionType.carb: 0,
        NutritionType.protein: 0,
        NutritionType.fat: 0,
        NutritionType.na: 0,
        NutritionType.ca: 0,
        NutritionType.fiber: 0,
      };
  String get overallComment => _analysisResult?.overallComment ?? '';
  Map<NutritionType, String> get commentsByFoodType =>
      _analysisResult?.commentsByFoodType ??
      {
        NutritionType.grains: '',
        NutritionType.meat: '',
        NutritionType.vegetables: '',
        NutritionType.fruits: '',
        NutritionType.oils: '',
        NutritionType.dairy: '',
      };

  // Provide access to comment templates (for UI separation of concerns)
  Map<NutritionType, Map<Rank, String>> get commentTemplates =>
      commentsForFoodTypeByRank;

  String get printerName => _printerName;
  set printerName(String input) {
    _printerName = input;
    notifyListeners();
  }

  bool get includeLabelPage => _includeLabelPage;
  set includeLabelPage(bool value) {
    _includeLabelPage = value;
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

  /// Analyzes nutrition data using NutritionAnalysisService.
  /// Results are cached in _analysisResult for use by getters and PDF generation.
  Future<void> analyze() async {
    try {
      _analysisResult = await NutritionAnalysisService.analyzeNutrition(
        orderNames: orderNames,
        meal: _meal,
        sex: _sex,
        age: _age,
        activityLevel: _activityLevel,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error in analyze(): $e');
      // rethrow; // Propagate error to UI for handling
    }
  }

  /// Generates a nutrition report PDF using PDFGenerationService.
  Future<Uint8List> generateReportPdf(PdfPageFormat format) async {
    if (_analysisResult == null) {
      throw Exception(
          'Analysis must be performed before generating report PDF');
    }
    try {
      return await PDFGenerationService.generateReportPdf(
        format: format,
        analysisResult: _analysisResult!,
        orderNames: orderNames,
        meal: _meal,
        sex: _sex,
        age: _age,
        activityLevel: _activityLevel,
      );
    } catch (e) {
      debugPrint('Error generating report PDF: $e');
      rethrow; // Propagate error to UI for handling
    }
  }

  /// Generates a food label PDF using PDFGenerationService.
  Future<Uint8List> generateLabelPdf(PdfPageFormat format) async {
    if (_analysisResult == null) {
      throw Exception('Analysis must be performed before generating label PDF');
    }
    try {
      return await PDFGenerationService.generateLabelPdf(
        format: format,
        labelInfo: _analysisResult!.labelInfo,
      );
    } catch (e) {
      debugPrint('Error generating label PDF: $e');
      rethrow; // Propagate error to UI for handling
    }
  }

  /// Generates a combined PDF with both nutrition report and label pages.
  ///
  /// Creates a single PDF document with 2 pages. If either page fails,
  /// only successfully generated pages will be included.
  ///
  /// Throws [Exception] if analysis hasn't been performed or if both pages fail.
  Future<Uint8List> generateCombinedPdf(PdfPageFormat format) async {
    if (_analysisResult == null) {
      throw Exception(
          'Analysis must be performed before generating combined PDF');
    }
    try {
      return await PDFGenerationService.generateCombinedPdf(
        format: format,
        analysisResult: _analysisResult!,
        orderNames: orderNames,
        meal: _meal,
        sex: _sex,
        age: _age,
        activityLevel: _activityLevel,
      );
    } catch (e) {
      debugPrint('Error generating combined PDF: $e');
      rethrow; // Propagate error to UI for handling
    }
  }

  /// Initializes/resets the provider state.
  Future<void> initialize() async {
    _meal = Meal.lunch;
    _activityLevel = ActivityLevel.miderate;
    _sex = Sex.female;
    _age = Age.zeroToNine;
    orderNames = [];
    _analysisResult = null;
    // Load saved includeLabelPage preference (defaults to false if not saved)
    _includeLabelPage = await DataPersistenceService.loadIncludeLabelPage();
    notifyListeners();
  }

  /// Saves analysis data using DataPersistenceService.
  Future<void> saveData() async {
    if (_analysisResult == null) {
      debugPrint('Warning: No analysis result to save');
      return;
    }
    try {
      await DataPersistenceService.saveAnalysisData(
        age: _age,
        sex: _sex,
        activityLevel: _activityLevel,
        orderNames: orderNames,
        overallComment: _analysisResult!.overallComment,
        intakeFoodType: _analysisResult!.intakeFoodType,
        intakeFoodTypeDailyProportion:
            _analysisResult!.intakeFoodTypeDailyProportion,
        ranksByFoodType: _analysisResult!.ranksByFoodType,
      );
    } catch (e) {
      debugPrint('Error saving data: $e');
      rethrow; // Propagate error to UI for handling
    }
  }
}
