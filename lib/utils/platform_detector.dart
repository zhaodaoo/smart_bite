/// Platform Detection and RFID Reader Factory
/// 
/// Automatically detects the platform and creates the appropriate RFID reader implementation:
/// - Raspberry Pi (Linux on ARM): GPIO/SPI adapter
/// - Other platforms: Serial adapter (or Mock for testing)
library;

import 'dart:io';

import 'package:flutter/foundation.dart';
import '../interfaces/rfid_reader.dart';
import '../adapters/gpio_spi_rfid_adapter.dart';
import '../adapters/mock_rfid_adapter.dart';

enum PlatformType {
  /// Raspberry Pi (Linux on ARM) with GPIO/SPI
  raspberryPi,
  
  /// Mock for testing
  mock,
  
  /// Unknown/unsupported platform
  unknown,
}

/// Detects the current platform type
class PlatformDetector {
  /// Detect platform based on OS and architecture
  static PlatformType detectPlatform({bool forceMock = false}) {
    if (forceMock) {
      return PlatformType.mock;
    }

    if (kIsWeb) {
      return PlatformType.unknown;
    }

    if (Platform.isLinux) {
      // Check if running on ARM (Raspberry Pi)
      if (_isRaspberryPi()) {
        return PlatformType.raspberryPi;
      }
    }

    return PlatformType.unknown;
  }

  /// Check if running on Raspberry Pi
  /// 
  /// Checks /proc/cpuinfo for BCM or Raspberry Pi identifiers
  static bool _isRaspberryPi() {
    try {
      final cpuInfo = File('/proc/cpuinfo');
      if (!cpuInfo.existsSync()) {
        return false;
      }

      final content = cpuInfo.readAsStringSync().toLowerCase();
      
      // Check for Raspberry Pi specific markers
      return content.contains('raspberry pi') ||
             content.contains('bcm2') || // BCM2835, BCM2836, BCM2837, BCM2711
             content.contains('hardware	: bcm');
             
    } catch (e) {
      debugPrint('Error detecting Raspberry Pi: $e');
      return false;
    }
  }

  /// Get platform display name
  static String getPlatformName(PlatformType platform) {
    switch (platform) {
      case PlatformType.raspberryPi:
        return 'Raspberry Pi (GPIO/SPI)';
      case PlatformType.mock:
        return 'Mock (Testing)';
      case PlatformType.unknown:
        return 'Unknown Platform';
    }
  }
}

/// Factory for creating RFID reader managers based on platform
class RFIDReaderFactory {
  /// Create appropriate RFID reader manager for current platform
  /// 
  /// [forcePlatform] - Override automatic detection (useful for testing)
  /// [mockScenario] - Scenario for mock adapter ('full_meal', 'partial', etc.)
  static RFIDReaderManager createReaderManager({
    PlatformType? forcePlatform,
    String mockScenario = 'full_meal',
  }) {
    final platform = forcePlatform ?? PlatformDetector.detectPlatform();
    
    debugPrint('Creating RFID reader manager for platform: ${PlatformDetector.getPlatformName(platform)}');

    switch (platform) {
      case PlatformType.raspberryPi:
        return _createGPIOReaderManager();
        
      case PlatformType.mock:
        return _createMockReaderManager(mockScenario);
        
      case PlatformType.unknown:
        debugPrint('Unknown platform, falling back to mock readers');
        return _createMockReaderManager(mockScenario);
    }
  }

  /// Create GPIO/SPI RFID reader manager (Raspberry Pi)
  static RFIDReaderManager _createGPIOReaderManager() {
    debugPrint('Initializing GPIO/SPI RFID readers');
    
    // Use default configuration (7 RC522 modules)
    return GPIOSPIRFIDReaderManager(
      configs: GPIOSPIRFIDReaderManager.defaultConfigs,
    );
  }

  /// Create Mock RFID reader manager (Testing)
  static RFIDReaderManager _createMockReaderManager(String scenario) {
    debugPrint('Initializing Mock RFID readers (scenario: $scenario)');
    return MockRFIDReaderManager(scenario: scenario);
  }

  /// Create custom GPIO reader manager with specific pin configuration
  static RFIDReaderManager createCustomGPIOReaderManager(
    List<RC522Config> configs,
  ) {
    debugPrint('Initializing custom GPIO/SPI RFID readers (${configs.length} modules)');
    return GPIOSPIRFIDReaderManager(configs: configs);
  }
}

/// Configuration options for RFID reader creation
class RFIDReaderConfig {
  /// Force a specific platform (overrides auto-detection)
  final PlatformType? forcePlatform;
  
  /// Mock scenario for testing ('full_meal', 'partial', 'errors', 'empty')
  final String mockScenario;
  
  /// Custom GPIO configurations for Raspberry Pi
  final List<RC522Config>? customGPIOConfigs;

  const RFIDReaderConfig({
    this.forcePlatform,
    this.mockScenario = 'full_meal',
    this.customGPIOConfigs,
  });

  /// Create reader manager from this configuration
  RFIDReaderManager createManager() {
    RFIDReaderManager manager;

    if (customGPIOConfigs != null && 
        (forcePlatform == PlatformType.raspberryPi || 
         PlatformDetector.detectPlatform() == PlatformType.raspberryPi)) {
      manager = RFIDReaderFactory.createCustomGPIOReaderManager(
        customGPIOConfigs!,
      );
    } else {
      manager = RFIDReaderFactory.createReaderManager(
        forcePlatform: forcePlatform,
        mockScenario: mockScenario,
      );
    }

    return manager;
  }
}
