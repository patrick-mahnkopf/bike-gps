import 'dart:math';

import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/route_parser/models/route.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/widgets.dart' hide Route;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_gl_platform_interface/mapbox_gl_platform_interface.dart';

class NavigationHandler {
  Route _activeRoute;
  Function _stopNavigationCallback;
  Function _recenterCallback;
  int _routeStartIndex = -1;
  LatLng _userLocation;
  RouteManager routeManager;
  bool _navigationActive = false;
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
    _navigationActive = true;
  }

  void stopNavigation() {
    _navigationActive = false;
  }

  void onLocationChanged(UserLocation userLocation) {
    if (_navigationActive) {
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
        stopNavigationCallback: _stopNavigationCallback,
        routeStartIndex: _routeStartIndex,
        userLocation: _userLocation,
        routeManager: routeManager,
        parent: this,
      ),
      NavigationBottomSheet(
        key: _navigationBottomSheetStateKey,
        activeRoute: _activeRoute,
        stopNavigationCallback: _stopNavigationCallback,
        recenterCallback: _recenterCallback,
        routeStartIndex: _routeStartIndex,
        userLocation: _userLocation,
        parent: this,
      ),
    ];
  }
}

class NavigationWidget extends StatefulWidget {
  final Route activeRoute;
  final int routeStartIndex;
  final RouteManager routeManager;
  final LatLng userLocation;
  final Function stopNavigationCallback;
  final NavigationHandler parent;

  NavigationWidget({
    @required Key key,
    @required this.activeRoute,
    @required this.routeStartIndex,
    @required this.userLocation,
    @required this.routeManager,
    @required this.stopNavigationCallback,
    @required this.parent,
  }) : super(key: key);

  @override
  NavigationState createState() => NavigationState(activeRoute, routeStartIndex,
      userLocation, routeManager, stopNavigationCallback, parent);
}

class NavigationState extends State<NavigationWidget> {
  final Route _activeRoute;
  int _routePointIndex;
  final RouteManager _routeManager;
  final Function _stopNavigationCallback;
  LatLng _userLocation;
  double _currentWayPointDistance = 0;
  List<RoutePoint> _routePoints;
  RoutePoint _currentWayPoint;
  RoutePoint _nextRoutePoint;
  int _currentWayPointIndex;
  bool _leftRouteDialogOpen = false;
  final NavigationHandler _parent;

  NavigationState(
    this._activeRoute,
    this._routePointIndex,
    this._userLocation,
    this._routeManager,
    this._stopNavigationCallback,
    this._parent,
  ) {
    _routePoints = _activeRoute.roadBook.routePoints;
    _updateRoutePointsAndDistance();
  }

  @override
  Widget build(BuildContext context) {
    return _currentWayPoint != null
        ? Padding(
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _currentWayPoint.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 24),
                                  ),
                                  Text(
                                    _currentWayPoint.location,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                  Text(
                                    _currentWayPoint.direction,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ],
                              ),
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
                            padding: EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Then",
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                                _getArrowIcon(_nextRoutePoint.turnSymbolId),
                                Text(
                                  _nextRoutePoint.name,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          )
        : Container();
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

    if (_currentWayPointIndex != null &&
        _currentWayPointIndex + 1 <= _routePoints.length) {
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
    if (_routeManager.routeParser.turnArrowAssetPaths.containsKey(iconId)) {
      return SvgPicture.asset(
        _routeManager.routeParser.turnArrowAssetPaths[iconId.toLowerCase()],
        color: Colors.white,
        matchTextDirection: true,
        width: 48,
        alignment: Alignment.center,
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
      _checkIfOnRoute();
    });
  }

  _checkIfOnRoute() {
    if (_routePointIndex > 0) {
      RoutePoint _previousWayPoint = _routePoints[_routePointIndex - 1];
      double au = _previousWayPoint.distance(_userLocation);
      double alpha =
          (_bearingBetween(_previousWayPoint.latLng, _currentWayPoint.latLng) -
                      _bearingBetween(_previousWayPoint.latLng, _userLocation))
                  .abs() /
              180 *
              pi;
      double distanceToRoute = sin(alpha) * au;
      print("Distance: $distanceToRoute");
      if (distanceToRoute >= 20) {
        showLeftRouteDialog();
      }
    }
  }

  double _bearingBetween(LatLng first, LatLng second) {
    return Geolocator.bearingBetween(
        first.latitude, first.longitude, second.latitude, second.longitude);
  }

  showLeftRouteDialog() async {
    if (!_leftRouteDialogOpen) {
      _leftRouteDialogOpen = true;
      _leftRouteDialogOpen = await showGeneralDialog<bool>(
            barrierLabel: "Barrier",
            barrierDismissible: true,
            barrierColor: Colors.black.withOpacity(0.5),
            transitionDuration: Duration(milliseconds: 100),
            context: this.context,
            pageBuilder: (_, __, ___) {
              return SimpleDialog(
                children: [
                  SimpleDialogOption(
                    child: Text('Stop Navigation'),
                    onPressed: () => _closeDialogAndStopNavigation(context),
                  ),
                ],
              );
            },
            transitionBuilder: (_, anim, __, child) {
              return FadeTransition(
                opacity: anim,
                child: child,
              );
            },
          ) ??
          false;
    }
  }

  _closeDialogAndStopNavigation(BuildContext context) {
    Navigator.pop(context, false);
    _parent.stopNavigation();
    _stopNavigationCallback();
  }
}

class NavigationBottomSheet extends StatefulWidget {
  final Function stopNavigationCallback;
  final Function recenterCallback;
  final Route activeRoute;
  final int routeStartIndex;
  final LatLng userLocation;
  final NavigationHandler parent;

  NavigationBottomSheet({
    @required Key key,
    @required this.activeRoute,
    @required this.stopNavigationCallback,
    @required this.recenterCallback,
    @required this.routeStartIndex,
    @required this.userLocation,
    @required this.parent,
  }) : super(key: key);

  @override
  NavigationBottomSheetState createState() => NavigationBottomSheetState(
        activeRoute,
        stopNavigationCallback,
        recenterCallback,
        routeStartIndex,
        userLocation,
        parent,
      );
}

class NavigationBottomSheetState extends State<NavigationBottomSheet> {
  final Function _stopNavigationCallback;
  final Function _recenterCallback;
  final NavigationHandler _parent;
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
    this._parent,
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
                                onPressed: _stopNavigation,
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

  _stopNavigation() {
    _parent.stopNavigation();
    _stopNavigationCallback();
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
