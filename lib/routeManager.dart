import 'dart:convert';
import 'dart:io';

import 'package:bike_gps/model/routeInfo.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:route_parser/models/route.dart';
import 'package:route_parser/route_parser.dart';

class RouteManager {
  String routesPath;
  RouteParser routeParser;
  Route currentRoute;
  RouteList routeList = RouteList();

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
        String routePath = getRouteFileWithBestExtension(routeName).path;
        LatLngBounds routeBounds = route.getBounds();
        routeList.add(
          name: routeName,
          path: routePath,
          bounds: routeBounds,
        );
      }
    });
  }

  Future<List<String>> getRouteNames() async {
    await updateRouteList();
    return routeList.routeNames;
  }

  Future<Route> getRoute(String routeName) async {
    if (routeList.contains(routeName)) {
      return await routeParser.getRoute(routeList.getFile(routeName));
    } else {
      File routeFile = getRouteFileWithBestExtension(routeName);

      if (routeFile == null) {
        return null;
      } else {
        return await routeParser.getRoute(routeFile);
      }
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
