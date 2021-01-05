import 'dart:math';

import 'package:bike_gps/widgets/map_view/map_widget.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:gpx/gpx.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:route_parser/models/route.dart';

class MapboxMapWidget extends StatefulWidget {
  final MapState parent;

  MapboxMapWidget({Key key, this.parent}) : super(key: key);

  @override
  State createState() => MapboxMapState(parent);
}

class MapboxMapState extends State<MapboxMapWidget> {
  final MapState parent;
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
    if (parent.useMapbox) {
      return MapboxStyles.OUTDOORS;
    } else {
      return parent.styleStrings[_currentStyleStringName];
    }
  }

  _onMapCreated(MapboxMapController controller) {
    _mapController = controller;
  }

  updateCameraPosition(CameraUpdate cameraUpdate) {
    _mapController.updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    _mapController.moveCamera(cameraUpdate);
  }

  drawRoute(Route route) {
    _mapController.addLine(
      LineOptions(
        geometry: getTrackAsList(route),
      ),
    );
  }

  getTrackAsList(Route route) {
    List<LatLng> trackList = [];

    for (Wpt trackPoint in route.trackPoints) {
      trackList.add(LatLng(trackPoint.lat, trackPoint.lon));
    }

    return trackList;
  }
}
