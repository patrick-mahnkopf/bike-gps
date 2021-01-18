import 'package:flutter/material.dart';

class Utils {
  static String getColorHex({MaterialColor materialColor, Color color}) {
    int value;
    if (materialColor != null)
      value = materialColor.value;
    else
      value = color.value;
    return '#${value.toRadixString(16).substring(2, value.toRadixString(16).length).padLeft(6, '0')}';
  }
}
