import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/features/domain/entities/search/entities.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
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
  final ConstantsHelper constantsHelper;
  final List<TourLine> tourLines = [];

  MapboxController(
      {this.mapboxMapController,
      @required this.accessToken,
      @required this.activeStyleString,
      @required this.compassEnabled,
      @required this.locationRenderMode,
      @required this.initialCameraPosition,
      @required this.styleStrings,
      @required this.myLocationTrackingMode,
      @required this.constantsHelper});

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
      constantsHelper: constantsHelper,
    );
  }

  @factoryMethod
  static Future<MapboxController> create(
      {@required ConstantsHelper constantsHelper}) async {
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
        myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
        constantsHelper: constantsHelper);
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

  // void recenterMap(BuildContext context) {
  //   final MapboxBloc mapboxBloc = BlocProvider.of<MapboxBloc>(context);
  //   if (mapboxBloc.state is MapboxLoadSuccess && mapboxMapController != null) {
  //     mapboxMapController
  //         .updateMyLocationTrackingMode(MyLocationTrackingMode.TrackingCompass);
  //     mapboxBloc.add(MapboxLoaded(
  //         mapboxController: copyWith(
  //             myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass)));
  //   }
  // }

  // bool canRecenterMap(BuildContext context) {
  //   return BlocProvider.of<MapboxBloc>(context).state is MapboxLoadSuccess &&
  //       mapboxMapController != null &&
  //       myLocationTrackingMode != MyLocationTrackingMode.TrackingCompass;
  // }

  Future<FunctionResult> onSelectPlace(SearchResult searchResult) async {
    try {
      final CameraUpdate cameraUpdate =
          CameraUpdate.newLatLngZoom(searchResult.coordinates, 14);
      _animateCamera(cameraUpdate);
      await _drawPlaceIcon(searchResult.coordinates);
    } on Exception catch (exception, stacktrace) {
      return FunctionResultFailure(
          error: exception,
          stackTrace: stacktrace,
          name: 'Mapbox Controller onSelectPlace');
    }
    return FunctionResultSuccess();
  }

  Future<FunctionResult> onSelectTour(Tour tour) async {
    try {
      tourLines.add(await _drawTour(tour: tour, isMainTour: true));
      await _drawTourStartAndEndIcons(
        tour.trackPoints.first.latLng,
        tour.trackPoints.last.latLng,
      );
      animateCameraToTourBounds(tour);
    } on Exception catch (exception, stacktrace) {
      return FunctionResultFailure(
          error: exception,
          stackTrace: stacktrace,
          name: 'Mapbox Controller onSelectTour');
    }
    return FunctionResultSuccess();
  }

  void animateCameraToTourBounds(Tour tour) {
    mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    final CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(tour.bounds);
    _animateCamera(cameraUpdate);
  }

  Future<TourLine> _drawTour({
    @required Tour tour,
    bool isMainTour = false,
    bool isPathToTour = false,
  }) async {
    const double lineWidth = 6;
    const double lineBorder = 2;
    const double touchAreaWidth = 36;
    const String touchAreaColor = '#00ff00';
    const String backgroundLineColor = '#000000';
    const String primaryTourColor = '#0099ff';
    const String secondaryTourColor = '#00ff00';
    final List<LatLng> lineCoordinateList =
        tour.trackPoints.map((trackPoint) => trackPoint.latLng).toList();

    final Line touchAreaLine = await mapboxMapController.addLine(
      LineOptions(
        geometry: lineCoordinateList,
        lineWidth: touchAreaWidth,
        lineColor: touchAreaColor,
        lineOpacity: 0,
      ),
    );
    final Line backgroundLine = await mapboxMapController.addLine(
      LineOptions(
        geometry: lineCoordinateList,
        lineWidth: lineBorder,
        lineColor: backgroundLineColor,
        lineOpacity: 0.8,
        lineGapWidth: lineWidth,
      ),
    );
    final Line tourLine = await mapboxMapController.addLine(
      LineOptions(
        geometry: lineCoordinateList,
        lineWidth: lineWidth,
        lineColor: isMainTour ? primaryTourColor : secondaryTourColor,
      ),
    );

    return TourLine(
      tourName: tour.name,
      background: backgroundLine,
      route: tourLine,
      isActive: isMainTour,
      isPathToTour: isPathToTour,
      touchArea: touchAreaLine,
    );
  }

  Future<FunctionResult> _drawTourStartAndEndIcons(
      LatLng startPoint, LatLng endPoint) async {
    mapboxMapController.addSymbol(SymbolOptions(
      iconImage: 'start_location',
      iconSize: 0.1,
      iconOffset: const Offset(0, 15),
      iconAnchor: 'bottom',
      geometry: startPoint,
      textField: 'Start',
      textOffset: const Offset(0, -1.6),
      textAnchor: 'bottom',
    ));
    mapboxMapController.addSymbol(SymbolOptions(
      iconImage: 'end_location',
      iconSize: 0.12,
      iconOffset: const Offset(0, 15),
      iconAnchor: 'bottom',
      geometry: endPoint,
      textField: 'End',
      textOffset: const Offset(0, -1.7),
      textAnchor: 'bottom',
    ));
    return FunctionResultSuccess();
  }

  void onLineTapped(Line line) {
    // TODO implement onLineTapped
  }

  void onTourDismissed() {
    _clearActiveDrawings();
  }

  void _clearActiveDrawings() {
    mapboxMapController.clearLines();
    mapboxMapController.clearCircles();
    mapboxMapController.clearSymbols();
  }

  void _moveCamera(CameraUpdate cameraUpdate) {
    mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    mapboxMapController.moveCamera(CameraUpdate.bearingTo(0));
    mapboxMapController.moveCamera(cameraUpdate);
  }

  void _animateCamera(CameraUpdate cameraUpdate) {
    mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    mapboxMapController.moveCamera(CameraUpdate.bearingTo(0));
    mapboxMapController.animateCamera(cameraUpdate);
  }

  Future<FunctionResult> _drawPlaceIcon(LatLng coordinates) async {
    try {
      await mapboxMapController.addSymbol(SymbolOptions(
        iconImage: 'place_pin',
        iconSize: 0.1,
        iconOffset: const Offset(0, 15),
        iconAnchor: 'bottom',
        geometry: coordinates,
      ));
    } on Exception catch (exception, stacktrace) {
      return FunctionResultFailure(
          error: exception, stackTrace: stacktrace, name: 'Mapbox Controller');
    }
    return FunctionResultSuccess();
  }
}
