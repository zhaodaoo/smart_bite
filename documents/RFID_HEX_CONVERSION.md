# RFID UID to Hex Conversion

## Overview

All RFID adapters now convert UID data to 8-character uppercase hex strings **immediately upon reading**, matching the Arduino `printHex` function behavior. This ensures data type consistency across all reading methods.

## Arduino printHex Reference

```cpp
void printHex(byte *buffer, byte bufferSize) {
  for (byte i = 0; i < bufferSize; i++) {
    Serial.print(buffer[i] < 0x10 ? "0" : "");  // Add leading zero if needed
    Serial.print(buffer[i], HEX);                // Print as hex
  }
}
```

## Flutter Implementation

### SimpleMFRC522._uidToHex()

```dart
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
```

## Conversion Examples

| UID Bytes | Hex String | Use Case |
|-----------|------------|----------|
| `[0xA2, 0x20, 0x38, 0xF6]` | `A22038F6` | Standard meal card |
| `[0xF2, 0x58, 0x38, 0xF6]` | `F25838F6` | Meal ID from database |
| `[0x72, 0x73, 0x38, 0xF6]` | `727338F6` | Meal ID from database |
| `[0x08, 0x04, 0xF9, 0xE3]` | `0804F9E3` | Serial reader example |
| `[0x88, 0x04, 0xF9, 0xE3]` | `8804F9E3` | Serial reader example |
| `[0x00, 0x00, 0x00, 0x00]` | `00000000` | All zeros (edge case) |
| `[0xFF, 0xFF, 0xFF, 0xFF]` | `FFFFFFFF` | All ones (edge case) |

## Data Flow

### GPIO/SPI RFID Reader (Raspberry Pi)

```
RC522 Hardware
    ↓ (SPI)
MFRC522.anticoll()
    ↓ (List<int> uid)
SimpleMFRC522._uidToHex()
    ↓ (String hex)
RFIDPollingService.performOneLoopCycles()
    ↓ (List<String> tagIds)
GPIOSPIRFIDReaderManager.scanAll()
    ↓ (List<RFIDReading>)
Application
```

**Key Point**: Conversion happens at `SimpleMFRC522._uidToHex()` - as soon as UID bytes are read from hardware.

### Serial RFID Reader (Arduino)

```
RC522 Hardware
    ↓ (SPI)
Arduino printHex()
    ↓ (Serial: "01OK8804F9E3")
USB Serial Port
    ↓
SerialRFIDAdapter._parseSerialData()
    ↓ (String rfid: "8804F9E3")
Application
```

**Key Point**: Arduino already converts to hex before sending. No conversion needed in Flutter.

### Mock RFID Reader (Testing)

```
Pre-configured hex strings
    ↓
MockRFIDAdapter.scan()
    ↓ (String rfid: "A22038F6")
Application
```

**Key Point**: Mock data already in correct hex format. No conversion needed.

## Format Specification

### Valid Format
- **Pattern**: `^[0-9A-F]{8}$`
- **Length**: Exactly 8 characters
- **Characters**: Uppercase hexadecimal (0-9, A-F)
- **Leading zeros**: Required (e.g., `0804F9E3`, not `804F9E3`)

### Examples
- ✅ `A22038F6` - Valid
- ✅ `0804F9E3` - Valid (with leading zeros)
- ✅ `FFFFFFFF` - Valid
- ❌ `a22038f6` - Invalid (lowercase)
- ❌ `A22038F` - Invalid (7 chars)
- ❌ `0xA22038F6` - Invalid (prefix)

## Benefits

1. **Single Conversion Point**: Data is converted once at the source, eliminating redundant conversions
2. **Type Consistency**: All adapters return `String` in the same format
3. **Arduino Compatibility**: Matches the proven Arduino implementation
4. **Database Ready**: Format matches meal IDs in database (`id_to_meal.dart`)
5. **Easy Debugging**: Human-readable hex strings instead of large integers

## Testing

Run unit tests to verify conversion logic:

```bash
flutter test test/unit/simple_mfrc522_test.dart
```

All tests verify:
- Byte array to hex conversion
- Leading zero padding
- Uppercase formatting
- 8-character length
- Match with Arduino printHex behavior

## Modified Files

1. `lib/services/simple_mfrc522.dart`
   - Changed `_uidToNum()` to `_uidToHex()`
   - Changed `_tagId` type from `int?` to `String?`
   - Changed `readIdNoBlock()` return type from `Future<int?>` to `Future<String?>`

2. `lib/services/rfid_polling_service.dart`
   - Changed `performOneLoopCycles()` return type from `Future<List<int>>` to `Future<List<String>>`
   - Updated internal set type from `Set<int>` to `Set<String>`

3. `lib/adapters/gpio_spi_rfid_adapter.dart`
   - Removed `_tagIdToHex()` method (no longer needed)
   - Updated `scanAll()` to use hex strings directly from service

4. `lib/adapters/serial_rfid_adapter.dart`
   - ✅ Already uses hex format (no changes needed)

5. `lib/adapters/mock_rfid_adapter.dart`
   - ✅ Already uses hex format (no changes needed)

## Date
Created: 2025-12-16
