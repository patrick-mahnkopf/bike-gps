import 'dart:io';
import 'dart:math';

import 'package:bike_gps/route_parser/models/route.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class RouteList {
  static const MIN_OVERLAP_PERCENTAGE = 0.25;
  Map<String, RouteInfo> _routeList = {};

  List<String> get routeNames => _routeList.keys.toList();

  add({String name, String path, LatLngBounds bounds}) {
    _routeList[name] = RouteInfo(name: name, path: path, bounds: bounds);
  }

  bool contains(String routeName) {
    return _routeList.keys.contains(routeName);
  }

  File getFile(String routeName) {
    return File(_routeList[routeName].path);
  }

  String getPath(String routeName) {
    return _routeList[routeName].path;
  }

  RouteInfo _getRouteInfo(String routeName) {
    return _routeList[routeName];
  }

  List<String> getSimilarRouteNames(String routeName) {
    List<String> similarRouteNames = [];
    RouteInfo primaryRouteInfo = _getRouteInfo(routeName);
    _routeList.values.forEach((routeInfo) {
      if (primaryRouteInfo.name != routeInfo.name) {
        if (primaryRouteInfo.overlap(routeInfo) >= MIN_OVERLAP_PERCENTAGE) {
          similarRouteNames.add(routeInfo.name);
        }
      }
    });
    return similarRouteNames;
  }

  LatLngBounds getCombinedBounds(
      Route primaryRoute, List<Route> similarRoutes) {
    RouteInfo combinedInfo = _getRouteInfo(primaryRoute.routeName);
    for (Route route in similarRoutes) {
      RouteInfo routeInfo = _getRouteInfo(route.routeName);
      if (routeInfo.south < combinedInfo.south)
        combinedInfo.south = routeInfo.south;
      if (routeInfo.west < combinedInfo.west)
        combinedInfo.west = routeInfo.west;
      if (routeInfo.north > combinedInfo.north)
        combinedInfo.north = routeInfo.north;
      if (routeInfo.east > combinedInfo.east)
        combinedInfo.east = routeInfo.east;
    }
    return combinedInfo.bounds;
  }
}

class RouteInfo {
  String name;
  String path;
  LatLngBounds bounds;

  double get west => bounds.southwest.longitude;

  set west(double newValue) => bounds = LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude, newValue),
      northeast: bounds.northeast);

  double get east => bounds.northeast.longitude;

  set east(double newValue) => bounds = LatLngBounds(
      southwest: bounds.southwest,
      northeast: LatLng(bounds.northeast.latitude, newValue));

  double get north => bounds.northeast.latitude;

  set north(double newValue) => bounds = LatLngBounds(
      southwest: bounds.southwest,
      northeast: LatLng(newValue, bounds.northeast.longitude));

  double get south => bounds.southwest.latitude;

  set south(double newValue) => bounds = LatLngBounds(
      southwest: LatLng(newValue, bounds.southwest.longitude),
      northeast: bounds.northeast);

  double get area => (east - west) * (north - south);

  RouteInfo({this.name, this.path, this.bounds});

  double overlap(RouteInfo other) {
    if (this.east <= other.west ||
        other.east <= this.west ||
        this.north <= other.south ||
        other.north <= this.south) return 0;
    double overlapArea =
        (max(this.west, other.west) - min(this.east, other.east)) *
            (max(this.south, other.south) - min(this.north, other.north));
    return max(0, overlapArea / (this.area + other.area - overlapArea));
  }
}
