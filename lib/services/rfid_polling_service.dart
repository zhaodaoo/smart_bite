import '../models/rfid_models.dart';
import 'simple_mfrc522.dart';

/// RFID polling service for button-triggered reading
class RFIDPollingService {
  /// Perform one reading cycle through all readers
  /// Collects unique tag IDs and returns them as a list
  Future<List<String>> performTwoLoopCycles(List<ReaderConfig> configs) async {
    final Set<String> uniqueTags = {};
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
      for (int cycle = 0; cycle < 1; cycle++) {
        for (var reader in readers) {
          try {
            // Attempt to read tag ID
            final tagId = await reader.readIdNoBlock();
            
            // Add to set if tag was detected (automatically handles duplicates)
            if (tagId != null) {
              uniqueTags.add(tagId);
            }
          } catch (e) {
            // Log error but continue to next reader
            print('Error reading reader ${reader.deviceNum} in cycle ${cycle + 1}: $e');
          }
        }
      }
    } finally {
      // Final cleanup - dispose all readers to release GPIO pins
      for (var reader in readers) {
        try {
          await reader.dispose();
        } catch (e) {
          print('Error disposing reader ${reader.deviceNum}: $e');
        }
      }
      
      // Add a small delay to ensure hardware stabilization
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Convert set to sorted list for consistent display
    final tagList = uniqueTags.toList()..sort();
    return tagList;
  }
  
  /// Dispose resources (kept for compatibility)
  void dispose() {
    // No persistent resources to dispose in button-triggered mode
  }
}
