import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:smart_bite/data/optimized_indexes.dart';
import 'package:smart_bite/provider/data_provider.dart';
import 'package:smart_bite/provider/rfid_reader_provider.dart';
import 'package:smart_bite/screens/input_screen.dart';
import 'package:smart_bite/services/data_persistence_service.dart';
import 'package:smart_bite/utils/platform_detector.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load critical data for optimal performance
  // Initialize optimized indexes for dishes and nutrition data
  // This improves RFID scanning and nutrition analysis performance by 40-50%
  String? csvError;
  try {
    await initializeOptimizedIndexes();
  } catch (e) {
    csvError = e.toString();
    debugPrint('❌ CSV loading failed: $csvError');
  }

  // Pre-load PDF background images to fix first print job missing background bug
  await _preloadPDFAssets();

  // Must add this line.
  await windowManager.ensureInitialized();

  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(1280, 720));
    WindowManager.instance.setMaximumSize(const Size(3840, 2160));
  }

  // Use it only after calling `hiddenWindowAtLaunch`
  windowManager.waitUntilReadyToShow().then((_) async {
    // Hide window title bar
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
    await windowManager.setFullScreen(true);
    await windowManager.center();
    await windowManager.show();
    await windowManager.setSkipTaskbar(false);
  });
  
  // Run app with error handling
  runApp(MyApp(csvError: csvError));
}

/// Preloads PDF background images at app startup to prevent missing background
/// on first print job.
///
/// This function uses warm-up captureFromWidget() calls to force the screenshot
/// rendering pipeline to load and cache the background images. The issue occurs
/// because captureFromWidget() creates an isolated rendering context with its own
/// image cache, separate from the main UI's ImageCache.
Future<void> _preloadPDFAssets() async {
  ScreenshotController? controller;
  try {
    debugPrint('🔄 Starting PDF assets preloading...');
    
    // Import is available at the top
    controller = ScreenshotController();
    
    // Create dummy widgets with both background images to warm up the cache
    final warmupWidget1 = Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/printing_layout_1.png"),
          fit: BoxFit.contain,
        ),
      ),
    );
    
    final warmupWidget2 = Container(
      width: 100,
      height: 100,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/printing_layout_2.png"),
          fit: BoxFit.contain,
        ),
      ),
    );
    
    // Execute warm-up captures to load images into screenshot pipeline's cache
    // Use low resolution and longer delay to ensure images are fully loaded
    await controller.captureFromWidget(
      warmupWidget1,
      pixelRatio: 0.1,
      targetSize: const Size(100, 100),
      delay: const Duration(seconds: 3),
    );
    
    await controller.captureFromWidget(
      warmupWidget2,
      pixelRatio: 0.1,
      targetSize: const Size(100, 100),
      delay: const Duration(seconds: 3),
    );
    
    debugPrint('✓ PDF background images preloaded successfully');
  } catch (e) {
    // Non-fatal: Log warning but don't block app startup
    debugPrint('⚠ Failed to preload PDF assets: $e');
  }
  // Note: ScreenshotController doesn't require explicit disposal
  // It only manages a GlobalKey which is garbage collected automatically
  // The ui.Image objects are disposed within captureFromWidget()
}

class MyApp extends StatelessWidget {
  final String? csvError;

  const MyApp({super.key, this.csvError});

  @override
  Widget build(BuildContext context) {
    // If CSV loading failed, show error screen
    if (csvError != null) {
      return MaterialApp(
        title: 'Smart Bite!',
        theme: ThemeData(
          fontFamily: 'NotoSansCJK',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          useMaterial3: true,
        ),
        home: _CsvErrorScreen(error: csvError!),
      );
    }

    // Normal app flow
    // Detect platform and create appropriate RFID reader manager
    // Use environment variable RFID_MODE to override: 'gpio' or 'mock'
    final rfidMode = Platform.environment['RFID_MODE'];
    PlatformType? forcePlatform;

    if (rfidMode == 'gpio') {
      forcePlatform = PlatformType.raspberryPi;
    } else if (rfidMode == 'mock') {
      forcePlatform = PlatformType.mock;
    }

    final readerManager = RFIDReaderFactory.createReaderManager(
      forcePlatform: forcePlatform,
    );

    return MultiProvider(
      providers: [
        // RFID reader provider (GPIO/SPI on Raspberry Pi)
        ChangeNotifierProvider(
          create: (context) => RFIDReaderProvider(
            readerManager: readerManager,
          ),
        ),
        ChangeNotifierProvider(create: (context) => DataProvider()),
      ],
      child: MaterialApp(
        title: 'Smart Bite!',
        theme: ThemeData(
          fontFamily: 'NotoSansCJK',
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          useMaterial3: true,
        ),
        home: const InputScreen(),
      ),
    );
  }
}

/// Error screen shown when CSV file loading fails
class _CsvErrorScreen extends StatelessWidget {
  final String error;

  const _CsvErrorScreen({required this.error});

  Future<String> _getCsvPath() async {
    try {
      return await DataPersistenceService.loadDishesInfoCsvPath();
    } catch (e) {
      return '無法取得路徑';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          elevation: 8,
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700], size: 48),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'CSV 檔案載入失敗',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.red[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  '無法載入菜色資料檔案，請檢查以下項目：',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                FutureBuilder<String>(
                  future: _getCsvPath(),
                  builder: (context, snapshot) {
                    final csvPath = snapshot.data ?? '載入中...';
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '預期檔案路徑：',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            csvPath,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '錯誤訊息：',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[900],
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        error,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '請確認：',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCheckItem(context, 'CSV 檔案是否存在於指定路徑'),
                      _buildCheckItem(context, '檔案格式是否正確（UTF-8 編碼）'),
                      _buildCheckItem(context, '檔案是否包含正確的表頭和資料列'),
                      _buildCheckItem(context, '檔案權限是否允許讀取'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => exit(0),
                    icon: const Icon(Icons.close),
                    label: const Text('關閉程式'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
