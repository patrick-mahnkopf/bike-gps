import 'dart:math';

import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/route_parser/models/route.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/widgets.dart' hide Route;
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl_platform_interface/mapbox_gl_platform_interface.dart';

class NavigationHandler {
  Route _activeRoute;
  Function _stopNavigationCallback;
  Function _recenterCallback;
  int _routeStartIndex = -1;
  LatLng _userLocation;
  RouteManager routeManager;
  final GlobalKey<NavigationState> _navigationStateKey = GlobalKey();
  final GlobalKey<NavigationBottomSheetState> _navigationBottomSheetStateKey =
      GlobalKey();

  NavigationHandler({@required this.routeManager});

  void startNavigation(
      {@required Route activeRoute,
      @required Function stopNavigationCallback,
      @required Function recenterCallback,
      @required LatLng currentLocation}) {
    _activeRoute = activeRoute;
    _stopNavigationCallback = stopNavigationCallback;
    _recenterCallback = recenterCallback;
    _userLocation = currentLocation;
    _routeStartIndex = _getClosestTrackPointIndex(currentLocation);
  }

  void onLocationChanged(UserLocation userLocation) {
    print("NavigationHandler: onLocationChanged");
    _userLocation = userLocation.position;
    int closestTrackPointIndex = _getClosestTrackPointIndex(_userLocation);
    _navigationStateKey.currentState.onLocationChanged(
      _userLocation,
      closestTrackPointIndex,
    );
    _navigationBottomSheetStateKey.currentState.onLocationChanged(
      _userLocation,
      closestTrackPointIndex,
    );
  }

  void onCameraTrackingDismissed() {
    _navigationBottomSheetStateKey.currentState.showRecenterButton();
  }

  int _getClosestTrackPointIndex(LatLng userLocation) {
    double shortestDistance = double.infinity;
    int index = -1;
    List<RoutePoint> routePoints = _activeRoute.roadBook.routePoints;
    for (int i = 0; i < routePoints.length; i++) {
      RoutePoint routePoint = routePoints[i];
      double currentDistance = routePoint.distance(userLocation);
      if (currentDistance < shortestDistance) {
        shortestDistance = currentDistance;
        index = i;
      }
    }
    if (index != 0 &&
        routePoints[index + 1].distance(userLocation) <
            routePoints[index - 1].distance(userLocation)) {
      index++;
    }
    return index;
  }

  List<Widget> getNavigationWidgets() {
    return [
      NavigationWidget(
        key: _navigationStateKey,
        activeRoute: _activeRoute,
        routeStartIndex: _routeStartIndex,
        userLocation: _userLocation,
        routeManager: routeManager,
      ),
      NavigationBottomSheet(
        key: _navigationBottomSheetStateKey,
        activeRoute: _activeRoute,
        stopNavigationCallback: _stopNavigationCallback,
        recenterCallback: _recenterCallback,
        routeStartIndex: _routeStartIndex,
        userLocation: _userLocation,
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
      {@required Key key,
      @required this.activeRoute,
      @required this.routeStartIndex,
      @required this.userLocation,
      @required this.routeManager})
      : super(key: key);

  @override
  NavigationState createState() =>
      NavigationState(activeRoute, routeStartIndex, userLocation, routeManager);
}

class NavigationState extends State<NavigationWidget> {
  final Route _activeRoute;
  int _routePointIndex;
  final RouteManager _routeManager;
  LatLng _userLocation;
  double _currentWayPointDistance = 0;
  List<RoutePoint> _routePoints;
  RoutePoint _currentWayPoint;
  RoutePoint _nextRoutePoint;
  int _currentWayPointIndex;

  NavigationState(
    this._activeRoute,
    this._routePointIndex,
    this._userLocation,
    this._routeManager,
  ) {
    _routePoints = _activeRoute.roadBook.routePoints;
    _updateRoutePointsAndDistance();
  }

  @override
  Widget build(BuildContext context) {
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
                          _getArrowIcon(_currentWayPoint.turnSymbolId),
                          Text(
                            getDistanceAsString(
                                _currentWayPointDistance.toInt()),
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
                        '${_currentWayPoint.name}',
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
            _nextRoutePoint != null
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
                          _getArrowIcon(_nextRoutePoint.turnSymbolId),
                          Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Text(
                              _nextRoutePoint.name,
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
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

  _updateRoutePointsAndDistance() {
    _currentWayPointDistance = 0;
    for (int i = _routePointIndex; i < _routePoints.length; i++) {
      if (i == _routePointIndex) {
        _currentWayPointDistance +=
            _distanceBetween(_userLocation, _routePoints[i].latLng);
      } else {
        _currentWayPointDistance += _distanceBetween(
            _routePoints[i - 1].latLng, _routePoints[i].latLng);
      }
      if (_routePoints[i].isWayPoint) {
        _currentWayPoint = _routePoints[i];
        _currentWayPointIndex = i;
        break;
      }
    }

    if (_currentWayPointIndex + 1 <= _routePoints.length) {
      int _nextRoutePointIndex = _routePoints.indexWhere(
          (routePoint) => routePoint.isWayPoint, _currentWayPointIndex + 1);
      if (_nextRoutePointIndex != -1) {
        _nextRoutePoint = _routePoints[_nextRoutePointIndex];
      } else {
        _nextRoutePoint = null;
      }
    }
  }

  Widget _getArrowIcon(String iconId) {
    if (_routeManager.routeParser.turnArrowImages.containsKey(iconId)) {
      return Image(
        image: _routeManager.routeParser.turnArrowImages[iconId.toLowerCase()],
      );
    } else {
      return Icon(Icons.info);
    }
  }

  onLocationChanged(LatLng userLocation, int routeStartIndex) {
    setState(() {
      _routePointIndex = routeStartIndex;
      _userLocation = userLocation;
      _updateRoutePointsAndDistance();
    });
  }
}

class NavigationBottomSheet extends StatefulWidget {
  final Function stopNavigationCallback;
  final Function recenterCallback;
  final Route activeRoute;
  final int routeStartIndex;
  final LatLng userLocation;

  NavigationBottomSheet({
    @required Key key,
    @required this.activeRoute,
    @required this.stopNavigationCallback,
    @required this.recenterCallback,
    @required this.routeStartIndex,
    @required this.userLocation,
  }) : super(key: key);

  @override
  NavigationBottomSheetState createState() => NavigationBottomSheetState(
    activeRoute,
        stopNavigationCallback,
        recenterCallback,
        routeStartIndex,
        userLocation,
      );
}

class NavigationBottomSheetState extends State<NavigationBottomSheet> {
  final Function _stopNavigationCallback;
  final Function _recenterCallback;
  Route _activeRoute;
  int _routeStartIndex;
  LatLng _userLocation;
  bool _snappingBot = false;
  bool _recenterButtonVisible = false;
  double _distanceLeft;

  NavigationBottomSheetState(
    this._activeRoute,
    this._stopNavigationCallback,
    this._recenterCallback,
    this._routeStartIndex,
    this._userLocation,
  ) {
    _setDistanceLeft(_userLocation, _routeStartIndex);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
          child: Wrap(
            children: [
              _recenterButtonVisible
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                      child: FloatingActionButton.extended(
                        onPressed: () => recenterMap(),
                        backgroundColor: Colors.white,
                        label: Text(
                          "Re-center",
                          style: TextStyle(color: Colors.blue),
                        ),
                        icon: Icon(
                          Icons.navigation,
                          color: Colors.blue,
                        ),
                      ),
                    )
                  : Container(),
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
                              getDistanceAsString(_distanceLeft.toInt()),
                              style: TextStyle(fontSize: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                child: Text("Exit"),
                                onPressed: _stopNavigationCallback,
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

  onLocationChanged(LatLng userLocation, int routeStartIndex) {
    setState(() {
      _setDistanceLeft(userLocation, routeStartIndex);
    });
  }

  _setDistanceLeft(LatLng userLocation, int routeStartIndex) {
    RoutePoint closestTrackPoint =
        _activeRoute.roadBook.routePoints[routeStartIndex];
    _distanceLeft =
        (_activeRoute.routeLength - closestTrackPoint.distanceFromStart) +
            _distanceBetween(userLocation, closestTrackPoint.latLng);
  }

  recenterMap() {
    hideRecenterButton();
    _recenterCallback();
  }

  showRecenterButton() {
    setState(() {
      _recenterButtonVisible = true;
    });
  }

  hideRecenterButton() {
    setState(() {
      _recenterButtonVisible = false;
    });
  }
}

double _distanceBetween(LatLng first, LatLng second) {
  return Geolocator.distanceBetween(
      first.latitude, first.longitude, second.latitude, second.longitude);
}

String getDistanceAsString(int distance) {
  if (distance.toDouble() / 1000 >= 1) {
    return "${(distance.toDouble() / 1000).toStringAsFixed(1)} km";
  } else {
    return "$distance m";
  }
}
