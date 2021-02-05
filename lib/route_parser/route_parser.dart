library route_parser;

import 'dart:io';

import 'package:bike_gps/route_parser/models/route.dart';

abstract class RouteParser {
  Map<String, String> turnArrowAssetPaths;

  RouteParser();

  Future<Route> getRoute(File routeFile);

  Route addPathToRoute(Route route, String body);

  List<String> getSupportedFileExtensions();
}
