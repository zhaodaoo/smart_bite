import 'dart:typed_data';
import 'package:dart_periphery/dart_periphery.dart';
import 'mfrc522_constants.dart';

/// Low-level MFRC522 RFID reader interface using SPI communication
class MFRC522 {
  final SPI _spi;
  final GPIO _resetPin;
  final bool _ownGpio;  // 標記是否擁有 GPIO
  
  MFRC522({required int spiDevice, required int resetPin})
      : _spi = SPI(spiDevice, 0, SPImode.mode0, 1000000),
        _resetPin = GPIO(resetPin, GPIOdirection.gpioDirOut),
        _ownGpio = true;

  /// 使用外部已設定好的 GPIO
  MFRC522.withoutGpioInit({
    required int spiDevice,
    required int resetPin,
    required GPIO rstGpio,
  })  : _spi = SPI(spiDevice, 0, SPImode.mode0, 1000000),
        _resetPin = rstGpio,
        _ownGpio = false;

  /// Write a byte to a register
  void writeRegister(int register, int value) {
    final address = ((register << 1) & 0x7E);
    final data = Uint8List.fromList([address, value]);
    _spi.transfer(data, true);
  }

  /// Read a byte from a register
  int readRegister(int register) {
    final address = ((register << 1) & 0x7E) | 0x80;
    final data = Uint8List.fromList([address, 0]);
    final response = _spi.transfer(data, true);
    return response[1];
  }

  /// Set register bits
  void setBitMask(int register, int mask) {
    final current = readRegister(register);
    writeRegister(register, current | mask);
  }

  /// Clear register bits
  void clearBitMask(int register, int mask) {
    final current = readRegister(register);
    writeRegister(register, current & (~mask));
  }

  /// Reset the MFRC522
  void reset() {
    writeRegister(MFRC522Registers.commandReg, MFRC522Commands.softReset);
  }

  /// Initialize the MFRC522
  Future<void> init() async {
    // Hardware reset
    _resetPin.write(true);
    await Future.delayed(const Duration(milliseconds: 50));
    _resetPin.write(false);
    await Future.delayed(const Duration(milliseconds: 50));
    _resetPin.write(true);
    await Future.delayed(const Duration(milliseconds: 50));

    // Soft reset
    reset();
    
    // Timer: TPrescaler*TreloadVal/6.78MHz = 24ms
    writeRegister(MFRC522Registers.tModeReg, 0x8D);
    writeRegister(MFRC522Registers.tPrescalerReg, 0x3E);
    writeRegister(MFRC522Registers.tReloadRegL, 30);
    writeRegister(MFRC522Registers.tReloadRegH, 0);

    // Force 100% ASK modulation
    writeRegister(MFRC522Registers.txASKReg, 0x40);
    
    // Set CRC preset value to 0x6363
    writeRegister(MFRC522Registers.modeReg, 0x3D);
    
    // Enable antenna
    antennaOn();
  }

  /// Turn on the antenna
  void antennaOn() {
    final current = readRegister(MFRC522Registers.txControlReg);
    if ((current & 0x03) != 0x03) {
      setBitMask(MFRC522Registers.txControlReg, 0x03);
    }
  }

  /// Turn off the antenna
  void antennaOff() {
    clearBitMask(MFRC522Registers.txControlReg, 0x03);
  }

  /// Communicate with PICC
  ({int status, List<int> backData, int backLen}) communicate(
    int command,
    List<int> sendData,
  ) {
    List<int> backData = [];
    int backLen = 0;
    int status = MFRC522Status.error;
    int irqEn = 0x00;
    int waitIRq = 0x00;

    if (command == MFRC522Commands.mfAuthent) {
      irqEn = 0x12;
      waitIRq = 0x10;
    } else if (command == MFRC522Commands.transceive) {
      irqEn = 0x77;
      waitIRq = 0x30;
    }

    writeRegister(MFRC522Registers.comIEnReg, irqEn | 0x80);
    clearBitMask(MFRC522Registers.comIrqReg, 0x80);
    setBitMask(MFRC522Registers.fifoLevelReg, 0x80);
    writeRegister(MFRC522Registers.commandReg, MFRC522Commands.idle);

    // Write data to FIFO
    for (var data in sendData) {
      writeRegister(MFRC522Registers.fifoDataReg, data);
    }

    // Execute command
    writeRegister(MFRC522Registers.commandReg, command);
    if (command == MFRC522Commands.transceive) {
      setBitMask(MFRC522Registers.bitFramingReg, 0x80);
    }

    // Wait for completion
    int i = 2000;
    int n;
    while (true) {
      n = readRegister(MFRC522Registers.comIrqReg);
      i--;
      if (i == 0 || (n & 0x01) != 0 || (n & waitIRq) != 0) {
        break;
      }
    }

    clearBitMask(MFRC522Registers.bitFramingReg, 0x80);

    if (i != 0) {
      if ((readRegister(MFRC522Registers.errorReg) & 0x1B) == 0x00) {
        status = MFRC522Status.ok;

        if ((n & irqEn & 0x01) != 0) {
          status = MFRC522Status.notag;
        }

        if (command == MFRC522Commands.transceive) {
          n = readRegister(MFRC522Registers.fifoLevelReg);
          final lastBits = readRegister(MFRC522Registers.controlReg) & 0x07;
          
          if (lastBits != 0) {
            backLen = (n - 1) * 8 + lastBits;
          } else {
            backLen = n * 8;
          }

          if (n == 0) {
            n = 1;
          }
          if (n > 16) {
            n = 16;
          }

          backData = List<int>.generate(
            n,
            (i) => readRegister(MFRC522Registers.fifoDataReg),
          );
        }
      } else {
        status = MFRC522Status.error;
      }
    }

    return (status: status, backData: backData, backLen: backLen);
  }

  /// Request card
  ({int status, List<int> backBits}) request(int reqMode) {
    writeRegister(MFRC522Registers.bitFramingReg, 0x07);
    final result = communicate(MFRC522Commands.transceive, [reqMode]);
    
    if (result.status != MFRC522Status.ok || result.backLen != 0x10) {
      return (status: MFRC522Status.error, backBits: []);
    }

    return (status: result.status, backBits: result.backData);
  }

  /// Anti-collision detection
  ({int status, List<int> uid}) anticoll() {
    writeRegister(MFRC522Registers.bitFramingReg, 0x00);
    final sendData = [PICCCommands.anticoll, 0x20];
    final result = communicate(MFRC522Commands.transceive, sendData);

    if (result.status == MFRC522Status.ok) {
      if (result.backData.length == 5) {
        // Verify checksum
        int checksum = 0;
        for (int i = 0; i < 4; i++) {
          checksum ^= result.backData[i];
        }
        if (checksum != result.backData[4]) {
          return (status: MFRC522Status.error, uid: []);
        }
        return (status: MFRC522Status.ok, uid: result.backData);
      } else {
        return (status: MFRC522Status.error, uid: []);
      }
    }

    return (status: result.status, uid: []);
  }

  /// Dispose resources
  void dispose() {
    antennaOff();
    _spi.dispose();
    if (_ownGpio) {
      _resetPin.dispose();
    }
  }

  /// Dispose resources without disposing GPIO (for external GPIO management)
  void disposeWithoutGpio() {
    antennaOff();
    _spi.dispose();
  }
}
