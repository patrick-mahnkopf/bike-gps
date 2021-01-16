import 'dart:math';
import 'dart:typed_data';

import 'package:bike_gps/model/map_resources.dart';
import 'package:bike_gps/model/place.dart';
import 'package:bike_gps/routeManager.dart';
import 'package:bike_gps/widget/map_view/map_style_list_widget.dart';
import 'package:flutter/cupertino.dart' hide Route;
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/services.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart';
import 'package:route_parser/models/route.dart';

class MapboxMapWidget extends StatefulWidget {
  final RouteManager routeManager;
  final MapResources mapResources;

  MapboxMapWidget(
      {@required Key key,
      @required this.routeManager,
      @required this.mapResources})
      : super(key: key);

  @override
  State createState() => MapboxMapState(routeManager, mapResources);
}

class MapboxMapState extends State<MapboxMapWidget> {
  final RouteManager routeManager;
  final MapResources mapResources;
  MapboxMapController _mapController;
  List<String> assetImages = [
    'start_location.png',
    'end_location.png',
    'place_pin.png'
  ];

  MapboxMapState(this.routeManager, this.mapResources);

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: mapResources.mapboxAccessToken,
      onMapCreated: _onMapCreated,
      styleString: mapResources.activeStyleString,
      compassViewPosition: CompassViewPosition.BottomRight,
      compassViewMargins: new Point(32, 32),
      myLocationEnabled: true,
      myLocationRenderMode: MyLocationRenderMode.COMPASS,
      myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
      initialCameraPosition:
          const CameraPosition(target: LatLng(52.3825, 9.7177), zoom: 14),
    );
  }

  _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
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

  onSelectPlace(Place place) {
    CameraUpdate cameraUpdate = getCameraUpdateFromPlace(place);
    updateCameraPosition(cameraUpdate);
    drawPlaceIcon(place);
  }

  CameraUpdate getCameraUpdateFromPlace(Place place) {
    return CameraUpdate.newLatLngZoom(place.coordinates, 14);
  }

  updateCameraPosition(CameraUpdate cameraUpdate) {
    _mapController.updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    _mapController.moveCamera(CameraUpdate.bearingTo(0));
    _mapController.animateCamera(cameraUpdate);
  }

  onSelectRoute(String routeName) async {
    Route route = await routeManager.getRoute(routeName);
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
      drawRoute(route);
      displayHeightMap();
    }
  }

  drawRoute(Route route) {
    _mapController.addLine(
      LineOptions(
        geometry: routeManager.getTrackAsList(route),
      ),
    );

    drawRouteStartAndEndIcons(route);
    moveCameraToRouteBounds(route);
  }

  displayHeightMap() {}

  clearActiveDrawings() {
    _mapController.clearLines();
    _mapController.clearCircles();
    _mapController.clearSymbols();
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

  drawRouteStartAndEndIcons(Route route) {
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
