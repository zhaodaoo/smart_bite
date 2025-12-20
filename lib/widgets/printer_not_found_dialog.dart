import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_bite/widgets/setting_page.dart';

/// Dialog displayed when the configured printer is not found on the system.
///
/// Features:
/// - Shows the current configured printer name
/// - Allows copying the printer name to clipboard
/// - Provides three action buttons:
///   1. Exit app - Closes the app to let user configure system printer
///   2. Settings - Opens app settings to change configured printer name
///   3. Cancel - Returns to current page without analyzing/printing
class PrinterNotFoundDialog extends StatelessWidget {
  final String configuredPrinterName;

  const PrinterNotFoundDialog({
    super.key,
    required this.configuredPrinterName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 32),
          SizedBox(width: 12),
          Text('找不到印表機', style: TextStyle(fontSize: 24)),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '系統找不到已設定的印表機。請確認印表機已正確安裝並設定。',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            const Text(
              '已設定的印表機名稱:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[400]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: SelectableText(
                      configuredPrinterName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: '複製印表機名稱',
                  onPressed: () {
                    Clipboard.setData(
                      ClipboardData(text: configuredPrinterName),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('已複製印表機名稱到剪貼簿'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '💡 解決方法:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. 點擊「離開應用程式」，前往系統設定安裝印表機',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '2. 確保系統印表機名稱與上方設定的名稱完全相同',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '3. 或點擊「設定」修改應用程式的印表機名稱',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Cancel button
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(fontSize: 16),
          ),
        ),
        // Settings button
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            // Open settings page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingPage(),
              ),
            );
          },
          icon: const Icon(Icons.settings),
          label: const Text(
            '設定',
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        // Exit app button
        ElevatedButton.icon(
          onPressed: () {
            exit(0); // Exit the application
          },
          icon: const Icon(Icons.exit_to_app),
          label: const Text(
            '離開應用程式',
            style: TextStyle(fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

/// Shows the printer not found dialog.
///
/// Returns a Future that completes when the dialog is dismissed.
Future<void> showPrinterNotFoundDialog(
  BuildContext context,
  String configuredPrinterName,
) {
  return showDialog(
    context: context,
    barrierDismissible: false, // Prevent dismissing by tapping outside
    builder: (context) => PrinterNotFoundDialog(
      configuredPrinterName: configuredPrinterName,
    ),
  );
}
