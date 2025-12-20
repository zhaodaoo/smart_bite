import 'package:flutter/material.dart';

/// PDF printing text widgets extracted from DataProvider.
/// These widgets are used for generating PDF screenshots with specific text styles.

class NormalBlackPrintingText extends StatelessWidget {
  final String text;

  const NormalBlackPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 50,
                color: Colors.black,
                fontFamily: 'NotoSansCJK')));
  }
}

class NormalRedPrintingText extends StatelessWidget {
  final String text;

  const NormalRedPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 46,
                color: Colors.red,
                fontFamily: 'NotoSansCJK')));
  }
}

class HighlightPrintingText extends StatelessWidget {
  final String text;

  const HighlightPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 120,
                color: Colors.red,
                fontFamily: 'NotoSansCJK')));
  }
}

class SmallPrintingText extends StatelessWidget {
  final String text;

  const SmallPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 40,
                color: Colors.red,
                fontFamily: 'NotoSansCJK')));
  }
}

class MidPrintingText extends StatelessWidget {
  final String text;

  const MidPrintingText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(text,
            style: const TextStyle(
                fontSize: 56,
                color: Colors.red,
                fontFamily: 'NotoSansCJK')));
  }
}

class PrintingBar extends StatelessWidget {
  final int percent;
  final Color color;

  const PrintingBar(this.percent, {super.key, required this.color});
  static const frameOpacity = 0.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
            width: 1225.5 * percent / 100.0,
            height: 66,
            child: Container(color: color.withValues(alpha: 0.7))),
        SizedBox(
            width: 1225.5 * (1.0 - percent / 100.0),
            height: 66,
            child: Container(color: Colors.blue.withValues(alpha: frameOpacity))),
      ],
    );
  }
}
