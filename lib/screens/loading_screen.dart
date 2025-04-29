import 'package:flutter/material.dart';

class AnalyzingPage extends StatefulWidget {
  const AnalyzingPage({super.key});

  @override
  State<AnalyzingPage> createState() =>
      _AnalyzingPageState();
}

class _AnalyzingPageState extends State<AnalyzingPage>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.8),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 280),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: Image(image: AssetImage('assets/images/title.png')),
              ),
              LinearProgressIndicator(
                value: controller.value,
                minHeight: 16,
                semanticsLabel: 'Linear progress indicator',
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 40, 0, 64),
                child: Text(
                  "分析中...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PrintingPage extends StatefulWidget {
  const PrintingPage({super.key});

  @override
  State<PrintingPage> createState() =>
      _PrintingPageState();
}

class _PrintingPageState extends State<PrintingPage>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
        setState(() {});
      });
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inverseSurface.withOpacity(0.9),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 280),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: Image(image: AssetImage('assets/images/title.png')),
              ),
              LinearProgressIndicator(
                value: controller.value,
                minHeight: 16,
                semanticsLabel: 'Linear progress indicator',
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 40, 0, 64),
                child: Text(
                  "列印中...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResetingPage extends StatelessWidget {
  const ResetingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.inverseSurface,
      body: const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 280),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 0),
                child: Image(image: AssetImage('assets/images/title.png')),
              ),
              SizedBox(height: 16,),
              Padding(
                padding: EdgeInsets.fromLTRB(0, 40, 0, 64),
                child: Text(
                  "列印完成，重置中，請稍後...",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
