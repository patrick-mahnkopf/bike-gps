import 'dart:io';

import 'package:bike_gps/features/data/models/tour/tour_info_model.dart';
import 'package:flutter/widgets.dart';
import 'package:gpx/gpx.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;

import '../../../../core/helpers/helpers.dart';
import '../../models/tour/models.dart';

abstract class TourParser {
  final ConstantsHelper constants;
  final DistanceHelper distanceHelper;

  TourParser({@required this.constants, @required this.distanceHelper});

  Future<TourModel> getTour({@required File file});

  Future<TourModel> getTourFromFileContent(
      {@required String tourFileContent, String tourName});

  Future<TourInfoModel> getTourInfo({@required File file});

  List<String> get fileExtensionPriority;
}

class GpxParser extends TourParser {
  GpxParser(
      {@required ConstantsHelper constants,
      @required DistanceHelper distanceHelper})
      : super(constants: constants, distanceHelper: distanceHelper);

  @override
  List<String> get fileExtensionPriority => ['.gpx', '.xml'];

  @override
  Future<TourModel> getTour({File file}) async {
    final String tourFileContent = await file.readAsString();
    final String tourName = p.basenameWithoutExtension(file.path);
    return getTourFromFileContent(
        tourFileContent: tourFileContent, tourName: tourName);
  }

  @override
  Future<TourModel> getTourFromFileContent(
      {@required String tourFileContent, @required String tourName}) async {
    final Gpx tourGpx = GpxReader().fromString(tourFileContent);
    double ascent = 0;
    double descent = 0;
    double tourLength = 0;
    final List<TrackPointModel> trackPoints = [];
    final List<WayPointModel> wayPoints = [];
    // TODO enrich with RouteService data when online, especially surface and wayPoint turn info
    double previousDistanceFromStart = 0;
    final List<Wpt> combinedTourPoints = _getCombinedPoints(tourGpx);
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

        if (currentPoint.ele > previousPoint.ele) {
          ascent += currentPoint.ele - previousPoint.ele;
        } else {
          descent += previousPoint.ele - currentPoint.ele;
        }
      }

      if (_isWaypoint(currentPoint)) {
        final WayPointModel wayPoint = WayPointModel(
          latLng: LatLng(currentPoint.lat, currentPoint.lon),
          elevation: currentPoint.ele,
          distanceFromStart: distanceFromStart,
          surface: 'A',
          name: currentPoint.name,
          direction: '',
          location: '',
          turnSymboldId: '',
        );
        wayPoints.add(wayPoint);

        trackPoints.add(TrackPointModel(
          latLng: LatLng(currentPoint.lat, currentPoint.lon),
          elevation: currentPoint.ele,
          isWayPoint: true,
          wayPoint: wayPoint,
          distanceFromStart: distanceFromStart,
          surface: 'A',
        ));
      } else {
        trackPoints.add(TrackPointModel(
          latLng: LatLng(currentPoint.lat, currentPoint.lon),
          elevation: currentPoint.ele,
          isWayPoint: _isWaypoint(currentPoint),
          distanceFromStart: distanceFromStart,
          surface: 'A',
        ));
      }
    }
    return TourModel(
      name: tourName,
      trackPoints: trackPoints,
      wayPoints: wayPoints,
      bounds: _getBounds(tourGpx, trackPoints),
      ascent: ascent,
      descent: descent,
      tourLength: tourLength,
    );
  }

  @override
  Future<TourInfoModel> getTourInfo({File file}) async {
    // TODO make more efficient by not parsing entire file
    final TourModel tourModel = await getTour(file: file);
    final String fileHash = await constants.getFileHash(file.path);

    return TourInfoModel(
        name: tourModel.name,
        filePath: file.path,
        bounds: tourModel.bounds,
        fileHash: fileHash);
  }

  bool _isWaypoint(Wpt point) {
    return point.name != null;
  }

  LatLngBounds _getBounds(Gpx tourGpx, List<TrackPointModel> trackPoints) {
    if (tourGpx?.metadata?.bounds != null) {
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

  List<Wpt> _getCombinedPoints(Gpx tourGpx) {
    List<Wpt> initialPoints = tourGpx.trks.first.trksegs.first.trkpts;
    if (tourGpx.trks.first.trksegs.first.trkpts.isEmpty) {
      initialPoints = tourGpx.rtes.first.rtepts;
    }
    final List<Wpt> combinedPoints = initialPoints;
    final List<Wpt> wayPoints = tourGpx.wpts;

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
