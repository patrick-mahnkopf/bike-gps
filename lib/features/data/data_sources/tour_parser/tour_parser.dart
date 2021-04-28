import 'dart:io';

import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/features/data/models/tour/tour_info_model.dart';
import 'package:flutter/widgets.dart';
import 'package:gpx/gpx.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;

import '../../models/tour/models.dart';

enum TourType { tour, route }

/// Tour file parser interface.
abstract class TourParser {
  final ConstantsHelper constantsHelper;
  final DistanceHelper distanceHelper;

  TourParser({@required this.constantsHelper, @required this.distanceHelper});

  Future<TourModel> getTour({@required File file});

  Future<TourModel> getTourFromFileContent(
      {@required String tourFileContent,
      @required String tourName,
      @required TourType tourType});

  Future<TourInfoModel> getTourInfo({@required File file});

  List<String> get fileExtensionPriority;
}

/// Class responsible for parsing gpx tour files.
@Injectable(as: TourParser, env: ["public"])
class GpxParser extends TourParser {
  GpxParser(
      {@required ConstantsHelper constantsHelper,
      @required DistanceHelper distanceHelper})
      : super(constantsHelper: constantsHelper, distanceHelper: distanceHelper);

  /// The file extensions this parser supports in its preferred order
  @override
  List<String> get fileExtensionPriority => ['.gpx', '.xml'];

  /// Returns a [TourModel] for the given tour [file].
  @override
  Future<TourModel> getTour({@required File file}) async {
    final String tourFileContent = await file.readAsString();
    final String tourName = p.basenameWithoutExtension(file.path);
    return getTourFromFileContent(
        tourFileContent: tourFileContent,
        tourName: tourName,
        tourType: TourType.tour);
  }

  /// Parses the [tourFileContent] and returns a [TourModel].
  ///
  ///
  @override
  Future<TourModel> getTourFromFileContent(
      {@required String tourFileContent,
      @required String tourName,
      @required TourType tourType}) async {
    final Gpx tourGpx = GpxReader().fromString(tourFileContent);
    double ascent = 0;
    double descent = 0;
    double tourLength = 0;
    final List<TrackPointModel> trackPoints = [];
    final List<WayPointModel> wayPoints = [];
    double previousDistanceFromStart = 0;
    final List<Wpt> combinedTourPoints = getCombinedPoints(tourGpx);
    for (int i = 0; i < combinedTourPoints.length; i++) {
      final Wpt currentPoint = combinedTourPoints[i];
      double distanceFromStart = 0;

      if (i > 0) {
        final Wpt previousPoint = combinedTourPoints[i - 1];
        final double distanceToPrevious =
            distanceHelper.distanceBetweenWpts(previousPoint, currentPoint);
        tourLength += distanceToPrevious;
        distanceFromStart = distanceToPrevious + previousDistanceFromStart;
        previousDistanceFromStart = distanceFromStart;

        if (currentPoint.ele != null && currentPoint.ele > previousPoint.ele) {
          ascent += currentPoint.ele - previousPoint.ele;
        } else {
          descent += previousPoint.ele - currentPoint.ele;
        }
      }

      if (_shouldAddWayPoint(tourType, i, combinedTourPoints, currentPoint)) {
        _addWayPoint(currentPoint, distanceFromStart, trackPoints, wayPoints);
      } else {
        _addTrackPoint(currentPoint, distanceFromStart, trackPoints);
      }
    }

    return TourModel(
      name: tourName,
      trackPoints: trackPoints,
      wayPoints: wayPoints,
      bounds: getBounds(tourGpx, trackPoints),
      ascent: ascent,
      descent: descent,
      tourLength: tourLength,
    );
  }

  /// Determines if [currentPoint] should be added as a WayPoint.
  bool _shouldAddWayPoint(TourType tourType, int i,
      List<Wpt> combinedTourPoints, Wpt currentPoint) {
    if (_isWaypoint(currentPoint)) {
      if (tourType == TourType.route) {
        return _shouldAddRouteWayPoint(i, currentPoint, combinedTourPoints);
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  /// Determines if [currentPoint] from the route service response should be
  /// added as a WayPoint.
  ///
  /// Does not add the first point. Only adds the first point for each step
  /// value. Does not add arrival type points that aren't the last point in the
  /// list.
  bool _shouldAddRouteWayPoint(
      int i, Wpt currentPoint, List<Wpt> combinedTourPoints) {
    if (i > 0) {
      final Wpt previousPoint = combinedTourPoints[i - 1];
      const orsArrivalType = '10';
      final bool isPrematureArrival =
          currentPoint.extensions['type'] == orsArrivalType &&
              i != combinedTourPoints.length - 1;

      /// Check if the currentPoint has a different step number than the
      /// previous one and is not an arrival type without being the last point
      /// in the list.
      if (currentPoint.extensions['step'] != previousPoint.extensions['step'] &&
          !isPrematureArrival) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  /// Adds a WayPoint for [currentPoint] and the corresponding TrackPoint to
  /// the respective list.
  ///
  /// Converts Wpt [currentPoint] to a TrackPoint and WayPoint and adds them to
  /// [trackPoints] and [wayPoints] respectively.
  void _addWayPoint(Wpt currentPoint, double distanceFromStart,
      List<TrackPointModel> trackPoints, List<WayPointModel> wayPoints) {
    final String direction = _getDirection(currentPoint);
    final String location = _getLocation(currentPoint);
    final String surface = _getSurface(currentPoint);
    final String turnSymbolId = _getTurnSymbolId(currentPoint);

    final WayPointModel wayPoint = WayPointModel(
      latLng: LatLng(currentPoint.lat, currentPoint.lon),
      elevation: currentPoint.ele,
      distanceFromStart: distanceFromStart,
      surface: surface,
      name: currentPoint.name ?? '',
      direction: direction,
      location: location,
      turnSymboldId: turnSymbolId,
    );
    final TrackPointModel trackPointWithWayPoint = TrackPointModel(
      latLng: LatLng(currentPoint.lat, currentPoint.lon),
      elevation: currentPoint.ele,
      isWayPoint: true,
      wayPoint: wayPoint,
      distanceFromStart: distanceFromStart,
      surface: wayPoint.surface,
    );

    trackPoints.add(trackPointWithWayPoint);
    wayPoints.add(wayPoint);
  }

  /// Adds a TrackPoint for [currentPoint] to the [trackPoints] list.
  void _addTrackPoint(Wpt currentPoint, double distanceFromStart,
      List<TrackPointModel> trackPoints) {
    final TrackPointModel trackPointWithoutWayPoint = TrackPointModel(
      latLng: LatLng(currentPoint.lat, currentPoint.lon),
      elevation: currentPoint.ele,
      isWayPoint: false,
      distanceFromStart: distanceFromStart,
      surface: 'A',
    );

    trackPoints.add(trackPointWithoutWayPoint);
  }

  /// Gets the direction of [currentPoint].
  String _getDirection(Wpt currentPoint) {
    if (currentPoint.extensions.containsKey('direction') &&
        currentPoint.extensions['direction'] != '') {
      return currentPoint.extensions['direction'];
    } else if (currentPoint.desc != null) {
      return currentPoint.desc;
    }
    return '';
  }

  /// Gets the location of [currentPoint].
  String _getLocation(Wpt currentPoint) {
    if (currentPoint.extensions.containsKey('location') &&
        currentPoint.extensions['location'] != '') {
      return currentPoint.extensions['location'];
    }
    return '';
  }

  /// Gets the surface of [currentPoint].
  String _getSurface(Wpt currentPoint) {
    if (currentPoint.extensions.containsKey('surface') &&
        currentPoint.extensions['surface'] != '') {
      return currentPoint.extensions['surface'];
    }
    return 'A';
  }

  /// Gets the turnSymbolId of [currentPoint].
  String _getTurnSymbolId(Wpt currentPoint) {
    if (currentPoint.extensions.containsKey('turnsymbolid') &&
        currentPoint.extensions['turnsymbolid'] != '') {
      return currentPoint.extensions['turnsymbolid'];
    } else if (currentPoint.extensions.containsKey('type') &&
        currentPoint.extensions['type'] != '') {
      return currentPoint.extensions['type'];
    }
    return '';
  }

  /// Gets a [TourInfoModel] of the tour [file].
  @override
  Future<TourInfoModel> getTourInfo({File file}) async {
    // TODO make more efficient by not parsing entire file
    final TourModel tourModel = await getTour(file: file);
    final String fileHash = await constantsHelper.getFileHash(file.path);

    return TourInfoModel(
        name: tourModel.name,
        filePath: file.path,
        bounds: tourModel.bounds,
        fileHash: fileHash,
        firstPoint: tourModel.trackPoints.first.latLng);
  }

  /// Checks if [point] is a waypoint.
  ///
  /// Checks if [point] has a non-empty name, description, direction, or
  /// turnSymbolId.
  bool _isWaypoint(Wpt point) {
    if (point.name != null && point.name != '') {
      return true;
    }
    if (point.desc != null && point.desc != '') {
      return true;
    }

    if (point.extensions != null) {
      if (point.extensions['direction'] != null &&
          point.extensions['direction'] != '') {
        return true;
      }
      if (point.extensions['turnsymbolid'] != null &&
          point.extensions['turnsymbolid'] != '') {
        return true;
      }
    }
    return false;
  }

  /// Gets the bounds of the [tourGpx].
  ///
  /// Gets the bounds from the gpx metadata element if it exists and is not
  /// empty. Otherwise calculates the bounds by iterating over all
  /// [trackPoints].
  LatLngBounds getBounds(Gpx tourGpx, List<TrackPointModel> trackPoints) {
    /// Returns the metadata bounds if they exist and aren't empty or only zero.
    if (tourGpx?.metadata?.bounds != null &&
        (tourGpx.metadata.bounds.maxlon - tourGpx.metadata.bounds.minlon > 0 ||
            tourGpx.metadata.bounds.maxlat - tourGpx.metadata.bounds.minlat >
                0)) {
      final Bounds bounds = tourGpx.metadata.bounds;
      return LatLngBounds(
          northeast: LatLng(bounds.maxlat, bounds.maxlon),
          southwest: LatLng(bounds.minlat, bounds.minlon));
    } else {
      final Map<String, double> extrema = {
        'north': trackPoints.first.latLng.latitude,
        'east': trackPoints.first.latLng.longitude,
        'south': trackPoints.first.latLng.latitude,
        'west': trackPoints.first.latLng.longitude,
      };

      /// Finds the extreme points of the tour and returns them as bounds.
      for (final TrackPointModel trackPoint in trackPoints) {
        if (trackPoint.latLng.latitude > extrema['north']) {
          extrema['north'] = trackPoint.latLng.latitude;
        }
        if (trackPoint.latLng.longitude > extrema['east']) {
          extrema['east'] = trackPoint.latLng.longitude;
        }
        if (trackPoint.latLng.latitude < extrema['south']) {
          extrema['south'] = trackPoint.latLng.latitude;
        }
        if (trackPoint.latLng.longitude < extrema['west']) {
          extrema['west'] = trackPoint.latLng.longitude;
        }
      }

      return LatLngBounds(
        southwest: LatLng(extrema['south'], extrema['west']),
        northeast: LatLng(extrema['north'], extrema['east']),
      );
    }
  }

  /// Returns a list of the trackpoints with the waypoints inserted at the
  /// correct locations.
  List<Wpt> getCombinedPoints(Gpx tourGpx) {
    List<Wpt> initialPoints;
    List<Wpt> wayPoints;

    /// Return routepoints if they exist.
    if (tourGpx.rtes.isNotEmpty) {
      return tourGpx.rtes.first.rtepts;
      // Return and empty list if there are neither routepoints nor trackpoints.
    } else if (tourGpx.rtes.isEmpty && tourGpx.trks.isEmpty) {
      return [];
    } else {
      initialPoints = tourGpx.trks.first.trksegs.first.trkpts;
      wayPoints = tourGpx.wpts;
    }
    final List<Wpt> combinedPoints = initialPoints;

    for (int i = 0; i < wayPoints.length; i++) {
      /// Finds index of trackPoint with lowest distance to current wayPoint.
      final Wpt wayPoint = wayPoints[i];
      double lowestDistance = double.infinity;
      int lowestDistanceIndex = -1;
      for (int j = 0; j < initialPoints.length; j++) {
        final Wpt trackPoint = initialPoints[j];
        final double distance =
            distanceHelper.distanceBetweenWpts(wayPoint, trackPoint);
        if (distance < lowestDistance) {
          lowestDistance = distance;
          lowestDistanceIndex = j;
        }
      }

      /// Inserts wayPoint at the correct position.
      /// Inserts in first position if it's closest to the first trackPoint.
      if (lowestDistanceIndex == 0) {
        combinedPoints.insert(lowestDistanceIndex, wayPoint);

        /// Inserts before the current wayPoint if it's closer to the previous
        /// trackPoint than to the next one.
      } else if (distanceHelper.distanceBetweenWpts(
            wayPoint,
            initialPoints[lowestDistanceIndex - 1],
          ) <
          distanceHelper.distanceBetweenWpts(
            wayPoint,
            initialPoints[lowestDistanceIndex + 1],
          )) {
        combinedPoints.insert(lowestDistanceIndex, wayPoint);

        /// Inserts after the current wayPoint otherwise.
      } else {
        combinedPoints.insert(lowestDistanceIndex + 1, wayPoint);
      }
    }
    return combinedPoints;
  }
}
