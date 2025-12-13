/// Serial RFID Adapter
/// 
/// Wraps the existing Arduino + USB Serial RFID reading logic
/// into the RFIDReader interface for compatibility with the abstraction layer.
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';
import '../interfaces/rfid_reader.dart';

/// Adapter for reading RC522 RFID modules via Arduino + USB Serial
class SerialRFIDAdapter implements RFIDReader {
  final String _address;
  final double _scanTimeout;
  
  ReaderStatus _status = ReaderStatus.init;
  String _deviceId = '--';
  
  final StreamController<RFIDReading> _readingsController = 
      StreamController<RFIDReading>.broadcast();
  
  SerialRFIDAdapter({
    required String address,
    double scanTimeout = 10.0,
  })  : _address = address,
        _scanTimeout = scanTimeout;

  @override
  String get address => _address;

  @override
  String get deviceId => _deviceId;

  @override
  ReaderStatus get status => _status;

  @override
  Stream<RFIDReading> get readings => _readingsController.stream;

  @override
  bool get isConnected => _status != ReaderStatus.init && _status != ReaderStatus.disconnected;

  @override
  Future<void> connect() async {
    // Serial connection is handled on-demand during scan
    _status = ReaderStatus.init;
  }

  @override
  Future<void> disconnect() async {
    _status = ReaderStatus.disconnected;
    await _readingsController.close();
  }

  @override
  Future<RFIDReading> scan() async {
    _status = ReaderStatus.updating;
    
    SerialPort? port;
    try {
      port = SerialPort(_address);
      
      if (!port.openRead()) {
        debugPrint('[$_address][error] Failed to open the port.');
        final reading = RFIDReading.error(_deviceId, 'Failed to open port');
        _status = ReaderStatus.error;
        _readingsController.add(reading);
        return reading;
      }

      // Configure the serial port
      SerialPortConfig config = port.config;
      config.baudRate = 9600;
      config.bits = 8;
      config.parity = 0;
      config.stopBits = 1;
      port.config = config;

      Stream<Uint8List> upcomingData = SerialPortReader(port, timeout: 10000).stream;

      // Read data with timeout
      List<int> buffer = [];
      final subscription = upcomingData.listen((data) => buffer.addAll(data));
      
      await Future.delayed(Duration(seconds: _scanTimeout.round()), () async {
        await subscription.cancel();
        port?.close();
      });

      // Parse the received data
      String rawData = String.fromCharCodes(buffer);
      debugPrint('[$_address][debug] $buffer');
      
      final reading = _parseSerialData(rawData);
      _status = reading.status;
      _deviceId = reading.deviceId;
      
      debugPrint('[$_address][info] $rawData');
      _readingsController.add(reading);
      
      return reading;
      
    } on SerialPortError catch (err, _) {
      final errorMsg = SerialPort.lastError.toString();
      debugPrint('[$_address][error] $errorMsg');
      
      final reading = RFIDReading.error(_deviceId, errorMsg);
      _status = ReaderStatus.error;
      _readingsController.add(reading);
      
      return reading;
      
    } finally {
      port?.close();
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Parse serial data according to the protocol: (\d{2})(OK)([0-9A-F]{8})?
  /// 
  /// Expected format examples:
  /// - "01OK8804F9E3" → Device 01, Status OK, RFID 8804F9E3
  /// - "02OKA22038F6" → Device 02, Status OK, RFID A22038F6
  /// - "03OK" → Device 03, Status OK, No card detected
  /// - "04ERROR" → Device 04, Error state
  RFIDReading _parseSerialData(String rawData) {
    final match = RegExp(
      r'(\d{2})(OK)([0-9A-F]{8})?',
      multiLine: true,
      dotAll: true,
    ).firstMatch(rawData);

    if (match != null) {
      final deviceId = match[1] ?? '--';
      final statusStr = match[2];
      final rfid = match[3] ?? '';

      debugPrint('Detected results DeviceID="$deviceId", Status="$statusStr", RFID="$rfid"');

      if (statusStr == 'OK') {
        return RFIDReading(
          deviceId: deviceId,
          status: ReaderStatus.ok,
          rfid: rfid,
          timestamp: DateTime.now(),
          rawData: rawData,
        );
      } else {
        return RFIDReading.error(
          deviceId,
          'Reader returned error status',
        );
      }
    } else {
      // Failed to parse
      return RFIDReading.error(
        _deviceId,
        'Failed to parse serial data: $rawData',
      );
    }
  }
}

/// Manager for multiple Serial RFID readers
class SerialRFIDReaderManager extends ChangeNotifier implements RFIDReaderManager {
  List<SerialRFIDAdapter> _readers = [];
  double _scanTimeout = 10.0;
  final Map<String, RFIDReading> _latestReadings = {};

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
    // Discover all available serial ports
    final availablePorts = SerialPort.availablePorts;
    
    _readers = availablePorts
        .map((address) => SerialRFIDAdapter(
              address: address,
              scanTimeout: _scanTimeout,
            ))
        .toList();
    
    debugPrint('Discovered ${_readers.length} serial ports');
    notifyListeners();
  }

  @override
  Future<List<RFIDReading>> scanAll() async {
    if (_readers.isEmpty) {
      await discoverReaders();
    }

    // Scan all readers in parallel
    final readings = await Future.wait(
      _readers.map((reader) => reader.scan()),
    );

    // Update latest readings cache
    for (final reading in readings) {
      _latestReadings[reading.deviceId] = reading;
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
