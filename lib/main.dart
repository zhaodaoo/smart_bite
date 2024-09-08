import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_bite/provider/serial_provider.dart';
import 'package:smart_bite/screens/setting_screen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => SerialPortsProvider())
      ],
      child: MaterialApp(
        title: 'Smart Bite!',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
          useMaterial3: true,
        ),
        home: const SettingPage(),
      ),
    );
  }
}
