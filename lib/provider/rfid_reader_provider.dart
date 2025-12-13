/// RFID Reader Provider
/// 
/// Abstracted provider that manages RFID readers independently of the hardware implementation.
/// Replaces SerialPortsProvider with a hardware-agnostic interface.
/// 
/// Supports multiple reader implementations:
/// - Serial (Arduino + USB)
/// - GPIO/SPI (Raspberry Pi)
/// - Mock (Testing)
library;

import 'package:flutter/material.dart';
import '../interfaces/rfid_reader.dart';
import '../services/meal_identification_service.dart';

/// Provider for managing RFID readers and meal identification
class RFIDReaderProvider extends ChangeNotifier {
  final RFIDReaderManager _readerManager;
  final MealIdentificationService _mealService;
  
  List<String> _orderNames = [];
  bool _isScanning = false;

  RFIDReaderProvider({
    required RFIDReaderManager readerManager,
    MealIdentificationService? mealService,
  })  : _readerManager = readerManager,
        _mealService = mealService ?? MealIdentificationService() {
    // Listen to reader manager changes
    _readerManager.addListener(_onReaderManagerUpdate);
  }

  // ========== Getters ==========

  /// List of all RFID readers
  List<RFIDReader> get readers => _readerManager.readers;

  /// Scan timeout in seconds
  double get scanTimeout => _readerManager.scanTimeout;

  /// List of identified meal names from last scan
  List<String> get orderNames => List.unmodifiable(_orderNames);

  /// Whether a scan is currently in progress
  bool get isScanning => _isScanning;

  /// Number of readers
  int get readerCount => readers.length;

  /// Number of valid cards detected in last scan
  int get validCardCount => _orderNames.length;

  // ========== Setters ==========

  set scanTimeout(double seconds) {
    _readerManager.scanTimeout = seconds;
    notifyListeners();
  }

  // ========== Methods ==========

  /// Discover and initialize all available readers
  Future<void> discoverReaders() async {
    try {
      await _readerManager.discoverReaders();
      notifyListeners();
    } catch (e) {
      debugPrint('Error discovering readers: $e');
      rethrow;
    }
  }

  /// Scan all readers and identify meals
  /// 
  /// This is the main method that:
  /// 1. Scans all RFID readers
  /// 2. Identifies meals from card UIDs
  /// 3. Updates orderNames list
  /// 4. Notifies listeners
  Future<void> updateReaders() async {
    if (_isScanning) {
      debugPrint('Scan already in progress, skipping');
      return;
    }

    _isScanning = true;
    _orderNames.clear();
    notifyListeners();

    try {
      // Scan all readers
      final readings = await _readerManager.scanAll();
      
      // Identify meals from valid readings
      _orderNames = _mealService.identifyMealsFromReadings(readings);
      
      debugPrint('Scan complete: ${_orderNames.length} meals identified');
      debugPrint('Meals: $_orderNames');
      
    } catch (e) {
      debugPrint('Error during scan: $e');
      rethrow;
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Get reading from a specific reader by device ID
  RFIDReading? getReading(String deviceId) {
    return _readerManager.getReading(deviceId);
  }

  /// Get all readings with valid cards
  List<RFIDReading> get validReadings => _readerManager.validReadings;

  /// Get statistics about last scan
  Map<String, int> getStats() {
    final allReadings = readers
        .map((r) => getReading(r.deviceId))
        .whereType<RFIDReading>()
        .toList();
    
    return _mealService.getIdentificationStats(allReadings);
  }

  /// Get reader status summary
  Map<String, int> getReaderStatusSummary() {
    final statusCounts = <String, int>{
      'init': 0,
      'updating': 0,
      'ok': 0,
      'error': 0,
      'disconnected': 0,
    };

    for (final reader in readers) {
      final statusKey = reader.status.toString().split('.').last;
      statusCounts[statusKey] = (statusCounts[statusKey] ?? 0) + 1;
    }

    return statusCounts;
  }

  /// Check if all readers are in OK state
  bool get allReadersOk {
    return readers.every((r) => r.status == ReaderStatus.ok);
  }

  /// Check if any reader has an error
  bool get hasErrors {
    return readers.any((r) => r.status == ReaderStatus.error);
  }

  void _onReaderManagerUpdate() {
    notifyListeners();
  }

  @override
  void dispose() {
    _readerManager.removeListener(_onReaderManagerUpdate);
    _readerManager.dispose();
    super.dispose();
  }
}

/// Extension to convert ReaderStatus to user-friendly display strings
extension ReaderStatusDisplay on ReaderStatus {
  String get displayName {
    switch (this) {
      case ReaderStatus.init:
        return '初始化';
      case ReaderStatus.updating:
        return '更新中';
      case ReaderStatus.ok:
        return '正常';
      case ReaderStatus.error:
        return '錯誤';
      case ReaderStatus.disconnected:
        return '未連接';
    }
  }

  /// Get color for status display
  Color get color {
    switch (this) {
      case ReaderStatus.init:
        return Colors.grey;
      case ReaderStatus.updating:
        return Colors.blue;
      case ReaderStatus.ok:
        return Colors.green;
      case ReaderStatus.error:
        return Colors.red;
      case ReaderStatus.disconnected:
        return Colors.orange;
    }
  }
}
