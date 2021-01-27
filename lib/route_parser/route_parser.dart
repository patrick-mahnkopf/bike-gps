library route_parser;

import 'dart:io';

import 'package:bike_gps/route_parser/models/route.dart';
import 'package:flutter/widgets.dart' hide Route;

abstract class RouteParser {
  Map<String, AssetImage> turnArrowImages;

  RouteParser();

  Future<Route> getRoute(File routeFile);

  List<String> getSupportedFileExtensions();
}
