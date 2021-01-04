import 'dart:math';

import 'package:bike_gps/widgets/map_widget.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class MapboxMapWidget extends StatefulWidget {
  final FullMapState parent;

  MapboxMapWidget({Key key, this.parent}) : super(key: key);

  @override
  State createState() => MapboxMapState(parent);
}

class MapboxMapState extends State<MapboxMapWidget> {
  final FullMapState parent;
  MapboxMapController _mapController;
  String _currentStyleStringName;
  MapboxMap mapboxMap;

  MapboxMapState(this.parent) {
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
    return parent.styleStrings[_currentStyleStringName];
  }

  _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
  }

  updateCameraPosition(CameraUpdate cameraUpdate) {
    _mapController.updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    _mapController.moveCamera(cameraUpdate);
  }
}
