import 'dart:math';

import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/route_parser/models/route.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/widgets.dart' hide Route;
import 'package:mapbox_gl_platform_interface/mapbox_gl_platform_interface.dart';

class NavigationHandler {
  Route _activeRoute;
  Function _stopNavigationCallback;
  int _routeStartIndex = -1;
  LatLng _userLocation;
  RouteManager routeManager;

  NavigationHandler({this.routeManager});

  void startNavigation(
      {Route activeRoute,
      Function stopNavigationCallback,
      LatLng currentLocation}) {
    _activeRoute = activeRoute;
    _stopNavigationCallback = stopNavigationCallback;
    _userLocation = currentLocation;
    _routeStartIndex = _getClosestTrackPointIndex(currentLocation);
  }

  void onLocationChanged(UserLocation userLocation) {}

  int _getClosestTrackPointIndex(LatLng userLocation) {
    double shortestDistance = double.infinity;
    int index = -1;
    List<RoutePoint> routePoints = _activeRoute.roadBook.wayPoints;
    for (int i = 0; i < routePoints.length; i++) {
      RoutePoint routePoint = routePoints[i];
      double currentDistance = routePoint.distance(userLocation);
      if (currentDistance < shortestDistance) {
        shortestDistance = currentDistance;
        index = i;
      }
    }
    if (routePoints[index + 1].distance(userLocation) <
        routePoints[index - 1].distance(userLocation)) {
      index++;
    }
    return index;
  }

  List<Widget> getNavigationWidgets() {
    return [
      NavigationWidget(
        activeRoute: _activeRoute,
        routeStartIndex: _routeStartIndex,
        userLocation: _userLocation,
        routeManager: routeManager,
      ),
      NavigationBottomSheet(
        activeRoute: _activeRoute,
        stopNavigationCallback: _stopNavigationCallback,
      ),
    ];
  }
}

class NavigationWidget extends StatefulWidget {
  final Route activeRoute;
  final int routeStartIndex;
  final RouteManager routeManager;
  final LatLng userLocation;

  NavigationWidget(
      {this.activeRoute,
      this.routeStartIndex,
      this.userLocation,
      this.routeManager});

  @override
  NavigationState createState() =>
      NavigationState(activeRoute, routeStartIndex, userLocation, routeManager);
}

class NavigationState extends State<NavigationWidget> {
  final Route activeRoute;
  int routePointIndex;
  final RouteManager routeManager;
  final LatLng userLocation;

  NavigationState(
    this.activeRoute,
    this.routePointIndex,
    this.userLocation,
    this.routeManager,
  );

  @override
  Widget build(BuildContext context) {
    RoutePoint currentRoutePoint =
        activeRoute.roadBook.wayPoints[routePointIndex];
    RoutePoint nextRoutePoint;
    if (routePointIndex < activeRoute.roadBook.wayPoints.length) {
      nextRoutePoint = activeRoute.roadBook.wayPoints[routePointIndex + 1];
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.zero,
              margin: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: Colors.green,
                boxShadow: [
                  BoxShadow(
                    blurRadius: 20.0,
                    color: Colors.black.withOpacity(0.2),
                  )
                ],
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(8),
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          _getArrowIcon(currentRoutePoint.turnSymbolId),
                          Text(
                            '${currentRoutePoint.distance(userLocation).toInt()} m',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        '${currentRoutePoint.name}',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            nextRoutePoint != null
                ? Container(
                    padding: EdgeInsets.zero,
                    margin: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      color: Colors.green.shade800,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                        )
                      ],
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                    ),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Text(
                              "Then",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          _getArrowIcon(nextRoutePoint.turnSymbolId),
                        ],
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  Widget _getArrowIcon(String iconId) {
    if (routeManager.routeParser.turnArrowImages.containsKey(iconId)) {
      return Image(
        image: routeManager.routeParser.turnArrowImages[iconId.toLowerCase()],
      );
    } else {
      return Icon(Icons.info);
    }
  }
}

class NavigationBottomSheet extends StatefulWidget {
  final Function stopNavigationCallback;
  final Route activeRoute;

  NavigationBottomSheet({
    this.activeRoute,
    this.stopNavigationCallback,
  });

  @override
  NavigationBottomSheetState createState() => NavigationBottomSheetState(
        activeRoute,
        stopNavigationCallback,
      );
}

class NavigationBottomSheetState extends State<NavigationBottomSheet> {
  final Function stopNavigationCallback;
  Route _activeRoute;
  bool _snappingBot = false;

  NavigationBottomSheetState(
    this._activeRoute,
    this.stopNavigationCallback,
  );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
          child: Wrap(
            children: [
              Container(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                alignment: Alignment.topCenter,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20.0,
                      color: Colors.black.withOpacity(0.2),
                    )
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _snappingBot
                        ? Stack(
                            children: [
                              Transform.rotate(
                                angle: pi / 8,
                                child: Container(
                                  padding: EdgeInsets.zero,
                                  width: 16,
                                  height: 4,
                                  margin: EdgeInsets.only(
                                      top: 8, left: 0, right: 8),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(5.0))),
                                ),
                              ),
                              Transform.rotate(
                                angle: -pi / 8,
                                child: Container(
                                  padding: EdgeInsets.zero,
                                  width: 16,
                                  height: 4,
                                  margin: EdgeInsets.only(
                                      top: 8, left: 8, right: 0),
                                  decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(5.0))),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: 28,
                            height: 4,
                            margin: EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5.0))),
                          ),
                    Container(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Text(
                              "${(_activeRoute.length.toDouble() / 1000).toStringAsFixed(1)} km",
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                child: Text("Exit"),
                                onPressed: stopNavigationCallback,
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.red,
                                  onPrimary: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(64),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 2.0,
                      margin: EdgeInsets.only(left: 20, right: 20),
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
