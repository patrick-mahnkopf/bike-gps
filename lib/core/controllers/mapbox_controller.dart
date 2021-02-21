import 'package:bike_gps/features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../injection_container.dart';

const String _mapStringsBasePath = 'assets/tokens/';
const bool _useMapbox = false;

@singleton
class MapboxController {
  final String accessToken;
  final String activeStyleString;
  final bool compassEnabled;
  final CameraPosition initialCameraPosition;
  final MyLocationRenderMode locationRenderMode;
  final MapboxMapController mapboxMapController;
  final Map<String, String> styleStrings;
  final MyLocationTrackingMode myLocationTrackingMode;

  MapboxController(
      {this.mapboxMapController,
      @required this.accessToken,
      @required this.activeStyleString,
      @required this.compassEnabled,
      @required this.locationRenderMode,
      @required this.initialCameraPosition,
      @required this.styleStrings,
      @required this.myLocationTrackingMode});

  MapboxController copyWith(
      {String accessToken,
      String activeStyleString,
      bool compassEnabled,
      MyLocationRenderMode locationRenderMode,
      CameraPosition initialCameraPosition,
      MapboxMapController mapboxMapController,
      MyLocationTrackingMode myLocationTrackingMode}) {
    return MapboxController(
      mapboxMapController: mapboxMapController ?? this.mapboxMapController,
      accessToken: accessToken ?? this.accessToken,
      activeStyleString: activeStyleString ?? this.activeStyleString,
      compassEnabled: compassEnabled ?? this.compassEnabled,
      locationRenderMode: locationRenderMode ?? this.locationRenderMode,
      initialCameraPosition:
          initialCameraPosition ?? this.initialCameraPosition,
      myLocationTrackingMode:
          myLocationTrackingMode ?? this.myLocationTrackingMode,
      styleStrings: styleStrings,
    );
  }

  @factoryMethod
  static Future<MapboxController> create() async {
    final String accessToken = await _getMapboxAccessToken();
    final Map<String, String> styleStrings = await _getStyleStrings();
    final CameraPosition initialCameraPosition =
        await _getInitialCameraPosition();

    return MapboxController(
        accessToken: accessToken,
        styleStrings: styleStrings,
        activeStyleString: styleStrings.values.first,
        compassEnabled: true,
        initialCameraPosition: initialCameraPosition,
        locationRenderMode: MyLocationRenderMode.COMPASS,
        myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass);
  }

  static Future<String> _getMapboxAccessToken() async {
    if (_useMapbox) {
      return rootBundle
          .loadString('${_mapStringsBasePath}mapbox_access_token.txt');
    } else {
      return 'random_string';
    }
  }

  static Future<Map<String, String>> _getStyleStrings() async {
    return {
      'vector': await rootBundle
          .loadString('${_mapStringsBasePath}vector_style_string.txt'),
      'raster': await rootBundle
          .loadString('${_mapStringsBasePath}raster_style_string.txt')
    };
  }

  static Future<CameraPosition> _getInitialCameraPosition() async {
    final LocationData locationData = await getIt<Location>().getLocation();
    return CameraPosition(
        target: LatLng(locationData.latitude, locationData.longitude),
        zoom: 14);
  }

  void recenterMap() {
    final MapboxState mapboxState = getIt<MapboxBloc>().state;
    if (mapboxState is MapboxLoadSuccess && mapboxMapController != null) {
      mapboxMapController
          .updateMyLocationTrackingMode(MyLocationTrackingMode.TrackingCompass);
      getIt<MapboxBloc>().add(MapboxLoaded(
          mapboxController: copyWith(
              myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass)));
    }
  }

  bool get canRecenterMap {
    final MapboxState mapboxState = getIt<MapboxBloc>().state;
    return mapboxState is MapboxLoadSuccess &&
        mapboxMapController != null &&
        myLocationTrackingMode != MyLocationTrackingMode.TrackingCompass;
  }
}
