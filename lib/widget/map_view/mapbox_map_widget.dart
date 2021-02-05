import 'dart:developer' as developer;
import 'dart:io';
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
import 'package:location/location.dart';
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
  LatLngBounds _currentBounds;
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
  CameraPosition _initialLocation =
      CameraPosition(target: LatLng(52.3825, 9.7177), zoom: 14);

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
      onUserLocationUpdated: parent.onLocationUpdated,
      myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
      onCameraTrackingDismissed: parent.onCameraTrackingDismissed,
      initialCameraPosition: _initialLocation,
    );
  }

  setNavigationTrackingMode() {
    _mapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.TrackingCompass);
  }

  _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    _mapController.onLineTapped.add(_onLineTapped);
  }

  Future<LatLng> _getCurrentLocation() async {
    LocationData locationData = await Location().getLocation();
    LatLng currentLocation =
        LatLng(locationData.latitude, locationData.longitude);
    // return await _mapController.requestMyLocationLatLng();
    return currentLocation;
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
    CameraUpdate cameraUpdate =
        CameraUpdate.newLatLngZoom(await _getCurrentLocation(), 14);
    _mapController.moveCamera(cameraUpdate);
    _initialLocation =
        CameraPosition(target: await _getCurrentLocation(), zoom: 14);
  }

  addImageToController(String imageAsset) async {
    ByteData bytes = await rootBundle.load('assets/images/$imageAsset');
    Uint8List list = bytes.buffer.asUint8List();
    String imageName = basenameWithoutExtension(imageAsset);
    _mapController.addImage(imageName, list);
  }

  onNavigationStarted(Route route) async {
    if (Platform.isIOS) {
      _mapController.moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
        // target: await _mapController.requestMyLocationLatLng(),
        target: await _getCurrentLocation(),
        // tilt: 200,
        zoom: 18,
      )));
    } else {
      await _mapController
          .animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        // target: await _mapController.requestMyLocationLatLng(),
        target: await _getCurrentLocation(),
        // tilt: 200,
        zoom: 18,
      )));
    }
    _locationRenderMode = MyLocationRenderMode.GPS;
    _mapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.TrackingCompass);
    _clearAlternativeRoutes();
    if (route.roadBook.hasPathToRoute) {
      developer.log("Map drew ORS route");
      _drawRoute(
        routeName: "ORS",
        lineCoordinateList: route.roadBook.pathToRouteList,
        isMainRoute: true,
        isPathToRoute: true,
      );
      setState(() {});
    }
  }

  onNavigationStopped() async {
    await _mapController
        .moveCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: await _getCurrentLocation(),
      tilt: 0,
    )));
    moveCameraToRouteBounds(_currentBounds);
    _locationRenderMode = MyLocationRenderMode.COMPASS;
    _mapController.updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    _redrawAlternativeRoutes();
    _clearPathToRoute();
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

  drawMultipleRoutes(Route primaryRoute, List<Route> similarRoutes) async {
    for (Route route in similarRoutes) {
      await _drawRoute(
        routeName: route.routeName,
        lineCoordinateList: route.trackAsList,
        isMainRoute: false,
      );
    }

    await _drawRoute(
        routeName: primaryRoute.routeName,
        lineCoordinateList: primaryRoute.trackAsList,
        isMainRoute: true);
    drawRouteStartAndEndIcons(primaryRoute.startPoint, primaryRoute.endPoint);

    if (_currentBounds == null) {
      _currentBounds =
          routeManager.routeList.getCombinedBounds(primaryRoute, similarRoutes);
    }
    moveCameraToRouteBounds(_currentBounds);
  }

  drawSingleRoute(Route route) async {
    await _drawRoute(
      routeName: route.routeName,
      lineCoordinateList: route.trackAsList,
      isMainRoute: true,
    );

    drawRouteStartAndEndIcons(route.startPoint, route.endPoint);

    if (_currentBounds == null) {
      _currentBounds = route.getBounds();
    }
    moveCameraToRouteBounds(_currentBounds);
  }

  _drawRoute({
    List<LatLng> lineCoordinateList,
    bool isMainRoute = false,
    bool isPathToRoute = false,
    @required String routeName,
  }) async {
    double lineWidth = 6;
    double lineBorder = 2;
    double touchAreaWidth = 36;

    Line touchAreaLine = await _mapController.addLine(
      LineOptions(
        geometry: lineCoordinateList,
        lineWidth: touchAreaWidth,
        lineColor: routeTouchAreaColor,
        lineOpacity: 0,
      ),
    );
    Line backgroundLine = await _mapController.addLine(
      LineOptions(
        geometry: lineCoordinateList,
        lineWidth: lineBorder,
        lineColor: routeBorderColor,
        lineOpacity: 0.8,
        lineGapWidth: lineWidth,
      ),
    );
    Line routeLine = await _mapController.addLine(
      LineOptions(
        geometry: lineCoordinateList,
        lineWidth: lineWidth,
        lineColor: isMainRoute ? primaryRouteColor : secondaryRouteColor,
      ),
    );

    routeLines.add(
      routeName: routeName,
      background: backgroundLine,
      route: routeLine,
      isActive: isMainRoute,
      isPathToRoute: isPathToRoute,
      touchArea: touchAreaLine,
    );
  }

  _onLineTapped(Line line) async {
    RouteLine routeLine = routeLines.getRouteLine(line);
    _updateLines(routeLine);
    Route route = await routeManager.getRoute(routeLine.routeName);
    List<Route> similarRoutes = await routeManager.getSimilarRoutes(route);
    parent.changeActiveRoute(route, similarRoutes);
    setState(() {
      _mapController.updateLine(line, LineOptions());
    });
  }

  _updateLines(RouteLine newActiveLine) async {
    if (newActiveLine != routeLines.activeLine) {
      _mapController.clearSymbols();

      RouteLine previousActiveLine = routeLines.activeLine;
      await _deactivateRouteLine(previousActiveLine);
      _activateRouteLine(newActiveLine);
      drawRouteStartAndEndIcons(
        newActiveLine.route.options.geometry.first,
        newActiveLine.route.options.geometry.last,
      );
      _searchWidgetStateKey.currentState
          .setActiveQuery(newActiveLine.routeName);
    }
  }

  _deactivateRouteLine(RouteLine routeLine) async {
    if (Platform.isLinux) {
      _mapController.updateLine(
          routeLine.route, LineOptions(lineColor: secondaryRouteColor));
      routeLine.route = Line(
          routeLine.route.id,
          routeLine.route.options
              .copyWith(LineOptions(lineColor: secondaryRouteColor)));
      routeLine.route = _mapController.lines
          .firstWhere((element) => element.id == routeLine.route.id);
    } else {
      for (Line line in routeLine.getLines()) {
        _mapController.removeLine(line);
      }
      routeLines.routeLines.remove(routeLine);
      await _drawRoute(
        routeName: routeLine.routeName,
        lineCoordinateList: routeLine.route.options.geometry,
        isMainRoute: false,
      );
    }
  }

  _activateRouteLine(RouteLine routeLine) {
    if (Platform.isLinux) {
      _mapController.updateLine(
          routeLine.touchArea, LineOptions(lineColor: routeTouchAreaColor));
      _mapController.updateLine(
          routeLine.background, LineOptions(lineColor: routeBorderColor));
      _mapController.updateLine(
          routeLine.route, LineOptions(lineColor: primaryRouteColor));
    } else {
      for (Line line in routeLine.getLines()) {
        _mapController.removeLine(line);
      }
      routeLines.routeLines.remove(routeLine);
      _drawRoute(
          routeName: routeLine.routeName,
          lineCoordinateList: routeLine.route.options.geometry,
          isMainRoute: true);
    }

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

  _clearPathToRoute() {
    for (Line line in routeLines.pathToRouteLine.getLines()) {
      _mapController.removeLine(line);
    }
    routeLines.pathToRouteLine = null;
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

  clearActiveDrawings() async {
    await _mapController.clearLines();
    _mapController.clearCircles();
    _mapController.clearSymbols();
    parent.hideBottomDrawer();
    _currentBounds = null;
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
