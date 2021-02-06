import 'package:bike_gps/utils/helpers/color_helper.dart';
import 'package:flutter/material.dart';

class AppConstants {
  static String primaryRouteColor =
      ColorHelper.colorToHex(materialColor: Colors.blue);
  static String secondaryRouteColor =
      ColorHelper.colorToHex(materialColor: Colors.grey);
  static String routeBorderColor = ColorHelper.colorToHex(color: Colors.black);
  static String routeTouchAreaColor =
      ColorHelper.colorToHex(materialColor: Colors.teal);
}
