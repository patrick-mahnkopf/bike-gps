import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class MapboxController {
  final String accessToken;
  final String activeStyleString;
  final bool compassEnabled;
  final CameraPosition initialCameraPosition;
  final MyLocationRenderMode locationRenderMode;
  final MapboxMapController mapboxMapController;
  final Map<String, String> styleStrings;

  MapboxController(
      {this.mapboxMapController,
      @required this.accessToken,
      @required this.activeStyleString,
      @required this.compassEnabled,
      @required this.locationRenderMode,
      @required this.initialCameraPosition,
      @required this.styleStrings});

  MapboxController copyWith(
          {String accessToken,
          String activeStyleString,
          bool compassEnabled,
          MyLocationRenderMode locationRenderMode,
          CameraPosition initialCameraPosition,
          MapboxMapController mapboxMapController}) =>
      MapboxController(
        mapboxMapController: mapboxMapController ?? this.mapboxMapController,
        accessToken: accessToken ?? this.accessToken,
        activeStyleString: activeStyleString ?? this.activeStyleString,
        compassEnabled: compassEnabled ?? this.compassEnabled,
        locationRenderMode: locationRenderMode ?? this.locationRenderMode,
        initialCameraPosition:
            initialCameraPosition ?? this.initialCameraPosition,
        styleStrings: styleStrings,
      );

  void recenterMap() {
    mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.TrackingCompass);
  }
}
