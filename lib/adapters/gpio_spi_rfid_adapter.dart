/// GPIO/SPI RFID Adapter for Raspberry Pi
/// 
/// Implements direct communication with RC522 RFID modules via SPI interface.
/// Uses the proven working implementation from read_multi_rfid.
/// 
/// Hardware Reference: https://wiki.keyestudio.com/Ks0205_Keyestudio_RC522_Sensor
/// 
/// MFRC522 Protocol: ISO14443A (13.56 MHz RFID)
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../interfaces/rfid_reader.dart';
import '../models/rfid_models.dart';
import '../services/rfid_polling_service.dart';

/// Configuration for a single RC522 module on the shared SPI bus
class RC522Config {
  /// Device identifier (e.g., "01", "02", ... "07")
  final String deviceId;
  
  /// SPI bus number (e.g., 0 for /dev/spidev0.0)
  final int spiNum;
  
  /// GPIO pin number for RST (Reset) - unique per module
  final int rstPin;
  
  const RC522Config({
    required this.deviceId,
    required this.spiNum,
    required this.rstPin,
  });

  /// Convert to ReaderConfig for use with RFIDPollingService
  ReaderConfig toReaderConfig(int deviceNum) {
    return ReaderConfig(
      deviceNum: deviceNum,
      spiNum: spiNum,
      rstPin: rstPin,
    );
  }

  @override
  String toString() => 'RC522Config(id: $deviceId, spi: $spiNum, rst: $rstPin)';
}

/// GPIO/SPI RFID Reader Manager for Raspberry Pi
/// 
/// Uses the button-triggered list-return pattern from read_multi_rfid
class GPIOSPIRFIDReaderManager extends ChangeNotifier implements RFIDReaderManager {
  final List<RC522Config> _configs;
  final Map<String, RFIDReading> _latestReadings = {};

  /// Default configuration for 7 RC522 modules on Raspberry Pi
  /// 
  /// Shared SPI bus: /dev/spidev0.0 (MISO=GPIO9, MOSI=GPIO10, SCK=GPIO11)
  /// Unique RST pins per module (matching working implementation):
  /// - Reader 1: RST=GPIO22
  /// - Reader 2: RST=GPIO27
  /// - Reader 3: RST=GPIO17
  /// - Reader 4: RST=GPIO4
  /// - Reader 5: RST=GPIO23
  /// - Reader 6: RST=GPIO24
  /// - Reader 7: RST=GPIO25
  static List<RC522Config> get defaultConfigs => [
    const RC522Config(deviceId: '01', spiNum: 0, rstPin: 22),
    const RC522Config(deviceId: '02', spiNum: 0, rstPin: 27),
    const RC522Config(deviceId: '03', spiNum: 0, rstPin: 17),
    const RC522Config(deviceId: '04', spiNum: 0, rstPin: 4),
    const RC522Config(deviceId: '05', spiNum: 0, rstPin: 23),
    const RC522Config(deviceId: '06', spiNum: 0, rstPin: 24),
    const RC522Config(deviceId: '07', spiNum: 0, rstPin: 25),
  ];

  GPIOSPIRFIDReaderManager({List<RC522Config>? configs})
      : _configs = configs ?? defaultConfigs;

  @override
  List<RFIDReader> get readers {
    // Return virtual readers based on configs
    return _configs.map((config) {
      final reading = _latestReadings[config.deviceId];
      return _VirtualRFIDReader(
        deviceId: config.deviceId,
        status: reading?.status ?? ReaderStatus.init,
        address: 'SPI${config.spiNum}.0/GPIO${config.rstPin}',
      );
    }).toList();
  }

  @override
  Future<void> discoverReaders() async {
    // No persistent connections in button-triggered mode
    // Readers are created fresh for each scan
    debugPrint('GPIO/SPI readers configured: ${_configs.length} readers');
    notifyListeners();
  }

  @override
  Future<List<RFIDReading>> scanAll() async {
    debugPrint('Starting async scan of ${_configs.length} readers...');
    
    try {
      // Convert configs to serializable format for isolate
      final configsData = _configs
          .asMap()
          .entries
          .map((entry) => {
                'deviceNum': entry.key + 1,
                'spiNum': entry.value.spiNum,
                'rstPin': entry.value.rstPin,
              })
          .toList();
      
      // Perform scan on background isolate to avoid UI blocking
      final tagIds = await compute(_performScanInIsolate, configsData);
      
      debugPrint('Scan complete. Found ${tagIds.length} unique tags: $tagIds');
      
      // Convert tag IDs to RFIDReading objects (on main thread)
      final readings = <RFIDReading>[];
      _latestReadings.clear();
      
      // Create readings for each configured reader
      for (int i = 0; i < _configs.length; i++) {
        final config = _configs[i];
        
        // Check if this reader detected a tag
        final hasTag = i < tagIds.length;
        
        final reading = hasTag
            ? RFIDReading.success(
                config.deviceId,
                tagIds[i],  // Already in hex format from SimpleMFRC522
              )
            : RFIDReading(
                deviceId: config.deviceId,
                status: ReaderStatus.ok,
                rfid: '',
                timestamp: DateTime.now(),
                rawData: 'NO_CARD',
              );
        
        readings.add(reading);
        _latestReadings[config.deviceId] = reading;
      }
      
      notifyListeners();
      return readings;
      
    } catch (e) {
      debugPrint('Error during scan: $e');
      
      // Return error readings for all readers
      final errorReadings = _configs
          .map((config) => RFIDReading.error(config.deviceId, e.toString()))
          .toList();
      
      for (final reading in errorReadings) {
        _latestReadings[reading.deviceId] = reading;
      }
      
      notifyListeners();
      return errorReadings;
    }
  }

  /// Static method for isolate execution (no instance state access)
  /// Enhanced with timeout protection and comprehensive error recovery
  static Future<List<String>> _performScanInIsolate(List<Map<String, int>> configsData) async {
    // Create ReaderConfig objects from serialized data
    final readerConfigs = configsData
        .map((data) => ReaderConfig(
              deviceNum: data['deviceNum']!,
              spiNum: data['spiNum']!,
              rstPin: data['rstPin']!,
            ))
        .toList();
    
    // Perform the actual GPIO operations with timeout protection
    final pollingService = RFIDPollingService();
    try {
      // Add timeout to prevent isolate from hanging indefinitely
      return await pollingService
          .performOneLoopCycles(readerConfigs)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('⚠️  RFID scan timeout in isolate, disposing resources');
              pollingService.dispose();
              throw TimeoutException('RFID scan timeout after 30 seconds');
            },
          );
    } catch (e) {
      debugPrint('❌ Error in isolate scan: $e');
      pollingService.dispose();
      rethrow;
    } finally {
      // Ensure disposal even if timeout handler didn't execute
      pollingService.dispose();
    }
  }

  @override
  RFIDReading? getReading(String deviceId) {
    return _latestReadings[deviceId];
  }

  @override
  List<RFIDReading> get validReadings {
    return _latestReadings.values
        .where((reading) => reading.hasCard)
        .toList();
  }

  @override
  void dispose() {
    _latestReadings.clear();
    super.dispose();
  }
}

/// Virtual RFID reader for status display
/// Used by GPIOSPIRFIDReaderManager to provide reader information
/// without maintaining persistent connections
class _VirtualRFIDReader implements RFIDReader {
  @override
  final String deviceId;
  
  @override
  final ReaderStatus status;
  
  @override
  final String address;

  _VirtualRFIDReader({
    required this.deviceId,
    required this.status,
    required this.address,
  });

  @override
  Stream<RFIDReading> get readings => const Stream.empty();

  @override
  Future<void> connect() async {
    throw UnimplementedError('Virtual reader does not support connection');
  }

  @override
  Future<void> disconnect() async {
    throw UnimplementedError('Virtual reader does not support disconnection');
  }

  @override
  Future<RFIDReading> scan() async {
    throw UnimplementedError('Virtual reader does not support direct scanning');
  }

  @override
  bool get isConnected => false;
}
