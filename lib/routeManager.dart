import 'dart:convert';
import 'dart:io';

import 'package:bike_gps/model/routeInfo.dart';
import 'package:bike_gps/route_parser/models/route.dart';
import 'package:bike_gps/route_parser/route_parser.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class RouteManager {
  String routesPath;
  RouteParser routeParser;
  RouteList routeList = RouteList();
  List<Route> recentRoutes = [];
  static const int RECENT_ROUTE_BUFFER = 20;

  RouteManager(this.routeParser) {
    WidgetsFlutterBinding.ensureInitialized();
    init();
  }

  void init() async {
    routesPath = p.join(
      (await getApplicationDocumentsDirectory()).path,
      'routes',
    );
    initMockRouteFiles();
    updateRouteList();
  }

  initMockRouteFiles() async {
    // TODO move to tests
    final Map<String, dynamic> manifestMap =
        jsonDecode((await rootBundle.loadString('AssetManifest.json')));
    final routePaths =
        manifestMap.keys.where((String key) => key.contains('routes/'));
    for (String routePath in routePaths) {
      initMockRouteFile(p.basename(routePath).replaceAll('%20', ' '));
    }
  }

  initMockRouteFile(String fileName) async {
    String routeFilePath = p.join(
      (await getApplicationDocumentsDirectory()).path,
      'routes',
      fileName,
    );
    if (!await File(routeFilePath).exists()) {
      File routeFile = new File(routeFilePath);
      String routeString =
          await rootBundle.loadString('assets/routes/$fileName');
      routeFile.writeAsString(routeString);
    }
  }

  updateRouteList() async {
    await Directory(routesPath).list().forEach((element) async {
      String routeName = p.basenameWithoutExtension(element.path);
      if (!routeList.contains(routeName)) {
        Route route = await getRoute(routeName);
        if (route != null) {
          LatLngBounds routeBounds = route.getBounds();
          routeList.add(
            name: routeName,
            path: route.filePath,
            bounds: routeBounds,
          );
        }
      }
    });
  }

  Future<List<String>> getRouteNames() async {
    return routeList.routeNames;
  }

  Future<Route> getRoute(String routeName) async {
    Route route;
    if (recentRoutes.isNotEmpty) {
      route = recentRoutes.firstWhere(
          (recentRoute) => recentRoute.routeName == routeName,
          orElse: () => null);
    }
    if (route != null) {
      return route;
    } else {
      if (routeList.contains(routeName)) {
        route = await routeParser.getRoute(routeList.getFile(routeName));
        _addRecentRoute(route);
        return route;
      } else {
        File routeFile = getRouteFileWithBestExtension(routeName);

        if (routeFile == null) {
          return null;
        } else {
          route = await routeParser.getRoute(routeFile);
          _addRecentRoute(route);
          return route;
        }
      }
    }
  }

  _addRecentRoute(Route route) {
    recentRoutes.insert(0, route);
    if (recentRoutes.length > RECENT_ROUTE_BUFFER) {
      recentRoutes.removeLast();
    }
  }

  File getRouteFileWithBestExtension(String routeName) {
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

  Future<List<Route>> getSimilarRoutes(Route primaryRoute) async {
    List<Route> similarRoutes = [];
    List<String> similarRouteNames =
        routeList.getSimilarRouteNames(primaryRoute.routeName);
    for (String routeName in similarRouteNames) {
      similarRoutes.add(await getRoute(routeName));
    }
    return similarRoutes;
  }
}
