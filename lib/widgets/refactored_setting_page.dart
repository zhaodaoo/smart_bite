/// Platform-Specific Settings Screen
/// 
/// Displays different configuration options based on the platform:
/// - Serial: Port addresses, baud rate, scan timeout
/// - GPIO/SPI: Pin configurations, SPI settings
/// - Mock: Test scenario selection
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/rfid_reader_provider.dart';
import '../provider/data_provider.dart';
import '../interfaces/rfid_reader.dart';
import '../utils/platform_detector.dart';

class RefactoredSettingPage extends StatelessWidget {
  const RefactoredSettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Row(
          children: [
            // Left column: RFID Reader Settings
            Expanded(
              child: _buildReaderSettingsColumn(context),
            ),
            
            // Right column: Printer and Other Settings
            Expanded(
              child: _buildPrinterSettingsColumn(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReaderSettingsColumn(BuildContext context) {
    final rfidProvider = context.watch<RFIDReaderProvider>();

    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Platform Info
        _buildPlatformInfo(context),
        
        // Scan Timeout Slider
        _buildScanTimeoutSlider(context, rfidProvider),
        
        // Reader Status Cards
        _buildReaderStatusSection(context, rfidProvider),
        
        // Refresh Button
        _buildRefreshButton(context, rfidProvider),
      ],
    );
  }

  Widget _buildPlatformInfo(BuildContext context) {
    final platform = PlatformDetector.detectPlatform();
    final platformName = PlatformDetector.getPlatformName(platform);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Platform',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getPlatformIcon(platform),
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  platformName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPlatformIcon(PlatformType platform) {
    switch (platform) {
      case PlatformType.raspberryPi:
        return Icons.developer_board;
      case PlatformType.desktop:
        return Icons.usb;
      case PlatformType.mock:
        return Icons.science;
      case PlatformType.unknown:
        return Icons.help_outline;
    }
  }

  Widget _buildScanTimeoutSlider(
    BuildContext context,
    RFIDReaderProvider provider,
  ) {
    return Column(
      children: [
        Text(
          'RFID Scan Timeout',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
          child: Slider(
            value: provider.scanTimeout,
            max: 20,
            min: 1,
            divisions: 19,
            label: '${provider.scanTimeout.round()}s',
            onChanged: (double value) {
              provider.scanTimeout = value;
            },
          ),
        ),
        Text(
          '${provider.scanTimeout.round()} seconds',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildReaderStatusSection(
    BuildContext context,
    RFIDReaderProvider provider,
  ) {
    return Column(
      children: [
        Text(
          'RFID Readers Status',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        
        // Statistics
        _buildReaderStats(context, provider),
        
        const SizedBox(height: 16),
        
        // Reader cards
        Center(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.readers
                  .map((reader) => _ReaderStatusCard(
                        deviceId: reader.deviceId,
                        status: reader.status,
                        address: reader.address,
                      ))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReaderStats(
    BuildContext context,
    RFIDReaderProvider provider,
  ) {
    final statusSummary = provider.getReaderStatusSummary();

    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              label: 'Total',
              value: provider.readerCount.toString(),
              icon: Icons.devices,
            ),
            _StatItem(
              label: 'OK',
              value: (statusSummary['ok'] ?? 0).toString(),
              icon: Icons.check_circle,
              color: Colors.green,
            ),
            _StatItem(
              label: 'Errors',
              value: (statusSummary['error'] ?? 0).toString(),
              icon: Icons.error,
              color: Colors.red,
            ),
            _StatItem(
              label: 'Cards',
              value: provider.validCardCount.toString(),
              icon: Icons.credit_card,
              color: Colors.blue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton(
    BuildContext context,
    RFIDReaderProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
      child: FilledButton.icon(
        onPressed: provider.isScanning
            ? null
            : () async {
                await provider.updateReaders();
              },
        icon: provider.isScanning
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh),
        label: Text(provider.isScanning ? 'Scanning...' : 'Scan RFID Readers'),
      ),
    );
  }

  Widget _buildPrinterSettingsColumn(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextFormField(
            initialValue: context.read<DataProvider>().printerName,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Printer Name',
            ),
            onChanged: (value) {
              context.read<DataProvider>().printerName = value;
            },
          ),
          // Add more printer settings as needed
        ],
      ),
    );
  }
}

/// Widget for displaying individual reader status
class _ReaderStatusCard extends StatelessWidget {
  final String deviceId;
  final ReaderStatus status;
  final String address;

  const _ReaderStatusCard({
    required this.deviceId,
    required this.status,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: status.color,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reader $deviceId',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              status.displayName,
              style: TextStyle(
                color: status.color,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getShortAddress(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon() {
    switch (status) {
      case ReaderStatus.ok:
        return Icons.check_circle;
      case ReaderStatus.error:
        return Icons.error;
      case ReaderStatus.updating:
        return Icons.refresh;
      case ReaderStatus.init:
        return Icons.radio_button_unchecked;
      case ReaderStatus.disconnected:
        return Icons.cloud_off;
    }
  }

  String _getShortAddress() {
    // Shorten address for display
    if (address.contains('/dev/')) {
      return address.split('/').last;
    }
    if (address.contains('MOCK')) {
      return 'Mock';
    }
    if (address.contains('GPIO')) {
      return 'GPIO';
    }
    return address;
  }
}

/// Stat item widget
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
