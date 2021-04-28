import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/domain/entities/search/entities.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/presentation/blocs/search/search_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:bike_gps/features/presentation/widgets/mapbox_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;

import '../../injection_container.dart';

const String _mapStringsBasePath = 'assets/tokens/';
const bool _useMapbox = false;

/// Controls the Mapbox map.
///
/// Combines functions of the [MapboxMapController] and the [MapboxWidget] as
/// well as custom ones.
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

  /// Initializes the map.
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

  /// Returns the Mapbox access token.
  ///
  /// Returns a random string if the Mapbox API isn't used, as this is required
  /// by Mapbox.
  static Future<String> _getMapboxAccessToken() async {
    if (_useMapbox) {
      return rootBundle
          .loadString(p.join(_mapStringsBasePath, 'mapbox_access_token.txt'));
    } else {
      return 'random_string';
    }
  }

  /// Returns the style strings available to the Mapbox map.
  static Future<Map<String, String>> _getStyleStrings() async {
    return {
      'vector': await rootBundle
          .loadString(p.join(_mapStringsBasePath, 'vector_style_string.txt')),
      'raster': await rootBundle
          .loadString(p.join(_mapStringsBasePath, 'raster_style_string.txt')),
    };
  }

  /// Gets the current user location as the initial map camera position.
  static Future<CameraPosition> _getInitialCameraPosition(
      ConstantsHelper constantsHelper) async {
    final LocationData locationData = await getIt<Location>().getLocation();
    return CameraPosition(
        target: LatLng(locationData.latitude, locationData.longitude),
        zoom: constantsHelper.tourViewZoom);
  }

  /// Handles the selection of a place in the search bar.
  ///
  /// Draws an icon at the [searchResult] location and moves the map camera
  /// there.
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

  /// Handles the selection of a tour in the search bar.
  ///
  /// Draws the [tour] and all [alternativeTours] on the map and moves the
  /// camera to their combined bounds. Removes all previously drawn objects.
  Future<FunctionResult> onSelectTour(
      {@required Tour tour, List<Tour> alternativeTours}) async {
    try {
      /// Removes all previously drawn objects.
      if (tourLines.isNotEmpty) {
        await onTourDismissed();
      }

      /// Draws all alternative tours and moves the camera to their combined
      /// bounds.
      if (alternativeTours != null && alternativeTours.isNotEmpty) {
        await drawAlternativeTours(alternativeTours);
        await animateCameraToTourBounds(
            tour: tour, alternativeTours: alternativeTours);

        /// Moves the camera to the tour bounds.
      } else {
        await animateCameraToTourBounds(tour: tour);
      }

      /// Draws the main tour.
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

  /// Draws the main tour track and a start and end icon on the map.
  ///
  /// Adds the drawn lines to [tourLines]. Returns a [FunctionResultFailure] on
  /// error.
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

  /// Draws all alternative tour tracks on the map.
  ///
  /// Adds the drawn lines to [tourLines]. Returns a [FunctionResultFailure] on
  /// error.
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

  /// Draws the [pathToTour] on the map.
  ///
  /// Clears all previous paths to tour. Returns a [FunctionResultFailure] on
  /// error.
  Future<FunctionResult> addPathToTour(Tour pathToTour) async {
    try {
      clearPathToTour();
      _drawPathToTour(pathToTour);
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  /// Draws the [pathToTour] on the map.
  ///
  /// Returns a [FunctionResultFailure] on error.
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

  /// Moves the camera to the tour bounds with an animation.
  ///
  /// Combines the bounds of the [tour] with those of the [alternativeTours] if
  /// they exist.
  Future<FunctionResult> animateCameraToTourBounds(
      {@required Tour tour, List<Tour> alternativeTours}) async {
    /// Stops tracking the user location.
    await mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    LatLngBounds bounds;

    /// Combines the bounds of all tours if alternative tours exist.
    if (alternativeTours != null && alternativeTours.isNotEmpty) {
      bounds = _getCombinedBounds(tour, alternativeTours);
    } else {
      bounds = tour.bounds;
    }
    final CameraUpdate cameraUpdate = _getCameraUpdateFromBounds(bounds);
    await _animateCamera(cameraUpdate);
    return FunctionResultSuccess();
  }

  /// Combines the bounds of the [tour] with those of all [alternativeTours].
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

  /// Converts the [bounds] to a [CameraUpdate] with offsets for map movement.
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

  /// Draws the tour along the [lineCoordinateList].
  ///
  /// The tour line color depends on whether this tour is the main one, the
  /// path to a tour, or an alternative one. Returns a [TourLine] containing
  /// the actual tour line, the background line and the touch area line.
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
    const String secondaryTourColor = '#aab7b8';

    /// Adds a background line to create a black border for the tour line.
    final Line backgroundLine = await mapboxMapController.addLine(
      LineOptions(
        geometry: lineCoordinateList,
        lineWidth: lineBorder,
        lineColor: backgroundLineColor,
        lineOpacity: 0.8,
        lineGapWidth: lineWidth,
      ),
    );

    /// The actual tour line. The color depends on whether this is the main one,
    /// the path to a tour, or an alternative one.
    final Line tourLine = await mapboxMapController.addLine(
      LineOptions(
        geometry: lineCoordinateList,
        lineWidth: lineWidth,
        lineColor:
            isMainTour || isPathToTour ? primaryTourColor : secondaryTourColor,
      ),
    );

    /// An invisible line to enlarge the touch area for easier tapping.
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

  /// Draws a start icon at [startPoint] and an end icon at [endPoint].
  ///
  /// The icons are added to [activeTourSymbols].
  Future<FunctionResult> _drawTourStartAndEndIcons(
      LatLng startPoint, LatLng endPoint) async {
    final String mapSymbolPath = ConstantsHelper.mapSymbolPath;

    /// Draws the start icon.
    activeTourSymbols.add(await mapboxMapController.addSymbol(SymbolOptions(
      iconImage: p.join(mapSymbolPath, 'start_location.png'),
      iconSize: 0.75,
      iconAnchor: 'bottom',
      geometry: startPoint,
      textField: 'Start',
      textOffset: const Offset(0, 1),
      textAnchor: 'bottom',
    )));

    /// Draws the end icon.
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

  /// Handles the tap on the [line].
  Future<FunctionResult> onLineTapped(Line line) async {
    /// Finds the TourLine belonging to the line that has been tapped.
    for (final TourLine tourLine in tourLines) {
      /// Checks if this is the correct TourLine and if it can handle taps.
      if (tourLine.tour.options.geometry == line.options.geometry &&
          !tourLine.isActive &&
          !tourLine.isPathToTour) {
        /// Changes the search bar query to this tour's name.
        searchBloc.searchBarController.query = tourLine.tourName;

        /// Loads the tapped tour.
        tourBloc.add(
            TourLoaded(tourName: tourLine.tourName, mapboxController: this));
        break;
      }
    }
    return FunctionResultSuccess();
  }

  /// Clears all drawings, [TourLine]s and active tour symbols.
  Future<FunctionResult> onTourDismissed() async {
    await _clearActiveDrawings();
    tourLines.clear();
    activeTourSymbols.clear();
    return FunctionResultSuccess();
  }

  /// Clears all drawings.
  ///
  /// Clears all lines, circles and symbols on the map.
  Future<FunctionResult> _clearActiveDrawings() async {
    await mapboxMapController.clearLines();
    await mapboxMapController.clearCircles();
    await mapboxMapController.clearSymbols();
    return FunctionResultSuccess();
  }

  /// Clears all drawings of alternative tours on the map.
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

  /// Clears all drawings of paths to tours on the map.
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

  /// Removes the [tourLine] from the map and from [tourLines].
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

  /// Removes the [line] from the map.
  Future<FunctionResult> _removeLine(Line line) async {
    if (mapboxMapController.lines.contains(line)) {
      /// Finds the correct line saved in the mapboxMapController.
      final Line lineResult = mapboxMapController.lines.firstWhere((element) =>
          element.options.geometry == line.options.geometry &&
          element.options.lineColor == line.options.lineColor);
      await mapboxMapController.removeLine(lineResult);
    }
    return FunctionResultSuccess();
  }

  /// Jumps the camera to the location described by the [cameraUpdate].
  ///
  /// Disables location tracking. Resets the bearing to 0.
  Future<FunctionResult> _moveCamera(CameraUpdate cameraUpdate) async {
    await mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    await mapboxMapController.moveCamera(CameraUpdate.bearingTo(0));
    await mapboxMapController.moveCamera(cameraUpdate);
    return FunctionResultSuccess();
  }

  /// Animates the camera to the location described by the [cameraUpdate].
  ///
  /// Disables location tracking. Resets the bearing to 0.
  Future<FunctionResult> _animateCamera(CameraUpdate cameraUpdate) async {
    await mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    await mapboxMapController.moveCamera(CameraUpdate.bearingTo(0));
    await mapboxMapController.animateCamera(cameraUpdate);
    return FunctionResultSuccess();
  }

  /// Draws a place icon at the [coordinates].
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
