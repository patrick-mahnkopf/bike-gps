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

@Injectable(as: TourParser, env: ["public"])
class GpxParser extends TourParser {
  GpxParser(
      {@required ConstantsHelper constantsHelper,
      @required DistanceHelper distanceHelper})
      : super(constantsHelper: constantsHelper, distanceHelper: distanceHelper);

  @override
  List<String> get fileExtensionPriority => ['.gpx', '.xml'];

  @override
  Future<TourModel> getTour({@required File file}) async {
    final String tourFileContent = await file.readAsString();
    final String tourName = p.basenameWithoutExtension(file.path);
    return getTourFromFileContent(
        tourFileContent: tourFileContent,
        tourName: tourName,
        tourType: TourType.tour);
  }

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
      double distanceFromStart;

      if (i == 0) {
        distanceFromStart = 0;
      } else {
        final Wpt previousPoint = combinedTourPoints[i - 1];
        final double distanceToPrevious =
            distanceHelper.distanceBetweenWpts(previousPoint, currentPoint);
        tourLength += distanceToPrevious;
        distanceFromStart = distanceToPrevious + previousDistanceFromStart;
        previousDistanceFromStart = distanceFromStart;

        if (currentPoint.ele != null) {
          if (currentPoint.ele > previousPoint.ele) {
            ascent += currentPoint.ele - previousPoint.ele;
          } else {
            descent += previousPoint.ele - currentPoint.ele;
          }
        }
      }

      if (_isWaypoint(currentPoint)) {
        String direction = '';
        String location = '';
        String surface = 'A';
        String turnSymbolId = '';

        if (currentPoint.extensions.containsKey('direction') &&
            currentPoint.extensions['direction'] != '') {
          direction = currentPoint.extensions['direction'];
        } else if (currentPoint.desc != null) {
          direction = currentPoint.desc;
        }
        if (currentPoint.extensions.containsKey('location') &&
            currentPoint.extensions['location'] != '') {
          location = currentPoint.extensions['location'];
        }
        if (currentPoint.extensions.containsKey('surface') &&
            currentPoint.extensions['surface'] != '') {
          surface = currentPoint.extensions['surface'];
        }
        if (currentPoint.extensions.containsKey('turnsymbolid') &&
            currentPoint.extensions['turnsymbolid'] != '') {
          turnSymbolId = currentPoint.extensions['turnsymbolid'];
        } else if (currentPoint.extensions.containsKey('type') &&
            currentPoint.extensions['type'] != '') {
          turnSymbolId = currentPoint.extensions['type'];
        }

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
        if (tourType == TourType.route && i > 0) {
          final Wpt previousPoint = combinedTourPoints[i - 1];
          const orsArrivalType = '10';
          final bool isPrematureArrival =
              currentPoint.extensions['type'] == orsArrivalType &&
                  i != combinedTourPoints.length;
          if (currentPoint.extensions['step'] !=
                  previousPoint.extensions['step'] &&
              !isPrematureArrival) {
            wayPoints.add(wayPoint);

            trackPoints.add(TrackPointModel(
              latLng: LatLng(currentPoint.lat, currentPoint.lon),
              elevation: currentPoint.ele,
              isWayPoint: true,
              wayPoint: wayPoint,
              distanceFromStart: distanceFromStart,
              surface: wayPoint.surface,
            ));
          } else {
            trackPoints.add(TrackPointModel(
              latLng: LatLng(currentPoint.lat, currentPoint.lon),
              elevation: currentPoint.ele,
              isWayPoint: false,
              distanceFromStart: distanceFromStart,
              surface: 'A',
            ));
          }
        } else if (tourType == TourType.route && i == 0) {
          trackPoints.add(TrackPointModel(
            latLng: LatLng(currentPoint.lat, currentPoint.lon),
            elevation: currentPoint.ele,
            isWayPoint: false,
            distanceFromStart: distanceFromStart,
            surface: 'A',
          ));
        } else {
          wayPoints.add(wayPoint);

          trackPoints.add(TrackPointModel(
            latLng: LatLng(currentPoint.lat, currentPoint.lon),
            elevation: currentPoint.ele,
            isWayPoint: true,
            wayPoint: wayPoint,
            distanceFromStart: distanceFromStart,
            surface: wayPoint.surface,
          ));
        }
      } else {
        trackPoints.add(TrackPointModel(
          latLng: LatLng(currentPoint.lat, currentPoint.lon),
          elevation: currentPoint.ele,
          isWayPoint: false,
          distanceFromStart: distanceFromStart,
          surface: 'A',
        ));
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

  bool _isWaypoint(Wpt point) {
    return point.name != null && point.name != '' ||
        (point.extensions != null &&
            point.extensions['direction'] != null &&
            point.extensions['direction'] != '');
  }

  LatLngBounds getBounds(Gpx tourGpx, List<TrackPointModel> trackPoints) {
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

  List<Wpt> getCombinedPoints(Gpx tourGpx) {
    List<Wpt> initialPoints;
    List<Wpt> wayPoints;
    if (tourGpx.rtes.isNotEmpty) {
      return tourGpx.rtes.first.rtepts;
    } else if (tourGpx.rtes.isEmpty && tourGpx.trks.isEmpty) {
      return [];
    } else {
      initialPoints = tourGpx.trks.first.trksegs.first.trkpts;
      wayPoints = tourGpx.wpts;
    }
    final List<Wpt> combinedPoints = initialPoints;

    for (int i = 0; i < wayPoints.length; i++) {
      // Find index of trackPoint with lowest distance to current wayPoint
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

      // Insert wayPoint at the correct position
      // Insert in first position if it's closest to the first trackPoint
      if (lowestDistanceIndex == 0) {
        combinedPoints.insert(lowestDistanceIndex, wayPoint);
        // Insert before the current wayPoint if it's closer to the previous trackPoint than to the next one
      } else if (distanceHelper.distanceBetweenWpts(
            wayPoint,
            initialPoints[lowestDistanceIndex - 1],
          ) <
          distanceHelper.distanceBetweenWpts(
            wayPoint,
            initialPoints[lowestDistanceIndex + 1],
          )) {
        combinedPoints.insert(lowestDistanceIndex, wayPoint);
        // Insert after the current wayPoint otherwise
      } else {
        combinedPoints.insert(lowestDistanceIndex + 1, wayPoint);
      }
    }
    return combinedPoints;
  }
}
