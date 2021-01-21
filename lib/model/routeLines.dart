import 'package:flutter/foundation.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class RouteLines {
  Map<String, RouteLine> routeLines = {};
  RouteLine activeLine;

  void add({
    @required String routeName,
    Line background,
    @required Line route,
    bool isActive = false,
    Line touchArea,
  }) {
    RouteLine routeLine =
        new RouteLine(routeName, background, route, touchArea);
    routeLines[routeName] = routeLine;
    if (isActive) activeLine = routeLine;
  }

  String getName(Line line) {
    return routeLines.values
        .firstWhere((routeLine) =>
            routeLine.route.options.geometry == line.options.geometry)
        .routeName;
  }

  RouteLine getRouteLine(Line line) {
    String routeName = getName(line);
    return routeLines[routeName];
  }
}

class RouteLine {
  String routeName;
  Line background;
  Line route;
  Line touchArea;

  RouteLine(this.routeName, this.background, this.route, this.touchArea);

  List<Line> getLines() {
    return [background, route, touchArea];
  }
}
