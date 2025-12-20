/// Refactored Order Page Widget
/// 
/// Uses the abstracted RFIDReaderProvider for hardware-agnostic RFID reading.
/// This widget demonstrates the GPIO/SPI-based RFID implementation.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/rfid_reader_provider.dart';
import '../provider/data_provider.dart';
import '../interfaces/rfid_reader.dart';

/// Order card widget for displaying detected meal
class OrderCard extends StatelessWidget {
  final ReaderStatus status;
  final String mealName;
  final double width;

  const OrderCard({
    super.key,
    required this.status,
    required this.mealName,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.1),
        border: Border.all(color: status.color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getStatusIcon(status),
                color: status.color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                status.displayName,
                style: TextStyle(
                  color: status.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            mealName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(ReaderStatus status) {
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
}

/// Refactored OrderPage using RFIDReaderProvider
class RefactoredOrderPage extends StatelessWidget {
  final void Function() onGoBack;
  final void Function() onSubmit;

  const RefactoredOrderPage({
    super.key,
    required this.onGoBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const _HeadLine('5.這是您點的餐：'),
        
        // Meal display section
        Padding(
          padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
          child: _buildMealDisplay(context),
        ),

        // Action buttons
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildMealDisplay(BuildContext context) {
    final isScanning = context.select<RFIDReaderProvider, bool>(
      (provider) => provider.isScanning,
    );

    if (isScanning) {
      return const CircularProgressIndicator.adaptive();
    }

    final orderNames = context.select<RFIDReaderProvider, List<String>>(
      (provider) => provider.orderNames,
    );

    if (orderNames.isEmpty) {
      return const OrderCard(
        width: 390,
        status: ReaderStatus.init,
        mealName: '沒收到您的點餐，是不知道要吃什麼嗎？可以請服務人員為您推薦！',
      );
    }

    return Wrap(
      spacing: 8,
      direction: Axis.horizontal,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: orderNames
          .map((mealName) => OrderCard(
                status: ReaderStatus.ok,
                mealName: mealName,
              ))
          .toList(),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _SubmitButton(
          onPressed: onGoBack,
          label: '返回',
        ),
        const SizedBox(width: 22),
        _SubmitButton(
          onPressed: () async {
            await context.read<RFIDReaderProvider>().updateReaders();
          },
          label: '重新感應',
        ),
        const SizedBox(width: 22),
        _SubmitButton(
          onPressed: () {
            // Transfer order data to DataProvider
            final orderNames = context.read<RFIDReaderProvider>().orderNames;
            context.read<DataProvider>().orderNames = orderNames;
            onSubmit();
          },
          label: '確認',
        ),
      ],
    );
  }
}

// Helper widgets (assuming these exist in input_screen.dart)
class _HeadLine extends StatelessWidget {
  final String text;

  const _HeadLine(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;

  const _SubmitButton({
    required this.onPressed,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
