import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_bite/provider/data_provider.dart';
import 'package:smart_bite/provider/serial_provider.dart';
import 'package:smart_bite/screens/input_screen.dart';
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SerialPortsProvider()),
        ChangeNotifierProvider(create: (context) => DataProvider(),),
      ],
      child: MaterialApp(
        title: 'Smart Bite!',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          useMaterial3: true,
        ),
        home: const InputScreen(),
      ),
    );
  }
}
