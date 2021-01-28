import 'dart:math';
import 'dart:typed_data';

import 'package:bike_gps/model/map_resources.dart';
import 'package:bike_gps/model/place.dart';
import 'package:bike_gps/model/routeLines.dart';
import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/route_parser/models/route.dart';
import 'package:bike_gps/utils.dart';
import 'package:bike_gps/widget/map_view/map_style_list_widget.dart';
import 'package:bike_gps/widget/map_view/map_widget.dart';
import 'package:bike_gps/widget/map_view/search_widget.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mapbox_gl_platform_interface/mapbox_gl_platform_interface.dart';
import 'package:path/path.dart';

class MapboxMapWidget extends StatefulWidget {
  final RouteManager routeManager;
  final MapResources mapResources;
  final GlobalKey<SearchWidgetState> searchWidgetStateKey;
  final MapState parent;

  MapboxMapWidget({
    @required Key key,
    @required this.routeManager,
    @required this.mapResources,
    this.searchWidgetStateKey,
    this.parent,
  }) : super(key: key);

  @override
  State createState() =>
      MapboxMapState(routeManager, mapResources, searchWidgetStateKey, parent);
}

class MapboxMapState extends State<MapboxMapWidget> {
  final RouteManager routeManager;
  final MapResources mapResources;
  final GlobalKey<SearchWidgetState> _searchWidgetStateKey;
  final MapState parent;
  MapboxMapController _mapController;
  bool _compassEnabled = true;
  RouteLines routeLines = RouteLines();
  MyLocationRenderMode _locationRenderMode = MyLocationRenderMode.COMPASS;
  List<String> assetImages = [
    'start_location.png',
    'end_location.png',
    'place_pin.png'
  ];
  String primaryRouteColor = Utils.getColorHex(materialColor: Colors.blue);
  String secondaryRouteColor = Utils.getColorHex(materialColor: Colors.grey);
  String routeBorderColor = Utils.getColorHex(color: Colors.black);
  String routeTouchAreaColor = Utils.getColorHex(materialColor: Colors.teal);

  MapboxMapState(
    this.routeManager,
    this.mapResources,
    this._searchWidgetStateKey,
    this.parent,
  );

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: mapResources.mapboxAccessToken,
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
      styleString: mapResources.activeStyleString,
      compassViewPosition: CompassViewPosition.BottomRight,
      compassViewMargins: Point(32, 32),
      compassEnabled: _compassEnabled,
      myLocationEnabled: true,
      myLocationRenderMode: _locationRenderMode,
      myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
      initialCameraPosition:
          const CameraPosition(target: LatLng(52.3825, 9.7177), zoom: 14),
    );
  }

  _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    _mapController.onLineTapped.add(_onLineTapped);
  }

  _onStyleLoaded() {
    initImages();
    initLocation();
  }

  initImages() async {
    for (String imageAsset in assetImages) {
      await addImageToController(imageAsset);
    }
  }

  initLocation() async {
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(
        await _mapController.requestMyLocationLatLng(), 14);
    _mapController.moveCamera(cameraUpdate);
  }

  addImageToController(String imageAsset) async {
    ByteData bytes = await rootBundle.load('assets/images/$imageAsset');
    Uint8List list = bytes.buffer.asUint8List();
    String imageName = basenameWithoutExtension(imageAsset);
    _mapController.addImage(imageName, list);
  }

  onNavigationStarted() {
    _locationRenderMode = MyLocationRenderMode.GPS;
    _mapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.TrackingCompass);
    _clearAlternativeRoutes();
  }

  onNavigationStopped() {
    _locationRenderMode = MyLocationRenderMode.COMPASS;
    _mapController.updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    _redrawAlternativeRoutes();
  }

  onSelectPlace(Place place) {
    CameraUpdate cameraUpdate = getCameraUpdateFromPlace(place);
    _animateCamera(cameraUpdate);
    drawPlaceIcon(place);
  }

  CameraUpdate getCameraUpdateFromPlace(Place place) {
    return CameraUpdate.newLatLngZoom(place.coordinates, 14);
  }

  _moveCamera(CameraUpdate cameraUpdate) {
    _mapController.updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    _mapController.moveCamera(CameraUpdate.bearingTo(0));
    _mapController.moveCamera(cameraUpdate);
  }

  _animateCamera(CameraUpdate cameraUpdate) {
    _mapController.updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    _mapController.moveCamera(CameraUpdate.bearingTo(0));
    _mapController.animateCamera(cameraUpdate);
  }

  onSelectRoute(String routeName) async {
    Route route = await routeManager.getRoute(routeName);
    List<Route> similarRoutes = await routeManager.getSimilarRoutes(route);
    setState(() {
      _compassEnabled = false;
    });
    if (route == null) {
      showDialog(
          context: this.context,
          child: AlertDialog(
            title: Text('Error loading route'),
            content: Text("Couldn't find route $routeName"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(this.context).pop(),
                  child: Text('Dismiss'))
            ],
          ));
    } else {
      if (similarRoutes != null && similarRoutes.length > 0) {
        drawMultipleRoutes(route, similarRoutes);
      } else {
        drawSingleRoute(route);
      }
      parent.showBottomDrawer(route, similarRoutes);
    }
  }

  drawMultipleRoutes(Route primaryRoute, List<Route> similarRoutes) {
    for (Route route in similarRoutes) {
      _drawRoute(
        routeName: route.routeName,
        lineCoordinateList: route.trackAsList,
        isMainRoute: false,
      );
    }

    _drawRoute(
        routeName: primaryRoute.routeName,
        lineCoordinateList: primaryRoute.trackAsList,
        isMainRoute: true);
    drawRouteStartAndEndIcons(primaryRoute.startPoint, primaryRoute.endPoint);

    LatLngBounds combinedBounds =
        routeManager.routeList.getCombinedBounds(primaryRoute, similarRoutes);
    moveCameraToRouteBounds(combinedBounds);
  }

  drawSingleRoute(Route route) {
    _drawRoute(
      routeName: route.routeName,
      lineCoordinateList: route.trackAsList,
      isMainRoute: true,
    );

    drawRouteStartAndEndIcons(route.startPoint, route.endPoint);
    moveCameraToRouteBounds(route.getBounds());
  }

  _drawRoute({
    List<LatLng> lineCoordinateList,
    bool isMainRoute = false,
    @required String routeName,
  }) async {
    double lineWidth = 6;
    double lineBorder = 2;
    double touchAreaWidth = 36;

    routeLines.add(
      routeName: routeName,
      background: await _mapController.addLine(
        LineOptions(
          geometry: lineCoordinateList,
          lineWidth: lineWidth + lineBorder,
          lineColor: routeBorderColor,
          lineOpacity: 0.8,
        ),
      ),
      route: await _mapController.addLine(
        LineOptions(
          geometry: lineCoordinateList,
          lineWidth: lineWidth,
          lineColor: isMainRoute ? primaryRouteColor : secondaryRouteColor,
        ),
      ),
      isActive: isMainRoute,
      touchArea: await _mapController.addLine(
        LineOptions(
          geometry: lineCoordinateList,
          lineWidth: touchAreaWidth,
          lineColor: routeTouchAreaColor,
          lineOpacity: 0,
        ),
      ),
    );
  }

  _onLineTapped(Line line) async {
    RouteLine routeLine = routeLines.getRouteLine(line);
    _updateLines(routeLine);
    Route route = await routeManager.getRoute(routeLine.routeName);
    List<Route> similarRoutes = await routeManager.getSimilarRoutes(route);
    parent.changeActiveRoute(route, similarRoutes);
  }

  _updateLines(RouteLine newActiveLine) async {
    _mapController.clearSymbols();

    RouteLine previousActiveLine = routeLines.activeLine;
    await _deactivateRouteLine(previousActiveLine);
    _activateRouteLine(newActiveLine);
    drawRouteStartAndEndIcons(
      newActiveLine.route.options.geometry.first,
      newActiveLine.route.options.geometry.last,
    );
    _searchWidgetStateKey.currentState.setActiveQuery(newActiveLine.routeName);
  }

  _deactivateRouteLine(RouteLine routeLine) async {
    for (Line line in routeLine.getLines()) {
      _mapController.removeLine(line);
    }
    await _drawRoute(
      routeName: routeLine.routeName,
      lineCoordinateList: routeLine.route.options.geometry,
      isMainRoute: false,
    );
  }

  _activateRouteLine(RouteLine routeLine) {
    for (Line line in routeLine.getLines()) {
      _mapController.removeLine(line);
    }
    _drawRoute(
        routeName: routeLine.routeName,
        lineCoordinateList: routeLine.route.options.geometry,
        isMainRoute: true);
    routeLines.activeLine = routeLine;
  }

  drawRouteStartAndEndIcons(LatLng startPoint, LatLng endPoint) {
    _mapController.addSymbol(SymbolOptions(
      iconImage: 'start_location',
      iconSize: 0.1,
      iconOffset: Offset(0, 15),
      iconAnchor: 'bottom',
      geometry: startPoint,
      textField: 'Start',
      textOffset: Offset(0, -1.6),
      textAnchor: 'bottom',
    ));
    _mapController.addSymbol(SymbolOptions(
      iconImage: 'end_location',
      iconSize: 0.12,
      iconOffset: Offset(0, 15),
      iconAnchor: 'bottom',
      geometry: endPoint,
      textField: 'End',
      textOffset: Offset(0, -1.7),
      textAnchor: 'bottom',
    ));
  }

  _clearAlternativeRoutes() {
    for (RouteLine routeLine in routeLines.routeLines.values) {
      if (routeLine != routeLines.activeLine) {
        for (Line line in routeLine.getLines()) {
          _mapController.removeLine(line);
        }
      }
    }
  }

  _redrawAlternativeRoutes() async {
    _mapController.clearLines();
    for (RouteLine routeLine in routeLines.routeLines.values) {
      if (routeLine != routeLines.activeLine) {
        routeLine.background =
            await _mapController.addLine(routeLine.background.options);
        routeLine.route = await _mapController.addLine(routeLine.route.options);
        routeLine.touchArea =
            await _mapController.addLine(routeLine.touchArea.options);
      }
    }
    routeLines.activeLine.background =
        await _mapController.addLine(routeLines.activeLine.background.options);
    routeLines.activeLine.route =
        await _mapController.addLine(routeLines.activeLine.route.options);
    routeLines.activeLine.touchArea =
        await _mapController.addLine(routeLines.activeLine.touchArea.options);
  }

  moveCameraToRouteBounds(LatLngBounds bounds) {
    double latOffset =
        (bounds.northeast.latitude - bounds.southwest.latitude) / 4;
    double lonOffset =
        (bounds.northeast.longitude - bounds.southwest.longitude) / 10;
    LatLngBounds adjustedBounds = LatLngBounds(
        southwest: LatLng(bounds.southwest.latitude - latOffset,
            bounds.southwest.longitude - lonOffset),
        northeast: LatLng(bounds.northeast.latitude + latOffset,
            bounds.northeast.longitude + lonOffset));
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(adjustedBounds);
    _moveCamera(cameraUpdate);
  }

  clearActiveDrawings() {
    _mapController.clearLines();
    _mapController.clearCircles();
    _mapController.clearSymbols();
    parent.hideBottomDrawer();
    setState(() {
      _compassEnabled = true;
    });
  }

  drawPlaceIcon(Place place) async {
    _mapController.addSymbol(SymbolOptions(
      iconImage: 'place_pin',
      iconSize: 0.1,
      iconOffset: Offset(0, 15),
      iconAnchor: 'bottom',
      geometry: place.coordinates,
    ));
  }

  showStyleSelectionDialog() {
    showGeneralDialog(
      barrierLabel: "Barrier",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: Duration(milliseconds: 100),
      context: this.context,
      pageBuilder: (_, __, ___) {
        return MapStyleListWidget(
          changeStyleCallback: changeStyle,
          styleStringNames: mapResources.styleStringNames,
          currentStyleName: mapResources.activeStyleStringName,
        );
      },
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: anim,
          child: child,
        );
      },
    );
  }

  changeStyle(String styleName) {
    if (mapResources.activeStyleStringName != styleName) {
      setState(() {
        mapResources.activeStyleStringName = styleName;
      });
    }
  }
}
