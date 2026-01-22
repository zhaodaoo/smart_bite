import 'package:flutter/material.dart';

import '../models/rfid_models.dart';
import 'simple_mfrc522.dart';

/// RFID polling service for button-triggered reading
class RFIDPollingService {
  /// Perform one reading cycle through all readers
  /// Returns a map of deviceId to tag ID (or null if no card)
  Future<Map<String, String?>> performOneLoopCycles(
      List<ReaderConfig> configs) async {
    final Map<String, String?> readerResults = {};
    final List<SimpleMFRC522> readers = [];

    try {
      // Create reader instances once (this initializes GPIO pins)
      for (var config in configs) {
        readers.add(SimpleMFRC522(
          deviceNum: config.deviceNum,
          spiNum: config.spiNum,
          rstPin: config.rstPin,
        ));
      }

      // Run 1 complete cycle through all readers
      for (int i = 0; i < readers.length; i++) {
        final reader = readers[i];
        final config = configs[i];
        // Generate deviceId from config ("01", "02", etc.)
        final deviceId = config.deviceNum.toString().padLeft(2, '0');

        try {
          // Attempt to read tag ID
          final tagId = await reader.readIdNoBlock();

          // Store result for this specific reader (null if no card)
          readerResults[deviceId] = tagId;
        } catch (e) {
          // Log error but continue to next reader
          debugPrint('Error reading reader $deviceId: $e');
          readerResults[deviceId] = null;
        }
      }
    } finally {
      // Final cleanup - dispose all readers to release GPIO pins
      for (var reader in readers) {
        try {
          await reader.dispose();
        } catch (e) {
          debugPrint('Error disposing reader ${reader.deviceNum}: $e');
        }
      }

      // Add a small delay to ensure hardware stabilization
      await Future.delayed(const Duration(milliseconds: 500));
    }

    // Return map with deviceId -> tagId associations
    debugPrint('Scan results: $readerResults');
    return readerResults;
  }

  /// Dispose resources (kept for compatibility)
  void dispose() {
    // No persistent resources to dispose in button-triggered mode
  }
}
