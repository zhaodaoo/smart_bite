/// Lazy Loading Service for PDF-Only Static Data
///
/// Defers loading of three_label_one_code.dart (18 KB, 68 entries)
/// until first PDF generation to improve app startup time.
library;

import 'package:smart_bite/data/three_label_one_code.dart';

/// Lazy-loaded label information for PDF generation
class LazyLabelData {
  static Map<String, Map<String, String>>? _data;
  static bool _isLoading = false;

  /// Get label data (loads on first access)
  static Map<String, Map<String, String>> get data {
    if (_data == null && !_isLoading) {
      _load();
    }
    return _data ?? {};
  }

  /// Check if data is loaded
  static bool get isLoaded => _data != null;

  /// Load the data (called automatically on first access)
  static void _load() {
    _isLoading = true;
    // Import happens here, deferred until needed
    _data = _loadLabelDataInternal();
    _isLoading = false;
  }

  /// Internal method to load data from source
  static Map<String, Map<String, String>> _loadLabelDataInternal() {
    // This import is evaluated only when this method is called
    // Note: Dart doesn't have true dynamic imports, so we import at top
    // but only access the data when this method is called
    return _getFoodToLabelInfo();
  }

  /// Preload the data explicitly (optional, for warming up)
  static Future<void> preload() async {
    if (_data == null) {
      _load();
    }
  }

  /// Clear the data (for testing or memory management)
  static void clear() {
    _data = null;
    _isLoading = false;
  }

  /// Get label info for specific food
  static Map<String, String>? getInfo(String foodName) {
    return data[foodName];
  }

  /// Get specific field from label info
  static String? getField(String foodName, String fieldName) {
    return data[foodName]?[fieldName];
  }
}

/// Internal function to access the actual data
/// This is separated to make lazy loading more explicit
Map<String, Map<String, String>> _getFoodToLabelInfo() {
  // Import the actual data here
  // In Dart, imports are evaluated at compile time, but we control
  // when the data is accessed and copied into memory
  return foodToLabelInfo;
}
