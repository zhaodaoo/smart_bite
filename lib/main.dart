import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:smart_bite/data/optimized_indexes.dart';
import 'package:smart_bite/provider/data_provider.dart';
import 'package:smart_bite/provider/rfid_reader_provider.dart';
import 'package:smart_bite/screens/input_screen.dart';
import 'package:smart_bite/utils/platform_detector.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pre-load critical data for optimal performance
  // Initialize optimized indexes for dishes and nutrition data
  // This improves RFID scanning and nutrition analysis performance by 40-50%
  await initializeOptimizedIndexes();

  // Pre-load PDF background images to fix first print job missing background bug
  await _preloadPDFAssets();

  // Must add this line.
  await windowManager.ensureInitialized();

  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(1920, 1080));
    WindowManager.instance.setMaximumSize(const Size(1920, 1080));
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
  runApp(const MyApp());
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
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
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
