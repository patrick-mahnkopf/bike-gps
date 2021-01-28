import 'dart:math';

import 'package:bike_gps/model/map_resources.dart';
import 'package:bike_gps/model/search_model.dart';
import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/route_parser/models/route.dart';
import 'package:bike_gps/widget/map_view/bottom_sheet_widget.dart';
import 'package:bike_gps/widget/map_view/mapbox_map_widget.dart';
import 'package:bike_gps/widget/map_view/options_dialog_widget.dart';
import 'package:bike_gps/widget/map_view/search_widget.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/material.dart' hide Route;
import 'package:provider/provider.dart';

class MapWidget extends StatefulWidget {
  final RouteManager routeManager;
  final MapResources mapResources;

  const MapWidget({
    @required this.routeManager,
    @required this.mapResources,
  });

  @override
  State createState() => MapState(routeManager, mapResources);
}

class MapState extends State<MapWidget> {
  final RouteManager routeManager;
  final MapResources mapResources;
  bool _bottomSheetVisible = false;
  Route _activeRoute;
  List<Route> _similarRoutes;
  bool _routeSelectionViewActive = true;
  bool _navigationViewActive = false;
  bool _snappingBot = false;
  String _initialSearchBarQuery = '';

  final GlobalKey<MapboxMapState> _mapboxMapStateKey = GlobalKey();
  final GlobalKey<SearchWidgetState> _searchWidgetStateKey = GlobalKey();
  final GlobalKey<BottomSheetState> _bottomSheetStateKey = GlobalKey();

  MapState(this.routeManager, this.mapResources);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          resizeToAvoidBottomInset: false,
          body: MapboxMapWidget(
            key: _mapboxMapStateKey,
            routeManager: routeManager,
            mapResources: mapResources,
            searchWidgetStateKey: _searchWidgetStateKey,
            parent: this,
          ),
        ),
        ..._getActiveWidgets(),
      ],
    );
  }

  List<Widget> _getActiveWidgets() {
    if (_routeSelectionViewActive) {
      return _getRouteSelectionWidgets();
    } else if (_navigationViewActive) {
      return _getNavigationWidgets();
    }
    return [];
  }

  List<Widget> _getRouteSelectionWidgets() {
    return [
      SafeArea(
        child: Padding(
          padding: EdgeInsets.only(top: 64, right: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: () => _mapboxMapStateKey.currentState
                      .showStyleSelectionDialog(),
                  child: Icon(Icons.layers),
                ),
              ),
            ],
          ),
        ),
      ),
      SafeArea(
        child: ChangeNotifierProvider(
          create: (_) => SearchModel(),
          child: SearchWidget(
              key: _searchWidgetStateKey,
              mapboxMapStateKey: _mapboxMapStateKey,
              parent: this,
              routeManager: routeManager,
              initialQuery: _initialSearchBarQuery),
        ),
      ),
      SafeArea(
        child: _bottomSheetVisible
            ? BottomSheetWidget(
                key: _bottomSheetStateKey,
                activeRoute: _activeRoute,
                similarRoutes: _similarRoutes,
                routeManager: routeManager,
                parent: this,
              )
            : Container(),
      )
    ];
  }

  List<Widget> _getNavigationWidgets() {
    return [
      Padding(
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
                            Transform.rotate(
                              angle: 180 * pi / 180,
                              child: Icon(
                                Icons.subdirectory_arrow_right,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              '30m',
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
                          'Suthwiesenstrasse',
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
              Container(
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
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      Transform.rotate(
                        angle: 180 * pi / 180,
                        child: Icon(
                          Icons.subdirectory_arrow_left,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      SafeArea(
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
                                  onPressed: stopNavigation,
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
      ),
    ];
  }

  startNavigation() {
    _activateNavigationView();
    _mapboxMapStateKey.currentState.onNavigationStarted();
  }

  stopNavigation() {
    _initialSearchBarQuery = _activeRoute.routeName;
    _activateRouteSelectionView();
    _mapboxMapStateKey.currentState.onNavigationStopped();
  }

  _activateRouteSelectionView() {
    setState(() {
      _routeSelectionViewActive = true;
      _navigationViewActive = false;
    });
  }

  _activateNavigationView() {
    setState(() {
      _navigationViewActive = true;
      _routeSelectionViewActive = false;
    });
  }

  openOptionsMenu() {
    showGeneralDialog(
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 100),
      context: context,
      pageBuilder: (_, __, ___) {
        return OptionsDialogWidget();
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: child,
        );
      },
    );
  }

  showBottomDrawer(Route route, List<Route> similarRoutes) {
    setState(() {
      _activeRoute = route;
      _similarRoutes = similarRoutes;
      _bottomSheetVisible = true;
    });
  }

  hideBottomDrawer() {
    setState(() {
      _bottomSheetVisible = false;
    });
  }

  changeActiveRoute(Route route, List<Route> similarRoutes) {
    _activeRoute = route;
    _similarRoutes = similarRoutes;
    _changeBottomDrawerRoute(route, similarRoutes);
  }

  _changeBottomDrawerRoute(Route route, List<Route> similarRoutes) {
    _bottomSheetStateKey.currentState.updateRoutes(route, similarRoutes);
  }
}
