import 'package:bike_gps/model/map_resources.dart';
import 'package:bike_gps/model/search_model.dart';
import 'package:bike_gps/navigation_handler.dart';
import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/route_parser/models/route.dart';
import 'package:bike_gps/widget/map_view/bottom_sheet_widget.dart';
import 'package:bike_gps/widget/map_view/mapbox_map_widget.dart';
import 'package:bike_gps/widget/map_view/options_dialog_widget.dart';
import 'package:bike_gps/widget/map_view/search_widget.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:mapbox_gl_platform_interface/mapbox_gl_platform_interface.dart';
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
  String _initialSearchBarQuery = '';
  NavigationHandler _navigationHandler;

  final GlobalKey<MapboxMapState> _mapboxMapStateKey = GlobalKey();
  final GlobalKey<SearchWidgetState> _searchWidgetStateKey = GlobalKey();
  final GlobalKey<BottomSheetState> _bottomSheetStateKey = GlobalKey();

  MapState(this.routeManager, this.mapResources) {
    _navigationHandler = NavigationHandler(routeManager: routeManager);
  }

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
      return _navigationHandler.getNavigationWidgets();
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

  startNavigation() async {
    MapboxMapState _mapboxMapState = _mapboxMapStateKey.currentState;
    LatLng currentLocation = await _mapboxMapState.getCurrentLocation();
    _navigationHandler.startNavigation(
      activeRoute: _activeRoute,
      stopNavigationCallback: stopNavigation,
      recenterCallback: recenterMap,
      currentLocation: currentLocation,
    );
    _mapboxMapState.onNavigationStarted();
    _activateNavigationView();
  }

  onLocationUpdated(UserLocation userLocation) {
    _navigationHandler.onLocationChanged(userLocation);
  }

  onCameraTrackingDismissed() {
    _navigationHandler.onCameraTrackingDismissed();
  }

  stopNavigation() {
    _initialSearchBarQuery = _activeRoute.routeName;
    _activateRouteSelectionView();
    _mapboxMapStateKey.currentState.onNavigationStopped();
  }

  recenterMap() {
    _mapboxMapStateKey.currentState.setNavigationTrackingMode();
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
