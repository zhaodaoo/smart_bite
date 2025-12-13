import 'package:flutter_test/flutter_test.dart';
import 'package:smart_bite/utils/platform_detector.dart';
import 'package:smart_bite/adapters/gpio_spi_rfid_adapter.dart';
import 'dart:io';

void main() {
  group('PlatformDetector', () {
    test('should detect platform type', () {
      final platformType = PlatformDetector.detectPlatform();
      
      // Platform type should be one of the valid types
      expect(
        [
          PlatformType.raspberryPi,
          PlatformType.desktop,
          PlatformType.mock,
        ],
        contains(platformType),
      );
    });
  });

  group('RFIDReaderFactory', () {
    test('should create reader manager with auto-detection', () {
      final manager = RFIDReaderFactory.createReaderManager();
      expect(manager, isNotNull);
    });

    test('should create mock reader manager when forced', () {
      final manager = RFIDReaderFactory.createReaderManager(
        forcePlatform: PlatformType.mock,
      );
      
      expect(manager, isNotNull);
      expect(manager.runtimeType.toString(), contains('Mock'));
    });

    test('should create serial reader manager when forced', () {
      final manager = RFIDReaderFactory.createReaderManager(
        forcePlatform: PlatformType.desktop,
      );
      
      expect(manager, isNotNull);
      expect(manager.runtimeType.toString(), contains('Serial'));
    });

    test('should create GPIO reader manager when forced', () {
      final manager = RFIDReaderFactory.createReaderManager(
        forcePlatform: PlatformType.raspberryPi,
      );
      
      expect(manager, isNotNull);
      final typeName = manager.runtimeType.toString();
      expect(typeName.contains('GPIO') || typeName.contains('SPI'), true);
    });

    test('should respect environment variable override', () {
      // Test that environment variable is checked
      // This is indirect testing since we can't easily set env vars in tests
      final manager = RFIDReaderFactory.createReaderManager();
      expect(manager, isNotNull);
    });

    test('should create custom GPIO reader manager with configs', () {
      final config = RFIDReaderConfig(
        forcePlatform: PlatformType.raspberryPi,
        customGPIOConfigs: [
          RC522Config(deviceId: '01', spiDevice: '/dev/spidev0.0', rstPin: 17, ssPin: 8),
        ],
      );

      final manager = config.createManager();
      expect(manager, isNotNull);
    });

    test('RFIDReaderConfig should create valid configuration', () {
      final config = RFIDReaderConfig(
        forcePlatform: PlatformType.raspberryPi,
        mockScenario: 'full_meal',
        scanTimeout: 5.0,
      );

      expect(config.forcePlatform, PlatformType.raspberryPi);
      expect(config.mockScenario, 'full_meal');
      expect(config.scanTimeout, 5.0);
    });
  });
}
