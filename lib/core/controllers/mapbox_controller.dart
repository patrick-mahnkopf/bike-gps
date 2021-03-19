import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/domain/entities/search/entities.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/presentation/blocs/search/search_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;

import '../../injection_container.dart';

const String _mapStringsBasePath = 'assets/tokens/';
const bool _useMapbox = false;

@singleton
class MapboxController {
  final String accessToken;
  String activeStyleString;
  final bool compassEnabled;
  final CameraPosition initialCameraPosition;
  MyLocationRenderMode locationRenderMode;
  MapboxMapController mapboxMapController;
  final Map<String, String> styleStrings;
  double devicePixelRatio;
  MyLocationTrackingMode myLocationTrackingMode;
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

  Future<FunctionResult> onStyleLoaded() async {
    // TODO use or remove (currently unused)
    final List<String> symbolPaths = await _getSymbolPaths();
    for (final String symbolPath in symbolPaths) {
      await _addImageToController(
        symbolPath,
      );
    }
    return FunctionResultSuccess();
  }

  Future<List<String>> _getSymbolPaths() async {
    final Map<String, dynamic> manifestMap =
        jsonDecode(await rootBundle.loadString('AssetManifest.json'))
            as Map<String, dynamic>;
    final String mapSymbolsPath = ConstantsHelper.mapSymbolPath;
    final Iterable<String> symbolPaths =
        manifestMap.keys.where((String key) => key.contains(mapSymbolsPath));

    final List<String> turnArrowPaths = [];
    for (final String symbolPath in symbolPaths) {
      final String cleanSymbolPath = symbolPath.replaceAll('%20', ' ');
      turnArrowPaths.add(cleanSymbolPath);
    }
    return turnArrowPaths;
  }

  Future<FunctionResult> _addImageToController(String imagePath) async {
    try {
      ByteData bytes;
      // TODO make loading of svg work
      if (p.extension(imagePath) == '.svg') {
        final String svgString = await rootBundle.loadString(imagePath);
        final DrawableRoot svgRoot = await svg.fromSvgString(svgString, "");
        final ui.Picture picture = svgRoot.toPicture(
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn));
        final ui.Image image = await picture.toImage(50, 50);
        bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      } else {
        bytes = await rootBundle.load(imagePath);
      }
      final Uint8List list = bytes.buffer.asUint8List();
      final String imageName = p.basenameWithoutExtension(imagePath);
      await mapboxMapController.addImage(imageName, list);
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
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
      if (tourLines.isNotEmpty) {
        await onTourDismissed();
      }
      if (alternativeTours != null && alternativeTours.isNotEmpty) {
        await drawAlternativeTours(alternativeTours);
        await animateCameraToTourBounds(
            tour: tour, alternativeTours: alternativeTours);
      } else {
        await animateCameraToTourBounds(tour: tour);
      }
      await _drawMainTour(
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

  // TODO use for debugging or remove
  Future<FunctionResult> _markWayPoints(Tour tour) async {
    if (debugMarkings.isNotEmpty) {
      mapboxMapController.removeSymbols(debugMarkings);
      debugMarkings.removeRange(0, debugMarkings.length);
    }
    for (int i = 0; i < tour.wayPoints.length; i++) {
      final LatLng geometry = tour.wayPoints[i].latLng;
      debugMarkings.add(await mapboxMapController.addSymbol(SymbolOptions(
        iconImage: 'end_location',
        iconSize: 0.25,
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

  Future<FunctionResult> animateCameraToTourBounds(
      {@required Tour tour, List<Tour> alternativeTours}) async {
    await mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    LatLngBounds bounds;
    if (alternativeTours != null && alternativeTours.isNotEmpty) {
      bounds = _getCombinedBounds(tour, alternativeTours);
    } else {
      bounds = tour.bounds;
    }
    final CameraUpdate cameraUpdate = _getCameraUpdateFromBounds(bounds);
    await _animateCamera(cameraUpdate);
    return FunctionResultSuccess();
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
    const String secondaryTourColor = '#aab7b8 ';

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
    final String mapSymbolPath = ConstantsHelper.mapSymbolPath;
    activeTourSymbols.add(await mapboxMapController.addSymbol(SymbolOptions(
      iconImage: p.join(mapSymbolPath, 'start_location.png'),
      iconSize: 0.75,
      iconAnchor: 'bottom',
      geometry: startPoint,
      textField: 'Start',
      textOffset: const Offset(0, 1),
      textAnchor: 'bottom',
    )));
    activeTourSymbols.add(await mapboxMapController.addSymbol(SymbolOptions(
      iconImage: p.join(mapSymbolPath, 'end_location.png'),
      iconSize: 0.75,
      iconAnchor: 'bottom',
      geometry: endPoint,
      textField: 'End',
      textOffset: const Offset(0, 1),
      textAnchor: 'bottom',
    )));
    return FunctionResultSuccess();
  }

  Future<FunctionResult> onLineTapped(Line line) async {
    for (final TourLine tourLine in tourLines) {
      if (tourLine.tour.options.geometry == line.options.geometry &&
          !tourLine.isActive &&
          !tourLine.isPathToTour) {
        searchBloc.searchBarController.query = tourLine.tourName;
        tourBloc.add(
            TourLoaded(tourName: tourLine.tourName, mapboxController: this));
        break;
      }
    }
    return FunctionResultSuccess();
  }

  Future<FunctionResult> onTourDismissed() async {
    await _clearActiveDrawings();
    tourLines.clear();
    activeTourSymbols.clear();
    return FunctionResultSuccess();
  }

  Future<FunctionResult> _clearActiveDrawings() async {
    await mapboxMapController.clearLines();
    await mapboxMapController.clearCircles();
    await mapboxMapController.clearSymbols();
    return FunctionResultSuccess();
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
    if (mapboxMapController.lines.contains(line)) {
      final Line lineResult = mapboxMapController.lines.firstWhere((element) =>
          element.options.geometry == line.options.geometry &&
          element.options.lineColor == line.options.lineColor);
      await mapboxMapController.removeLine(lineResult);
    }
    return FunctionResultSuccess();
  }

  Future<FunctionResult> _moveCamera(CameraUpdate cameraUpdate) async {
    await mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    await mapboxMapController.moveCamera(CameraUpdate.bearingTo(0));
    await mapboxMapController.moveCamera(cameraUpdate);
    return FunctionResultSuccess();
  }

  Future<FunctionResult> _animateCamera(CameraUpdate cameraUpdate) async {
    await mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    await mapboxMapController.moveCamera(CameraUpdate.bearingTo(0));
    await mapboxMapController.animateCamera(cameraUpdate);
    return FunctionResultSuccess();
  }

  Future<FunctionResult> _drawPlaceIcon(LatLng coordinates) async {
    try {
      final String mapSymbolPath = ConstantsHelper.mapSymbolPath;
      await mapboxMapController.addSymbol(SymbolOptions(
        iconImage: p.join(mapSymbolPath, 'end_location.png'),
        iconSize: 0.75,
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
