library route_parser;

import 'dart:io';

import 'package:bike_gps/route_parser/models/route.dart';

abstract class RouteParser {
  RouteParser();

  Future<Route> getRoute(File routeFile);

  List<String> getSupportedFileExtensions();
}
