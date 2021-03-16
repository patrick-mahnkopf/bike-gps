import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:flutter/cupertino.dart';
import 'package:geodesy/geodesy.dart' as gd;
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

@injectable
class DistanceHelper {
  double distanceBetweenLatLngs(LatLng first, LatLng second) {
    return Geolocator.distanceBetween(
        first.latitude, first.longitude, second.latitude, second.longitude);
  }

  double distanceBetweenWpts(Wpt first, Wpt second) {
    final LatLng firstLatLng = LatLng(first.lat, first.lon);
    final LatLng secondLatLng = LatLng(second.lat, second.lon);
    return distanceBetweenLatLngs(firstLatLng, secondLatLng);
  }

  String distanceToString(double distance) {
    if (distance / 1000 >= 1.0) {
      return "${(distance / 1000).toStringAsFixed(1)} km";
    } else {
      return "${distance.toInt()} m";
    }
  }

  Future<double> distanceToTour(LatLng userLocation, Tour tour) async {
    final int closestTrackPointIndex =
        getClosestTrackPointIndex(tour, userLocation);
    final TrackPoint closestTrackPoint =
        tour.trackPoints[closestTrackPointIndex];
    TrackPoint tourSegmentStart;
    TrackPoint tourSegmentEnd;

    if (closestTrackPointIndex == 0) {
      tourSegmentStart = closestTrackPoint;
      tourSegmentEnd = tour.trackPoints[closestTrackPointIndex + 1];
    } else {
      tourSegmentStart = tour.trackPoints[closestTrackPointIndex - 1];
      tourSegmentEnd = closestTrackPoint;
    }
    return _distanceToCurrentTourSegment(
        lineStart: tourSegmentStart.latLng,
        lineEnd: tourSegmentEnd.latLng,
        point: userLocation);
  }

  int getClosestTrackPointIndex(Tour tour, LatLng userLocation) {
    double shortestDistance = double.infinity;
    int index = 0;
    for (int i = 0; i < tour.trackPoints.length; i++) {
      final TrackPoint trackPoint = tour.trackPoints[i];
      final double distance =
          distanceBetweenLatLngs(userLocation, trackPoint.latLng);
      if (distance < shortestDistance) {
        shortestDistance = distance;
        index = i;
      }
    }
    return index;
  }

  double _distanceToCurrentTourSegment(
      {@required LatLng lineStart,
      @required LatLng lineEnd,
      @required LatLng point}) {
    if (_pointIsBetweenLineEnds(lineStart, lineEnd, point)) {
      return _getCrossTrackDistance(
              lineStart: lineStart, lineEnd: lineEnd, point: point)
          .abs();
    } else {
      final double distancePA = distanceBetweenLatLngs(point, lineStart);
      final double distancePB = distanceBetweenLatLngs(point, lineEnd);
      if (distancePA < distancePB) {
        return distancePA;
      } else {
        return distancePB;
      }
    }
  }

  bool _pointIsBetweenLineEnds(LatLng lineA, LatLng lineB, LatLng point) {
    final double bearingAB = bearingBetweenLatLngs(lineA, lineB);
    final double bearingAP = bearingBetweenLatLngs(lineA, point);
    final double bearingBA = bearingBetweenLatLngs(lineB, lineA);
    final double bearingBP = bearingBetweenLatLngs(lineB, point);
    final bool pointIsBelowB =
        bearingAB - 90 <= bearingAP && bearingAP <= bearingAB + 90;
    final bool pointIsAboveA =
        bearingBA - 90 <= bearingBP && bearingBP <= bearingBA + 90;
    if (pointIsBelowB && pointIsAboveA) {
      return true;
    }
    return false;
  }

  double _getCrossTrackDistance(
      {@required LatLng lineStart,
      @required LatLng lineEnd,
      @required LatLng point}) {
    const double earthRadius = 6378137.0;
    final p = gd.LatLng(point.latitude, point.longitude);
    final a = gd.LatLng(lineStart.latitude, lineStart.longitude);
    final b = gd.LatLng(lineEnd.latitude, lineEnd.longitude);
    return gd.Geodesy().crossTrackDistanceTo(p, a, b, earthRadius).toDouble();
  }

  double bearingBetweenLatLngs(LatLng first, LatLng second) {
    final double bearing = Geolocator.bearingBetween(
        first.latitude, first.longitude, second.latitude, second.longitude);
    return (bearing + 360) % 360;
  }
}
