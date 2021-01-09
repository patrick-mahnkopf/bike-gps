import 'dart:math';
import 'dart:typed_data';

import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/widgets/map_view/map_widget.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart';
import 'package:route_parser/models/route.dart';

class MapboxMapWidget extends StatefulWidget {
  final MapState parent;
  final RouteManager routeManager;

  MapboxMapWidget({Key key, this.parent, this.routeManager}) : super(key: key);

  @override
  State createState() => MapboxMapState(parent, routeManager);
}

class MapboxMapState extends State<MapboxMapWidget> {
  final MapState parent;
  final RouteManager routeManager;
  MapboxMapController _mapController;
  String _currentStyleStringName;
  MapboxMap mapboxMap;
  List<String> assetImages = ['start_location.png', 'end_location.png'];

  MapboxMapState(this.parent, this.routeManager) {
    _currentStyleStringName = parent.styleStringNames[0];
  }

  @override
  Widget build(BuildContext context) {
    mapboxMap = MapboxMap(
      accessToken: parent.mapboxAccessToken,
      onMapCreated: _onMapCreated,
      styleString: _getCurrentStyleString(),
      compassViewPosition: CompassViewPosition.BottomRight,
      compassViewMargins: new Point(32, 32),
      myLocationEnabled: true,
      myLocationRenderMode: MyLocationRenderMode.COMPASS,
      myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
      initialCameraPosition:
          const CameraPosition(target: LatLng(52.3825, 9.7177), zoom: 14),
    );

    return mapboxMap;
  }

  changeStyle(String styleName) {
    setState(() {
      _currentStyleStringName = styleName;
    });
  }

  String _getCurrentStyleString() {
    if (parent.useMapbox) {
      return MapboxStyles.OUTDOORS;
    } else {
      return parent.styleStrings[_currentStyleStringName];
    }
  }

  _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
    initImages();
  }

  initImages() async {
    for (String imageAsset in assetImages) {
      await addImageToController(imageAsset);
    }
  }

  addImageToController(String imageAsset) async {
    ByteData bytes = await rootBundle.load('assets/images/$imageAsset');
    Uint8List list = bytes.buffer.asUint8List();
    String imageName = basenameWithoutExtension(imageAsset);
    _mapController.addImage(imageName, list);
  }

  updateCameraPosition(CameraUpdate cameraUpdate) {
    _mapController.updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    _mapController.moveCamera(CameraUpdate.bearingTo(0));
    _mapController.animateCamera(cameraUpdate);
  }

  drawRoute(Route route) {
    clearAllDrawnRoutes();

    _mapController.addLine(
      LineOptions(
        geometry: routeManager.getTrackAsList(route),
      ),
    );

    drawStartAndEndIcons(route);
    moveCameraToRouteBounds(route);
  }

  clearAllDrawnRoutes() {
    _mapController.clearLines();
    _mapController.clearCircles();
    _mapController.clearSymbols();
  }

  drawStartAndEndIcons(Route route) {
    LatLng startPoint = LatLng(
      route.trackPoints.first.lat,
      route.trackPoints.first.lon,
    );
    LatLng endPoint = LatLng(
      route.trackPoints.last.lat,
      route.trackPoints.last.lon,
    );

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

  moveCameraToRouteBounds(Route route) {
    LatLngBounds routeBounds = routeManager.getRouteBounds(route);
    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(routeBounds);
    updateCameraPosition(cameraUpdate);
  }
}
