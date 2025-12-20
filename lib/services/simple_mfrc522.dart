import 'package:dart_periphery/dart_periphery.dart';
import 'mfrc522.dart';
import 'mfrc522_constants.dart';

/// Simplified MFRC522 interface for reading RFID tag IDs
class SimpleMFRC522 {
  final int deviceNum;
  final int spiNum;
  final int rstPin;
  
  MFRC522? _reader;
  String? _tagId;
  late GPIO _rstGpio;

  SimpleMFRC522({
    required this.deviceNum,
    required this.spiNum,
    required this.rstPin,
  }) {
    // Power-down the reader to reset it
    // 只設定 GPIO 為 OUTPUT，不做其他操作
    _rstGpio = GPIO(rstPin, GPIOdirection.gpioDirOut);
  }

  String? get tagId => _tagId;

  /// Initialize the RFID reader
  Future<void> initReader() async {
    // 建立 MFRC522 物件但不透過建構子設定 RST (因為我們已經在外部設定了)
    // 這裡需要直接建立並初始化
    _reader = MFRC522.withoutGpioInit(spiDevice: spiNum, resetPin: rstPin, rstGpio: _rstGpio);
    await _reader!.init();
    _tagId = null;
    await Future.delayed(const Duration(milliseconds: 500));  // 等待讀卡器初始化完成
  }

  /// Reset the reader
  Future<void> resetReader() async {
    _tagId = null;
    if (_reader != null) {
      _reader!.disposeWithoutGpio();  // 只清理 SPI，不清理 GPIO
      _reader = null;
    }
    
    _rstGpio.write(false);  // GPIO.LOW - 關閉讀卡器
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Read tag ID in non-blocking mode
  Future<String?> readIdNoBlock() async {
    try {
      await initReader();

      // Request card
      final requestResult = _reader!.request(PICCCommands.reqidl);
      if (requestResult.status != MFRC522Status.ok) {
        await resetReader();
        return null;
      }

      // Anti-collision
      final anticollResult = _reader!.anticoll();
      if (anticollResult.status != MFRC522Status.ok) {
        await resetReader();
        return null;
      }

      await resetReader();
      _tagId = _uidToHex(anticollResult.uid);
      return _tagId;
    } catch (e) {
      await resetReader();
      return null;
    }
  }

  /// Convert UID bytes to hex string (matching Arduino printHex behavior)
  /// Converts first 4 bytes of UID to 8-character uppercase hex string
  /// Example: [0xA2, 0x20, 0x38, 0xF6] -> "A22038F6"
  String _uidToHex(List<int> uid) {
    final buffer = StringBuffer();
    // Use first 4 bytes to create 8-character hex string
    for (int i = 0; i < 4 && i < uid.length; i++) {
      // Convert each byte to 2-character hex with leading zero if needed
      buffer.write(uid[i].toRadixString(16).toUpperCase().padLeft(2, '0'));
    }
    return buffer.toString();
  }

  /// Dispose resources
  Future<void> dispose() async {
    await resetReader();
    _rstGpio.dispose();
  }
}
