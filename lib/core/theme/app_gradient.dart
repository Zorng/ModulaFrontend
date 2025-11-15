import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFFFDBD5), // indigo
      Color(0xFFE8E8E8),
    ],
    stops: [0.02, 0.86],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient textGradient = LinearGradient(
    colors: [
      Color(0xFF696969),
      Color(0xFFED533C),
    ],
    stops: [0.28, 1.0],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}