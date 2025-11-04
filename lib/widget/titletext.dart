import 'package:flutter/material.dart';

class TitleTextWidget extends StatelessWidget {
  const TitleTextWidget(
      {super.key,
      required this.label,
      this.fontSize = 20,
      this.maxLines,
      this.color,
      });
  final String label;
  final double fontSize;
  final Color? color;
  final int? maxLines;
  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: maxLines,
      style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: color,
          overflow: TextOverflow.ellipsis),
    );
  }
}