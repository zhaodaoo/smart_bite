import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_bite/provider/data_provider.dart';
import 'package:smart_bite/provider/serial_provider.dart';
import 'package:smart_bite/provider/rfid_reader_provider.dart';
import 'package:smart_bite/screens/input_screen.dart';
import 'package:smart_bite/utils/platform_detector.dart';
import 'package:window_manager/window_manager.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
// Must add this line.
  await windowManager.ensureInitialized();

  if (Platform.isWindows) {
    WindowManager.instance.setMinimumSize(const Size(1280, 720));
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Detect platform and create appropriate RFID reader manager
    // Use environment variable RFID_MODE to override: 'serial', 'gpio', or 'mock'
    final rfidMode = Platform.environment['RFID_MODE'];
    PlatformType? forcePlatform;
    
    if (rfidMode == 'serial') {
      forcePlatform = PlatformType.desktop;
    } else if (rfidMode == 'gpio') {
      forcePlatform = PlatformType.raspberryPi;
    } else if (rfidMode == 'mock') {
      forcePlatform = PlatformType.mock;
    }
    
    final readerManager = RFIDReaderFactory.createReaderManager(
      forcePlatform: forcePlatform,
    );
    
    return MultiProvider(
      providers: [
        // New abstracted RFID reader provider
        ChangeNotifierProvider(
          create: (context) => RFIDReaderProvider(
            readerManager: readerManager,
          ),
        ),
        // Keep legacy serial provider for backward compatibility during migration
        ChangeNotifierProvider(create: (context) => SerialPortsProvider()),
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
