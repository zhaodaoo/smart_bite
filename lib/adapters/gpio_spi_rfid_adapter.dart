/// GPIO/SPI RFID Adapter for Raspberry Pi
/// 
/// Implements direct communication with RC522 RFID modules via SPI interface.
/// Supports the hardware topology where 7 RC522 modules share:
/// - Common SPI bus pins: MISO (GPIO 9), MOSI (GPIO 10), SCK (GPIO 11)
/// - Unique control pins per module: RST and SDA/SS (Slave Select)
/// 
/// Hardware Reference: https://wiki.keyestudio.com/Ks0205_Keyestudio_RC522_Sensor
/// 
/// MFRC522 Protocol: ISO14443A (13.56 MHz RFID)
library;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../interfaces/rfid_reader.dart';

/// Configuration for a single RC522 module on the shared SPI bus
class RC522Config {
  /// Device identifier (e.g., "01", "02", ... "07")
  final String deviceId;
  
  /// SPI device path (e.g., "/dev/spidev0.0")
  final String spiDevice;
  
  /// GPIO pin number for RST (Reset) - unique per module
  final int rstPin;
  
  /// GPIO pin number for SDA/SS (Slave Select) - unique per module
  final int ssPin;
  
  const RC522Config({
    required this.deviceId,
    required this.spiDevice,
    required this.rstPin,
    required this.ssPin,
  });

  @override
  String toString() => 'RC522Config(id: $deviceId, spi: $spiDevice, rst: $rstPin, ss: $ssPin)';
}

/// MFRC522 Register Addresses (partial - commonly used)
class MFRC522Registers {
  // Command and status
  static const int commandReg = 0x01;
  static const int comIEnReg = 0x02;
  static const int comIrqReg = 0x04;
  static const int errorReg = 0x06;
  static const int status2Reg = 0x08;
  
  // FIFO
  static const int fifoDataReg = 0x09;
  static const int fifoLevelReg = 0x0A;
  
  // Control
  static const int controlReg = 0x0C;
  static const int bitFramingReg = 0x0D;
  
  // Mode
  static const int modeReg = 0x11;
  static const int txControlReg = 0x14;
  static const int txAutoReg = 0x15;
  
  // Timer
  static const int timerReloadReg = 0x2C;
  static const int timerModeReg = 0x2A;
  
  // Version
  static const int versionReg = 0x37;
}

/// MFRC522 Commands
class MFRC522Commands {
  static const int idle = 0x00;
  static const int transceive = 0x0C;
  static const int softreset = 0x0F;
}

/// PICC (Proximity Integrated Circuit Card) Commands (ISO14443A)
class PICCCommands {
  static const int reqidl = 0x26; // Request command, Type A (REQA)
  static const int anticoll = 0x93; // Anti-collision
}

/// GPIO/SPI RFID Adapter for RC522 modules on Raspberry Pi
class GPIOSPIRFIDAdapter implements RFIDReader {
  final RC522Config _config;
  
  ReaderStatus _status = ReaderStatus.init;
  
  final StreamController<RFIDReading> _readingsController = 
      StreamController<RFIDReading>.broadcast();

  GPIOSPIRFIDAdapter({
    required RC522Config config,
  })  : _config = config;

  @override
  String get deviceId => _config.deviceId;

  @override
  String get address => '${_config.spiDevice} (RST:${_config.rstPin}, SS:${_config.ssPin})';

  @override
  ReaderStatus get status => _status;

  @override
  Stream<RFIDReading> get readings => _readingsController.stream;

  @override
  bool get isConnected => _status != ReaderStatus.init && _status != ReaderStatus.disconnected;

  @override
  Future<void> connect() async {
    try {
      // Initialize GPIO pins
      await _initializeGPIO(_config.rstPin, 'rst');
      await _initializeGPIO(_config.ssPin, 'ss');
      
      // Reset the RC522 module
      await _resetModule();
      
      // Initialize the MFRC522 chip
      await _initializeMFRC522();
      
      _status = ReaderStatus.ok;
      debugPrint('[$address] GPIO/SPI reader connected');
      
    } catch (e) {
      _status = ReaderStatus.error;
      debugPrint('[$address] Failed to connect: $e');
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _status = ReaderStatus.disconnected;
    
    // Unexport GPIO pins
    await _cleanupGPIO(_config.rstPin);
    await _cleanupGPIO(_config.ssPin);
    
    await _readingsController.close();
    debugPrint('[$address] GPIO/SPI reader disconnected');
  }

  @override
  Future<RFIDReading> scan() async {
    _status = ReaderStatus.updating;
    
    try {
      // Activate antenna
      await _setAntennaOn();
      
      // Request card presence (REQA command)
      final cardPresent = await _requestCard();
      
      if (!cardPresent) {
        // No card detected
        final reading = RFIDReading(
          deviceId: _config.deviceId,
          status: ReaderStatus.ok,
          rfid: '',
          timestamp: DateTime.now(),
          rawData: 'NO_CARD',
        );
        
        _status = ReaderStatus.ok;
        _readingsController.add(reading);
        return reading;
      }
      
      // Card detected, read UID
      final uid = await _readCardUID();
      
      if (uid == null || uid.isEmpty) {
        final reading = RFIDReading.error(
          _config.deviceId,
          'Failed to read card UID',
        );
        _status = ReaderStatus.error;
        _readingsController.add(reading);
        return reading;
      }
      
      // Convert UID to hex string (8 characters)
      final rfidHex = _uidToHexString(uid);
      
      final reading = RFIDReading.success(_config.deviceId, rfidHex);
      _status = ReaderStatus.ok;
      _readingsController.add(reading);
      
      debugPrint('[$address] Read RFID: $rfidHex');
      return reading;
      
    } catch (e) {
      final reading = RFIDReading.error(
        _config.deviceId,
        'Scan error: $e',
      );
      _status = ReaderStatus.error;
      _readingsController.add(reading);
      return reading;
    }
  }

  // ========== GPIO Management ==========

  Future<void> _initializeGPIO(int pin, String label) async {
    try {
      // Export GPIO pin via sysfs
      final exportFile = File('/sys/class/gpio/export');
      if (await exportFile.exists()) {
        await exportFile.writeAsString('$pin\n');
        
        // Wait for GPIO to be exported
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Set direction to output
        final directionFile = File('/sys/class/gpio/gpio$pin/direction');
        await directionFile.writeAsString('out\n');
        
        debugPrint('[$address] Initialized GPIO $pin ($label)');
      }
    } catch (e) {
      // GPIO might already be exported, try to continue
      debugPrint('[$address] GPIO $pin init warning: $e');
    }
  }

  Future<void> _cleanupGPIO(int pin) async {
    try {
      final unexportFile = File('/sys/class/gpio/unexport');
      if (await unexportFile.exists()) {
        await unexportFile.writeAsString('$pin\n');
      }
    } catch (e) {
      debugPrint('[$address] GPIO $pin cleanup warning: $e');
    }
  }

  Future<void> _setGPIO(int pin, bool value) async {
    try {
      final valueFile = File('/sys/class/gpio/gpio$pin/value');
      await valueFile.writeAsString(value ? '1\n' : '0\n');
    } catch (e) {
      debugPrint('[$address] GPIO $pin set error: $e');
    }
  }

  // ========== SPI Communication ==========

  Future<void> _spiWrite(int register, int value) async {
    // SPI write: address byte with MSB=0, followed by data byte
    // This is a placeholder - actual implementation needs SPI library
    // In production, use packages like 'dart_periphery' or native extensions
    
    debugPrint('[$address] SPI Write: reg=0x${register.toRadixString(16)}, val=0x${value.toRadixString(16)}');
    
    // TODO: Implement actual SPI communication
    // Example using dart_periphery:
    // final spi = SPI(_config.spiDevice, 0, 1000000);
    // final txBuf = Uint8List.fromList([(register << 1) & 0x7E, value]);
    // spi.transfer(txBuf, rxBuf);
  }

  Future<int> _spiRead(int register) async {
    // SPI read: address byte with MSB=1, followed by reading data byte
    // This is a placeholder - actual implementation needs SPI library
    
    debugPrint('[$address] SPI Read: reg=0x${register.toRadixString(16)}');
    
    // TODO: Implement actual SPI communication
    // Example using dart_periphery:
    // final spi = SPI(_config.spiDevice, 0, 1000000);
    // final txBuf = Uint8List.fromList([((register << 1) & 0x7E) | 0x80, 0x00]);
    // final rxBuf = spi.transfer(txBuf);
    // return rxBuf[1];
    
    return 0; // Placeholder
  }

  // ========== MFRC522 Protocol ==========

  Future<void> _resetModule() async {
    // Hardware reset via RST pin
    await _setGPIO(_config.rstPin, false);
    await Future.delayed(const Duration(milliseconds: 50));
    await _setGPIO(_config.rstPin, true);
    await Future.delayed(const Duration(milliseconds: 50));
    
    debugPrint('[$address] Module reset complete');
  }

  Future<void> _initializeMFRC522() async {
    // Software reset
    await _spiWrite(MFRC522Registers.commandReg, MFRC522Commands.softreset);
    await Future.delayed(const Duration(milliseconds: 50));
    
    // Configure timer
    await _spiWrite(MFRC522Registers.timerModeReg, 0x8D);
    await _spiWrite(MFRC522Registers.timerReloadReg, 0x3E);
    
    // Configure TX
    await _spiWrite(MFRC522Registers.txAutoReg, 0x40);
    
    // Configure mode
    await _spiWrite(MFRC522Registers.modeReg, 0x3D);
    
    // Read version to verify communication
    final version = await _spiRead(MFRC522Registers.versionReg);
    debugPrint('[$address] MFRC522 version: 0x${version.toRadixString(16)}');
  }

  Future<void> _setAntennaOn() async {
    final current = await _spiRead(MFRC522Registers.txControlReg);
    if ((current & 0x03) != 0x03) {
      await _spiWrite(MFRC522Registers.txControlReg, current | 0x03);
    }
  }

  Future<bool> _requestCard() async {
    // Send REQA command to detect card presence
    // This is simplified - actual implementation needs full MFRC522 protocol
    
    // TODO: Implement full PICC_REQA command sequence
    // 1. Clear FIFO
    // 2. Write REQA command to FIFO
    // 3. Execute Transceive command
    // 4. Wait for IRQ
    // 5. Check response (ATQA - Answer To Request A)
    
    debugPrint('[$address] Requesting card presence...');
    
    // Placeholder: simulate card detection
    // In production, this checks for ATQA response
    return false; // TODO: Return actual card presence status
  }

  Future<Uint8List?> _readCardUID() async {
    // Anti-collision loop to read card UID
    // ISO14443A: UID can be 4, 7, or 10 bytes
    
    // TODO: Implement full anti-collision protocol
    // 1. Send ANTICOLL command
    // 2. Receive UID cascade levels
    // 3. Verify BCC (Block Check Character)
    // 4. Return complete UID
    
    debugPrint('[$address] Reading card UID...');
    
    // Placeholder: return mock UID for testing
    // In production, this performs anti-collision and returns actual UID
    return null; // TODO: Return actual UID bytes
  }

  String _uidToHexString(Uint8List uid) {
    // Convert UID bytes to 8-character hex string
    // If UID is 4 bytes, use all 4 bytes (8 hex chars)
    // If UID is 7+ bytes, use first 4 bytes
    
    final buffer = StringBuffer();
    final length = uid.length >= 4 ? 4 : uid.length;
    
    for (int i = 0; i < length; i++) {
      buffer.write(uid[i].toRadixString(16).toUpperCase().padLeft(2, '0'));
    }
    
    return buffer.toString();
  }
}

/// GPIO/SPI RFID Reader Manager for Raspberry Pi
class GPIOSPIRFIDReaderManager extends ChangeNotifier implements RFIDReaderManager {
  List<GPIOSPIRFIDAdapter> _readers = [];
  double _scanTimeout = 2.0;
  final Map<String, RFIDReading> _latestReadings = {};

  /// Default configuration for 7 RC522 modules on Raspberry Pi
  /// 
  /// Shared SPI bus: /dev/spidev0.0 (MISO=GPIO9, MOSI=GPIO10, SCK=GPIO11)
  /// Unique pins per module:
  /// - Module 1: RST=GPIO17, SS=GPIO8
  /// - Module 2: RST=GPIO27, SS=GPIO7
  /// - Module 3: RST=GPIO22, SS=GPIO25
  /// - Module 4: RST=GPIO23, SS=GPIO24
  /// - Module 5: RST=GPIO18, SS=GPIO12
  /// - Module 6: RST=GPIO15, SS=GPIO16
  /// - Module 7: RST=GPIO14, SS=GPIO20
  static List<RC522Config> get defaultConfigs => [
    const RC522Config(deviceId: '01', spiDevice: '/dev/spidev0.0', rstPin: 17, ssPin: 8),
    const RC522Config(deviceId: '02', spiDevice: '/dev/spidev0.0', rstPin: 27, ssPin: 7),
    const RC522Config(deviceId: '03', spiDevice: '/dev/spidev0.0', rstPin: 22, ssPin: 25),
    const RC522Config(deviceId: '04', spiDevice: '/dev/spidev0.0', rstPin: 23, ssPin: 24),
    const RC522Config(deviceId: '05', spiDevice: '/dev/spidev0.0', rstPin: 18, ssPin: 12),
    const RC522Config(deviceId: '06', spiDevice: '/dev/spidev0.0', rstPin: 15, ssPin: 16),
    const RC522Config(deviceId: '07', spiDevice: '/dev/spidev0.0', rstPin: 14, ssPin: 20),
  ];

  GPIOSPIRFIDReaderManager({List<RC522Config>? configs}) {
    final readerConfigs = configs ?? defaultConfigs;
    _readers = readerConfigs
        .map((config) => GPIOSPIRFIDAdapter(
              config: config,
            ))
        .toList();
  }

  @override
  List<RFIDReader> get readers => _readers;

  @override
  double get scanTimeout => _scanTimeout;

  @override
  set scanTimeout(double seconds) {
    _scanTimeout = seconds;
    notifyListeners();
  }

  @override
  Future<void> discoverReaders() async {
    // GPIO readers are pre-configured, just connect them
    for (final reader in _readers) {
      try {
        await reader.connect();
      } catch (e) {
        debugPrint('Failed to connect reader ${reader.deviceId}: $e');
      }
    }
    notifyListeners();
  }

  @override
  Future<List<RFIDReading>> scanAll() async {
    // Scan readers sequentially (shared SPI bus requires sequential access)
    final readings = <RFIDReading>[];
    
    for (final reader in _readers) {
      try {
        final reading = await reader.scan();
        readings.add(reading);
        _latestReadings[reading.deviceId] = reading;
      } catch (e) {
        debugPrint('Error scanning reader ${reader.deviceId}: $e');
        final errorReading = RFIDReading.error(reader.deviceId, e.toString());
        readings.add(errorReading);
        _latestReadings[reader.deviceId] = errorReading;
      }
    }

    notifyListeners();
    return readings;
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
    for (final reader in _readers) {
      reader.disconnect();
    }
    _readers.clear();
    _latestReadings.clear();
    super.dispose();
  }
}
