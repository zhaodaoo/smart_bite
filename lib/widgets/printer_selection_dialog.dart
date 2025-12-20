import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:smart_bite/services/printer_service.dart';

/// Dialog for selecting a printer from available system printers.
///
/// Features:
/// - Lists all available printers on the system
/// - Marks the default printer (first in list)
/// - Allows user to select a printer
/// - Returns the selected printer's name/URL
class PrinterSelectionDialog extends StatefulWidget {
  final String? currentPrinterName;

  const PrinterSelectionDialog({
    super.key,
    this.currentPrinterName,
  });

  @override
  State<PrinterSelectionDialog> createState() => _PrinterSelectionDialogState();
}

class _PrinterSelectionDialogState extends State<PrinterSelectionDialog> {
  List<Printer> _printers = [];
  bool _isLoading = true;
  String? _selectedPrinterUrl;
  Printer? _defaultPrinter;

  @override
  void initState() {
    super.initState();
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    setState(() => _isLoading = true);

    try {
      final printers = await PrinterService.getAvailablePrinters();
      final defaultPrinter = await PrinterService.getDefaultPrinter();

      setState(() {
        _printers = printers;
        _defaultPrinter = defaultPrinter;
        _isLoading = false;

        // Pre-select current printer if it exists in the list
        if (widget.currentPrinterName != null) {
          final matchingPrinter = printers
              .where((p) =>
                  p.name == widget.currentPrinterName ||
                  p.url == widget.currentPrinterName)
              .firstOrNull;

          if (matchingPrinter != null) {
            _selectedPrinterUrl = matchingPrinter.url;
          }
        }

        // If no printer is pre-selected, select the default printer
        if (_selectedPrinterUrl == null && defaultPrinter != null) {
          _selectedPrinterUrl = defaultPrinter.url;
        }
      });
    } catch (e) {
      debugPrint('❌ Error loading printers: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.print, color: Colors.blue, size: 28),
          SizedBox(width: 12),
          Text('選擇印表機', style: TextStyle(fontSize: 22)),
        ],
      ),
      content: SizedBox(
        width: 500,
        height: 400,
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在掃描印表機...'),
                  ],
                ),
              )
            : _printers.isEmpty
                ? _buildNoPrintersView()
                : _buildPrintersList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消', style: TextStyle(fontSize: 16)),
        ),
        FilledButton(
          onPressed: _selectedPrinterUrl == null
              ? null
              : () => Navigator.of(context).pop(_selectedPrinterUrl),
          child: const Text('確認', style: TextStyle(fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildNoPrintersView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.print_disabled, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            '找不到可用的印表機',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '請確認印表機已正確安裝並連接到系統',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadPrinters,
            icon: const Icon(Icons.refresh),
            label: const Text('重新掃描'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrintersList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_defaultPrinter != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '系統預設印表機: ${_defaultPrinter!.name}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[900],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const Text(
          '可用的印表機:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _printers.length,
            itemBuilder: (context, index) {
              final printer = _printers[index];
              final isDefault = _defaultPrinter?.url == printer.url;
              final isSelected = _selectedPrinterUrl == printer.url;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: isSelected ? 2 : 0,
                color: isSelected ? Colors.blue[50] : null,
                child: RadioListTile<String>(
                  value: printer.url,
                  groupValue: _selectedPrinterUrl,
                  onChanged: (value) {
                    setState(() => _selectedPrinterUrl = value);
                  },
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          printer.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '預設',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  subtitle: printer.url != printer.name
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            printer.url,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton.icon(
              onPressed: _loadPrinters,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重新掃描', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows the printer selection dialog.
///
/// Returns the selected printer's URL/name, or null if cancelled.
Future<String?> showPrinterSelectionDialog(
  BuildContext context, {
  String? currentPrinterName,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PrinterSelectionDialog(
      currentPrinterName: currentPrinterName,
    ),
  );
}
