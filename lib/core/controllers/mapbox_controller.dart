import 'dart:developer';

import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/domain/entities/search/entities.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/presentation/blocs/search/search_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
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
  final TourListHelper tourListHelper;
  final SearchBloc searchBloc;
  final TourBloc tourBloc;
  final List<TourLine> tourLines = [];
  final List<Symbol> activeTourSymbols = [];
  final List<Symbol> debugMarkings = [];

  MapboxController(
      {this.mapboxMapController,
      @required this.accessToken,
      @required this.activeStyleString,
      @required this.compassEnabled,
      @required this.locationRenderMode,
      @required this.initialCameraPosition,
      @required this.styleStrings,
      @required this.myLocationTrackingMode,
      @required this.constantsHelper,
      @required this.tourListHelper,
      @required this.searchBloc,
      @required this.tourBloc});

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
        tourListHelper: tourListHelper,
        searchBloc: searchBloc,
        tourBloc: tourBloc);
  }

  @factoryMethod
  static Future<MapboxController> create(
      {@required ConstantsHelper constantsHelper,
      @required TourListHelper tourListHelper,
      @required SearchBloc searchBloc,
      @required TourBloc tourBloc}) async {
    final String accessToken = await _getMapboxAccessToken();
    final Map<String, String> styleStrings = await _getStyleStrings();
    final CameraPosition initialCameraPosition =
        await _getInitialCameraPosition(constantsHelper);

    return MapboxController(
        accessToken: accessToken,
        styleStrings: styleStrings,
        activeStyleString: styleStrings.values.first,
        compassEnabled: true,
        initialCameraPosition: initialCameraPosition,
        locationRenderMode: MyLocationRenderMode.COMPASS,
        myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
        constantsHelper: constantsHelper,
        tourListHelper: tourListHelper,
        searchBloc: searchBloc,
        tourBloc: tourBloc);
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

  static Future<CameraPosition> _getInitialCameraPosition(
      ConstantsHelper constantsHelper) async {
    final LocationData locationData = await getIt<Location>().getLocation();
    return CameraPosition(
        target: LatLng(locationData.latitude, locationData.longitude),
        zoom: constantsHelper.tourViewZoom);
  }

  Future<FunctionResult> onSelectPlace(SearchResult searchResult) async {
    try {
      final CameraUpdate cameraUpdate = CameraUpdate.newLatLngZoom(
          searchResult.coordinates, constantsHelper.tourViewZoom);
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

  Future<FunctionResult> onSelectTour(
      {@required Tour tour, List<Tour> alternativeTours}) async {
    try {
      if (alternativeTours != null && alternativeTours.isNotEmpty) {
        drawAlternativeTours(alternativeTours);
        animateCameraToTourBounds(
            tour: tour, alternativeTours: alternativeTours);
      } else {
        animateCameraToTourBounds(tour: tour);
      }
      _drawMainTour(
          coordinateList: tour.trackPointCoordinateList, tourName: tour.name);
    } on Exception catch (exception, stacktrace) {
      return FunctionResultFailure(
          error: exception,
          stackTrace: stacktrace,
          name: 'Mapbox Controller onSelectTour');
    }
    return FunctionResultSuccess();
  }

  Future<FunctionResult> _drawMainTour(
      {@required List<LatLng> coordinateList,
      @required String tourName}) async {
    try {
      tourLines.add(await _drawTour(
          lineCoordinateList: coordinateList,
          tourName: tourName,
          isMainTour: true));
      await _drawTourStartAndEndIcons(
        coordinateList.first,
        coordinateList.last,
      );
      return FunctionResultSuccess();
    } on Exception catch (exception, stacktrace) {
      return FunctionResultFailure(
          error: exception,
          stackTrace: stacktrace,
          name: 'Mapbox Controller _drawMainTour');
    }
  }

  Future<FunctionResult> drawAlternativeTours(
      List<Tour> alternativeTours) async {
    try {
      for (final Tour tour in alternativeTours) {
        tourLines.add(await _drawTour(
            lineCoordinateList: tour.trackPointCoordinateList,
            tourName: tour.name));
      }
      return FunctionResultSuccess();
    } on Exception catch (exception, stacktrace) {
      return FunctionResultFailure(
          error: exception,
          stackTrace: stacktrace,
          name: 'Mapbox Controller _drawAlternativeTours');
    }
  }

  Future<FunctionResult> addPathToTour(Tour pathToTour) async {
    try {
      clearPathToTour();
      _drawPathToTour(pathToTour);
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  Future<FunctionResult> _drawPathToTour(Tour pathToTour) async {
    try {
      tourLines.add(await _drawTour(
          lineCoordinateList: pathToTour.trackPointCoordinateList,
          tourName: pathToTour.name,
          isPathToTour: true));
      // await _markWayPoints(pathToTour);
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  Future<FunctionResult> _markWayPoints(Tour tour) async {
    if (debugMarkings.isNotEmpty) {
      mapboxMapController.removeSymbols(debugMarkings);
      debugMarkings.removeRange(0, debugMarkings.length);
    }
    for (int i = 0; i < tour.wayPoints.length; i++) {
      final LatLng geometry = tour.wayPoints[i].latLng;
      debugMarkings.add(await mapboxMapController.addSymbol(SymbolOptions(
        iconImage: 'place_pin',
        iconSize: 0.1,
        // iconOffset: const Offset(0, 15),
        iconAnchor: 'bottom',
        geometry: geometry,
        textField: '$i',
        // textOffset: const Offset(0, -1.6),
        textAnchor: 'bottom',
      )));
    }
    return FunctionResultSuccess();
  }

  void animateCameraToTourBounds(
      {@required Tour tour, List<Tour> alternativeTours}) {
    mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    LatLngBounds bounds;
    if (alternativeTours != null && alternativeTours.isNotEmpty) {
      bounds = _getCombinedBounds(tour, alternativeTours);
    } else {
      bounds = tour.bounds;
    }
    final CameraUpdate cameraUpdate = _getCameraUpdateFromBounds(bounds);
    _animateCamera(cameraUpdate);
  }

  LatLngBounds _getCombinedBounds(Tour tour, List<Tour> alternativeTours) {
    final TourBounds combinedBounds = tourListHelper.getBounds(tour.name);
    for (final Tour alternativeTour in alternativeTours) {
      final TourBounds bounds = tourListHelper.getBounds(alternativeTour.name);
      if (bounds.south < combinedBounds.south) {
        combinedBounds.south = bounds.south;
      }
      if (bounds.west < combinedBounds.west) {
        combinedBounds.west = bounds.west;
      }
      if (bounds.north > combinedBounds.north) {
        combinedBounds.north = bounds.north;
      }
      if (bounds.east > combinedBounds.east) {
        combinedBounds.east = bounds.east;
      }
    }
    return combinedBounds.bounds;
  }

  CameraUpdate _getCameraUpdateFromBounds(LatLngBounds bounds) {
    final double latOffset =
        (bounds.northeast.latitude - bounds.southwest.latitude) / 4;
    final double lonOffset =
        (bounds.northeast.longitude - bounds.southwest.longitude) / 10;

    final LatLngBounds adjustedBounds = LatLngBounds(
        southwest: LatLng(bounds.southwest.latitude - latOffset,
            bounds.southwest.longitude - lonOffset),
        northeast: LatLng(bounds.northeast.latitude + latOffset,
            bounds.northeast.longitude + lonOffset));
    return CameraUpdate.newLatLngBounds(adjustedBounds);
  }

  Future<TourLine> _drawTour({
    @required List<LatLng> lineCoordinateList,
    @required String tourName,
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
        lineColor:
            isMainTour || isPathToTour ? primaryTourColor : secondaryTourColor,
      ),
    );
    final Line touchAreaLine = await mapboxMapController.addLine(
      LineOptions(
        geometry: lineCoordinateList,
        lineWidth: touchAreaWidth,
        lineColor: touchAreaColor,
        lineOpacity: 0,
      ),
    );

    return TourLine(
      tourName: tourName,
      background: backgroundLine,
      tour: tourLine,
      isActive: isMainTour,
      isPathToTour: isPathToTour,
      touchArea: touchAreaLine,
    );
  }

  Future<FunctionResult> _drawTourStartAndEndIcons(
      LatLng startPoint, LatLng endPoint) async {
    activeTourSymbols.add(await mapboxMapController.addSymbol(SymbolOptions(
      iconImage: 'start_location',
      iconSize: 0.1,
      iconOffset: const Offset(0, 15),
      iconAnchor: 'bottom',
      geometry: startPoint,
      textField: 'Start',
      textOffset: const Offset(0, -1.6),
      textAnchor: 'bottom',
    )));
    activeTourSymbols.add(await mapboxMapController.addSymbol(SymbolOptions(
      iconImage: 'end_location',
      iconSize: 0.12,
      iconOffset: const Offset(0, 15),
      iconAnchor: 'bottom',
      geometry: endPoint,
      textField: 'End',
      textOffset: const Offset(0, -1.7),
      textAnchor: 'bottom',
    )));
    return FunctionResultSuccess();
  }

  Future<FunctionResult> onLineTapped(Line line) async {
    for (final TourLine tourLine in tourLines) {
      if (tourLine.tour.options.geometry == line.options.geometry &&
          !tourLine.isActive &&
          !tourLine.isPathToTour) {
        await _activateTourLine(tourLine);
        searchBloc.searchBarController.query = tourLine.tourName;
        tourBloc.add(
            TourLoaded(tourName: tourLine.tourName, mapboxController: this));
        break;
      }
    }
    return FunctionResultSuccess();
  }

  Future<FunctionResult> _activateTourLine(TourLine tourLine) async {
    await _deactivateActiveTourLine();
    await _removeTourLine(tourLine);
    await _removeActiveTourSymbols();
    await _drawMainTour(
        coordinateList: tourLine.tour.options.geometry,
        tourName: tourLine.tourName);
    return FunctionResultSuccess();
  }

  Future<FunctionResult> _deactivateActiveTourLine() async {
    for (final TourLine tourLine in List<TourLine>.from(tourLines)) {
      if (tourLine.isActive) {
        await _removeTourLine(tourLine);
        tourLines.add(await _drawTour(
            lineCoordinateList: tourLine.tour.options.geometry,
            tourName: tourLine.tourName));
      }
    }
    return FunctionResultSuccess();
  }

  Future<FunctionResult> _removeActiveTourSymbols() async {
    for (final Symbol symbol in List<Symbol>.from(activeTourSymbols)) {
      await mapboxMapController.removeSymbol(symbol);
      activeTourSymbols.remove(symbol);
    }
    return FunctionResultSuccess();
  }

  void onTourDismissed() {
    _clearActiveDrawings();
    tourLines.clear();
  }

  void _clearActiveDrawings() {
    mapboxMapController.clearLines();
    mapboxMapController.clearCircles();
    mapboxMapController.clearSymbols();
  }

  Future<FunctionResult> clearAlternativeTours() async {
    try {
      for (final TourLine tourLine in List<TourLine>.from(tourLines)) {
        if (!tourLine.isActive) {
          await _removeTourLine(tourLine);
        }
      }
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  Future<FunctionResult> clearPathToTour() async {
    try {
      for (final TourLine tourLine in List<TourLine>.from(tourLines)) {
        if (tourLine.isPathToTour) {
          log('pathToTour ids: background: ${tourLine.background.id}, tour: ${tourLine.tour.id}, touchArea: ${tourLine.touchArea.id}',
              name: 'MapboxController clearPathToTour');
          await _removeTourLine(tourLine);
        }
      }
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  Future<FunctionResult> _removeTourLine(TourLine tourLine) async {
    try {
      await _removeLine(tourLine.background);
      await _removeLine(tourLine.tour);
      await _removeLine(tourLine.touchArea);
      tourLines.remove(tourLine);
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  Future<FunctionResult> _removeLine(Line line) async {
    log('line: id: ${line.id}', name: 'MapboxController lines _removeLine');
    if (mapboxMapController.lines.contains(line)) {
      final Line lineResult = mapboxMapController.lines.firstWhere((element) =>
          element.options.geometry == line.options.geometry &&
          element.options.lineColor == line.options.lineColor);
      await mapboxMapController.removeLine(lineResult);
    }
    return FunctionResultSuccess();
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
