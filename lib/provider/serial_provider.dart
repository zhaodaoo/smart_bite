import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

enum PortStatus {init, updating, ok, error}

double currentLoadingTime = 10;

class SerialPortsProvider extends ChangeNotifier {
  List<MySerialPort> _availablePorts = SerialPort.availablePorts.map((address)=>MySerialPort(address: address)).toList();
  double _loadingTime = currentLoadingTime;
  List<String> orderNames = [];

  // Getter
  List<MySerialPort> get availablePorts => _availablePorts;
  double get loadingTime => _loadingTime;

  set loadingTime(double newTime) {
    _loadingTime = newTime;
    currentLoadingTime = newTime;
    notifyListeners();
  }

  Future<void> readFromPort(MySerialPort port) async{
    port.status = PortStatus.updating;
    notifyListeners();

    await port.read();
    notifyListeners();
  }

  Future<void> updatePorts() async{
    _availablePorts.clear();
    _availablePorts = SerialPort.availablePorts.map((address)=>MySerialPort(address: address)).toList();
    notifyListeners();

    await Future.wait(
      _availablePorts.map(
        (port) async => await readFromPort(port)
      )
    );
    notifyListeners();
  }
}

class MySerialPort {
  final String address;
  
  MySerialPort({required this.address});

  

  // Private variables
  PortStatus status = PortStatus.init;
  String _id = '--';
  String _rfid = '';
  String _strBuffer = 'Init';

  // Getter
  String get deviceId => _id;
  String get rfid => _rfid; 

  // Methods
  void _onInit () {
    status = PortStatus.init;
    _id = '--';
    _rfid = '';
    _strBuffer = 'Init';
  }

  void _onError () {
    status = PortStatus.error;
    _id = '--';
    _rfid = '';
    _strBuffer = 'Error';
  }
  
  void _onUpdating () {
    final match = RegExp(r'(\d{2})(OK)([0-9A-F]{8})?', multiLine: true, dotAll: true).firstMatch(_strBuffer);
    if (match != null) {
      debugPrint('Dectected results DeviceID="${match[1]}", Status="${match[2]}", RFID="${match[3]}"');
      _id = match[1] ?? '--';
      status = match[2]=='OK'? PortStatus.ok:PortStatus.error;
      _rfid = match[3] ?? '';
    } else {
      _onError ();
    }
  }

  Future<void> read() async{
    SerialPort port = SerialPort(address);

    if (port.openRead()) {
      // Configure the serial port
      SerialPortConfig config = port.config; 
      config.baudRate = 9600;   
      config.bits = 8;
      config.parity = 0;
      config.stopBits = 1;
      port.config = config;

      Stream<Uint8List> upcomingData = SerialPortReader(port, timeout: 10000).stream;
      
      
      try {
        List<int> buffer = [];
        final subscription = upcomingData.listen((data) => buffer.addAll(data));
        await Future.delayed(Duration(seconds: currentLoadingTime.round()), () async{
          await subscription.cancel();
          port.close();

          _strBuffer = String.fromCharCodes(buffer);
          debugPrint('[$address][debug] $buffer');
          _onUpdating();
          debugPrint('[$address][info] $_strBuffer');
        });
      } on SerialPortError catch (err, _) {
        _strBuffer = SerialPort.lastError.toString();
        port.close();
        await Future.delayed(const Duration(seconds: 1));
        _onError();
        debugPrint('[$address][error] $_strBuffer');
      }
      
    } else {
      port.close();
      await Future.delayed(const Duration(seconds: 1));
      _onInit();
      debugPrint('[$address][error] Failed to open the port.');
    }
  }
}
