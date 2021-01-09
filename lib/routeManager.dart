import 'dart:io';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:gpx/gpx.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:route_parser/models/route.dart';
import 'package:route_parser/route_parser.dart';

class RouteManager {
  List<String> routeList = [];
  Route currentRoute;
  RouteParser routeParser;
  String routesPath;

  RouteManager(this.routeParser) {
    WidgetsFlutterBinding.ensureInitialized();
    init();
  }

  mockRouteFile() async {
    String dir =
        p.join((await getApplicationDocumentsDirectory()).path, 'routes');
    String routeFilePath = p.join(dir, 'Eilenriede.gpx');
    if (!await File(routeFilePath).exists()) {
      String routeString = await rootBundle.loadString('assets/Eilenriede.gpx');
      File routeFile = new File(routeFilePath);
      routeFile.writeAsString(routeString);
    }
    String routeFilePath2 = p.join(dir, 'Julius-Trip-Ring.gpx');
    if (!await File(routeFilePath2).exists()) {
      String routeString2 =
          await rootBundle.loadString('assets/Julius-Trip-Ring.gpx');
      File routeFile2 = new File(routeFilePath2);
      routeFile2.writeAsString(routeString2);
    }
  }

  void init() async {
    routesPath =
        p.join((await getApplicationDocumentsDirectory()).path, 'routes');
    mockRouteFile();
    updateRouteList();
  }

  updateRouteList() async {
    routeList = await Directory(routesPath)
        .list()
        .map((event) => p.basenameWithoutExtension(event.path))
        .toList();
  }

  Future<List<String>> getRouteList() async {
    await updateRouteList();
    return routeList;
  }

  Future<Route> getRoute(String routeName) async {
    File routeFile = getRouteFile(routeName);

    if (routeFile == null) {
      return null;
    } else {
      currentRoute = await routeParser.getRoute(routeFile);
      return currentRoute;
    }
  }

  Route getRouteSync(String routeName) {
    File routeFile = getRouteFile(routeName);

    if (routeFile == null) {
      return null;
    } else {
      currentRoute = routeParser.getRouteSync(routeFile);
      return currentRoute;
    }
  }

  File getRouteFile(String routeName) {
    String filePath = p.join(routesPath, routeName);
    File routeFile;

    for (String fileExtension in routeParser.getSupportedFileExtensions()) {
      if (File(filePath + fileExtension).existsSync()) {
        routeFile = File(filePath + fileExtension);
        break;
      }
    }

    return routeFile;
  }

  List<LatLng> getTrackAsList(Route route) {
    List<LatLng> trackList = [];

    for (Wpt trackPoint in route.trackPoints) {
      trackList.add(LatLng(trackPoint.lat, trackPoint.lon));
    }

    return trackList;
  }

  LatLngBounds getRouteBounds(Route route) {
    Map<String, double> extrema = {
      'west': route.trackPoints[0].lon,
      'north': route.trackPoints[0].lat,
      'east': route.trackPoints[0].lon,
      'south': route.trackPoints[0].lat,
    };
    double padding = 0.006;
    double offset = 0.006;
    for (Wpt trackPoint in route.trackPoints) {
      if (trackPoint.lon < extrema['west']) extrema['west'] = trackPoint.lon;
      if (trackPoint.lon > extrema['east']) extrema['east'] = trackPoint.lon;
      if (trackPoint.lat > extrema['north']) extrema['north'] = trackPoint.lat;
      if (trackPoint.lat < extrema['south']) extrema['south'] = trackPoint.lat;
    }
    return LatLngBounds(
      southwest: LatLng(
          extrema['south'] - padding + offset, extrema['west'] - padding),
      northeast: LatLng(
          extrema['north'] + padding + offset, extrema['east'] + padding),
    );
  }
}
