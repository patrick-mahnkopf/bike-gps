import 'package:route_parser/models/route.dart';
import 'package:route_parser/route_parser.dart';

class RouteManager {
  static const String ROUTE_ROOT_PATH = "";
  List<String> routeList;
  Route currentRoute;
  RouteParser routeParser;

  RouteManager(this.routeParser);

  Route getRoute(String routeName) {
    currentRoute = routeParser.getRoute(ROUTE_ROOT_PATH, routeName);
    return currentRoute;
  }
}
