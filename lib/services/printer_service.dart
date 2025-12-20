import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Service for checking printer availability and related operations.
class PrinterService {
  /// Checks if a printer with the specified name is available on the system.
  ///
  /// Returns true if the printer is found, false otherwise.
  ///
  /// The check is performed by querying all available printers using the
  /// printing package and comparing their names/URLs with the target printer name.
  static Future<bool> isPrinterAvailable(String printerName) async {
    try {
      debugPrint('🔍 Checking if printer "$printerName" is available...');

      // Get list of all available printers
      final printers = await Printing.listPrinters();

      debugPrint('📋 Found ${printers.length} printer(s) on system');
      for (final printer in printers) {
        debugPrint('  - ${printer.name} (${printer.url})');
      }

      // Check if any printer matches the configured name
      // Match against both name and url (url is used in Printer constructor)
      final found = printers.any((printer) {
        return printer.name == printerName || printer.url == printerName;
      });

      if (found) {
        debugPrint('✓ Printer "$printerName" is available');
      } else {
        debugPrint('❌ Printer "$printerName" not found on system');
      }

      return found;
    } catch (e) {
      debugPrint('❌ Error checking printer availability: $e');
      // Treat errors as printer not available
      return false;
    }
  }

  /// Gets a list of all available printers on the system.
  ///
  /// Returns an empty list if no printers are available or an error occurs.
  static Future<List<Printer>> getAvailablePrinters() async {
    try {
      final printers = await Printing.listPrinters();
      debugPrint('📋 Retrieved ${printers.length} available printer(s)');
      return printers;
    } catch (e) {
      debugPrint('❌ Error listing printers: $e');
      return [];
    }
  }

  /// Prints a PDF to the specified printer.
  ///
  /// Throws an exception if:
  /// - The printer is not found
  /// - PDF generation fails
  /// - Printing operation fails
  ///
  /// Returns true if printing was initiated successfully.
  static Future<bool> printPdf({
    required String printerName,
    required PdfPageFormat format,
    required Future<Uint8List> Function(PdfPageFormat) onLayout,
    bool usePrinterSettings = true,
  }) async {
    try {
      debugPrint('🖨 Starting print job to "$printerName"...');

      // Check printer availability first
      if (!await isPrinterAvailable(printerName)) {
        throw PrinterNotFoundException(
          'Printer "$printerName" not found on system',
        );
      }

      // Proceed with printing
      await Printing.directPrintPdf(
        printer: Printer(url: printerName),
        format: format,
        usePrinterSettings: usePrinterSettings,
        onLayout: onLayout,
      );

      debugPrint('✓ Print job sent successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Print job failed: $e');
      rethrow;
    }
  }
}

/// Exception thrown when a configured printer is not found on the system.
class PrinterNotFoundException implements Exception {
  final String message;

  PrinterNotFoundException(this.message);

  @override
  String toString() => 'PrinterNotFoundException: $message';
}
