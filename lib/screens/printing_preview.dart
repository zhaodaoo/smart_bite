import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';
import 'package:smart_bite/data/comments.dart';
import 'package:smart_bite/data/constant.dart';

Future<void> main() async {
  runApp(const MyApp('Printing Demo'));
}

class MyApp extends StatelessWidget {
  const MyApp(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    precacheImage(const AssetImage('assets/images/printing_layout.png'), context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: PdfPreview(
          build: (format) => _generatePdf(format),
          initialPageFormat: PdfPageFormat.a4.landscape,
          dpi: 300,
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format) async {
    
    Widget myContainer = Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/printing_layout.png"),
          fit: BoxFit.contain,
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 100, child: Container(color: Colors.blue.withOpacity(0.0),),),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 480, height: 64, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 80, child: Center(child: NormalPrintingText('男性'))),
                  SizedBox(height: 18, width: 200, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  const SizedBox(height: 80, child: Center(child: NormalPrintingText('11歲'))),
                  SizedBox(height: 18, width: 200, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  const SizedBox(height: 80, child: Center(child: NormalPrintingText('低'))),
                  SizedBox(height: 18, width: 200, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  const SizedBox(height: 80, child: Center(child: NormalPrintingText('午餐'))),
                ],
              ),
              SizedBox(width: 120, height: 100, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 1160, height: 56, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 1160, child: Container(color: Colors.blue.withOpacity(0.0), child: const Center(child: NormalPrintingText('藜麥毛豆糙米菇菇雞炊飯、藜麥毛豆糙米菇菇雞炊飯、藜麥毛豆糙米菇菇雞炊飯、藜麥毛豆糙米菇菇雞炊飯、蒜香彩椒青花蓮藕片、蒜香彩椒青花蓮藕片、蒜香彩椒青花蓮藕片')),),),
                ],
              ),
              SizedBox(width: 160, height: 100, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 1160, height: 56, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 1160,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('六大類食物都攝取到了，看看下方的圖表了解這餐吃的食物分析吧！'),),),
                ],
              ),
            
            ],
          ),
          SizedBox(height: 18, child: Container(color: Colors.blue.withOpacity(0.0),),),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 720, height: 50, child: Container(color: Colors.blue.withOpacity(0.0),),),
              SizedBox(width: 360, child: Container(color: Colors.blue.withOpacity(0.0), child: const HighlightPrintingText('2050'),),),
              SizedBox(width: 560, height: 50, child: Container(color: Colors.blue.withOpacity(0.0),),),
              SizedBox(width: 810, child: Container(color: Colors.blue.withOpacity(0.0), child: const HighlightPrintingText('1800-1900'),),),
            ],
          ),
          SizedBox(height: 136, child: Container(color: Colors.blue.withOpacity(0.0),),),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 454, height: 40, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 100, height: 132, child: Container(color: Colors.blue.withOpacity(0.0), child: const SmallPrintingText('1.3'),),),
                  SizedBox(width: 100, height: 132, child: Container(color: Colors.blue.withOpacity(0.0), child: const SmallPrintingText('0.1'),),),
                  SizedBox(width: 100, height: 132, child: Container(color: Colors.blue.withOpacity(0.0), child: const SmallPrintingText('2.7'),),),
                  SizedBox(width: 100, height: 132, child: Container(color: Colors.blue.withOpacity(0.0), child: const SmallPrintingText('0.7'),),),
                  SizedBox(width: 100, height: 132, child: Container(color: Colors.blue.withOpacity(0.0), child: const SmallPrintingText('3.9'),),),
                  SizedBox(width: 100, height: 132, child: Container(color: Colors.blue.withOpacity(0.0), child: const SmallPrintingText('0.9'),),),
                ],
              ),
              SizedBox(width: 254, height: 50, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(height: 33, child: Container(color: Colors.blue.withOpacity(0.0))),
                  const PrintingBar(100, color: Color.fromARGB(1, 236, 176, 30),),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  const PrintingBar(100, color: Color.fromARGB(1, 219, 81, 115),),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  const PrintingBar(100, color: Color.fromARGB(1, 138, 185, 45),),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  const PrintingBar(100, color: Color.fromARGB(1, 219, 103, 18),),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  const PrintingBar(100, color: Color.fromARGB(1, 213, 180, 101),),
                  SizedBox(height: 66, child: Container(color: Colors.blue.withOpacity(0.0))),
                  const PrintingBar(100, color: Color.fromARGB(1, 147, 204, 233),),
                  SizedBox(height: 33, child: Container(color: Colors.blue.withOpacity(0.0))),
                ],
              ),
              // SizedBox(width: 70, height: 35, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 180, height: 132,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('66%'),),),
                  SizedBox(width: 180, height: 132,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('10%'),),),
                  SizedBox(width: 180, height: 132,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('88%'),),),
                  SizedBox(width: 180, height: 132,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('53%'),),),
                  SizedBox(width: 180, height: 132,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('77%'),),),
                  SizedBox(width: 180, height: 132,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('60%'),),),
                ],
              ),
              SizedBox(width: 550, height: 35, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 300, height: 105,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('1077.7'),),),
                  SizedBox(width: 300, height: 105,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('119.4'),),),
                  SizedBox(width: 300, height: 105,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('37.8'),),),
                  SizedBox(width: 300, height: 105,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('48.3'),),),
                  SizedBox(width: 300, height: 105,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('1620.6'),),),
                  SizedBox(width: 300, height: 105,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('725.4'),),),
                  SizedBox(width: 300, height: 105,child: Container(color: Colors.blue.withOpacity(0.0), child: const NormalPrintingText('11.9'),),),
                ],
              ),
            
            ],
          ),
          SizedBox(height: 192, child: Container(color: Colors.blue.withOpacity(0.0),),),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 592, height: 50, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 64, height: 4, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 64, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: const MidPrintingText('適量'),),),
                  SizedBox(width: 64, height: 36, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 64, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: const MidPrintingText('不足'),),),
                  SizedBox(width: 64, height: 36, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 64, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: const MidPrintingText('適量'),),),
                ],
              ),
              
              SizedBox(width: 56, height: 50, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 1000, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: SmallPrintingText(commentsForFoodTypeByRank[NutritionType.grains]![Rank.good]!),),),
                  SizedBox(width: 50, height: 36, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 1000, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: SmallPrintingText(commentsForFoodTypeByRank[NutritionType.meat]![Rank.tooLess]!),),),
                  SizedBox(width: 50, height: 36, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 1000, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: SmallPrintingText(commentsForFoodTypeByRank[NutritionType.vegetables]![Rank.good]!),),),
                ],
              ),
              SizedBox(width: 472, height: 50, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 64, height: 4, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 64, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: const MidPrintingText('適量'),),),
                  SizedBox(width: 64, height: 36, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 64, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: const MidPrintingText('不足'),),),
                  SizedBox(width: 64, height: 36, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 64, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: const MidPrintingText('適量'),),),
                ],
              ),
              
              SizedBox(width: 60, height: 50, child: Container(color: Colors.blue.withOpacity(0.0),),),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(width: 1000, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: SmallPrintingText(commentsForFoodTypeByRank[NutritionType.fruits]![Rank.tooMuch]!),),),
                  SizedBox(width: 50, height: 36, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 1000, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: SmallPrintingText(commentsForFoodTypeByRank[NutritionType.oils]![Rank.good]!),),),
                  SizedBox(width: 50, height: 36, child: Container(color: Colors.blue.withOpacity(0.0),),),
                  SizedBox(width: 1000, height: 180,child: Container(color: Colors.blue.withOpacity(0.0), child: SmallPrintingText(commentsForFoodTypeByRank[NutritionType.grains]![Rank.tooMuch]!),),),
                ],
              ),
            ],
          ),
          
        ],
      ),
    );

    ScreenshotController screenshotController = ScreenshotController();
    var capturedImage = await screenshotController.captureFromWidget(
      myContainer,
      pixelRatio: 1,
      targetSize: const Size(3508,2480),
      delay: const Duration(seconds: 3)
    );

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: format.copyWith(
          marginBottom: 0.3 * PdfPageFormat.cm,
          marginLeft: 0.3 * PdfPageFormat.cm,
          marginRight: 0.3 * PdfPageFormat.cm,
          marginTop: 0.3 * PdfPageFormat.cm
        ),
        build: (context) {
          return pw.Center(
            child: pw.Image(
                pw.MemoryImage(capturedImage),
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );
    return pdf.save();

  }
  
}

class NormalPrintingText extends StatelessWidget {
  final String text;

  const NormalPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(fontSize: 46, color: Colors.red)));
  }
}

class HighlightPrintingText extends StatelessWidget {
  final String text;

  const HighlightPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(fontSize: 120, color: Colors.red)));
  }
}

class SmallPrintingText extends StatelessWidget {
  final String text;

  const SmallPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(fontSize: 40, color: Colors.red)));
  }
}

class MidPrintingText extends StatelessWidget {
  final String text;

  const MidPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(text, style: const TextStyle(fontSize: 56, color: Colors.red)));
  }
}

class PrintingBar extends StatelessWidget {
  final int percent;
  final Color color;

  const PrintingBar(this.percent, {super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(width: 1222.0*percent/100.0, height: 66,child: Container(color: color.withOpacity(0.7)),),
        SizedBox(width: 1222.0*(1.0-percent/100.0), height: 66,child: Container(color: Colors.blue.withOpacity(0.0)),),
      ],
    );
  }
  
}
