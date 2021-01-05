import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:route_parser/models/route.dart';
import 'package:route_parser/route_parser.dart';

class RouteManager {
  List<String> routeList;
  Route currentRoute;
  RouteParser routeParser;

  RouteManager(this.routeParser);

  Future<Route> getRoute(String routeName) async {
    File routeFile = await getRouteFile(routeName);

    if (routeFile == null) {
      return null;
    } else {
      currentRoute = await routeParser.getRoute(routeFile);
      return currentRoute;
    }
  }

  Future<File> getRouteFile(String routeName) async {
    String filePath = p.join(
        (await getApplicationDocumentsDirectory()).path, 'routes', routeName);
    File routeFile;

    for (String fileExtension in routeParser.getSupportedFileExtensions()) {
      if (File(filePath + fileExtension).existsSync()) {
        routeFile = File(filePath + fileExtension);
        break;
      }
    }

    return routeFile;
  }
}
