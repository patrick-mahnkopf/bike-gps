import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:flutter/cupertino.dart';
import 'package:geodesy/geodesy.dart' as gd;
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

@injectable
class DistanceHelper {
  static const _distanceNeededToPassTrackPoint = 5;

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

  Future<double> distanceToTour(
    LatLng userLocation,
    Tour tour,
  ) async {
    int closestTrackPointIndex = getClosestTrackPointIndex(tour, userLocation);
    if (userPassedTrackPoint(
            tour: tour,
            userLocation: userLocation,
            trackPointIndex: closestTrackPointIndex) &&
        closestTrackPointIndex < tour.trackPoints.length - 1) {
      closestTrackPointIndex++;
    }
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
    return _distanceToTourSegment(
        lineStart: tourSegmentStart.latLng,
        lineEnd: tourSegmentEnd.latLng,
        point: userLocation);
  }

  bool userPassedTrackPoint(
      {Tour tour, LatLng userLocation, int trackPointIndex}) {
    final List<TrackPoint> trackPoints = tour.trackPoints;
    final bool currentIsLastPointInTour =
        trackPointIndex == trackPoints.length - 1;
    final LatLng currentPointLatLng = trackPoints[trackPointIndex].latLng;

    if (currentIsLastPointInTour) {
      final LatLng previousPointLatLng =
          trackPoints[trackPointIndex - 1].latLng;
      return _userPassedLastPoint(
          previousPointLatLng: previousPointLatLng,
          currentPointLatLng: currentPointLatLng,
          userLocation: userLocation);
    } else {
      final LatLng nextPointLatLng = trackPoints[trackPointIndex + 1].latLng;
      return _userPassedCurrentPoint(
          trackPoints: trackPoints,
          trackPointIndex: trackPointIndex,
          currentPointLatLng: currentPointLatLng,
          nextPointLatLng: nextPointLatLng,
          userLocation: userLocation);
    }
  }

  bool _userPassedLastPoint({
    @required LatLng previousPointLatLng,
    @required LatLng currentPointLatLng,
    @required LatLng userLocation,
  }) {
    final double distanceUserPreviousPoint =
        distanceBetweenLatLngs(userLocation, previousPointLatLng);
    final double distanceUserCurrentPoint =
        distanceBetweenLatLngs(userLocation, currentPointLatLng);
    if (!_pointIsBetweenLineEnds(
            previousPointLatLng, currentPointLatLng, userLocation) &&
        distanceUserCurrentPoint < distanceUserPreviousPoint) {
      return true;
    } else {
      return false;
    }
  }

  bool _userPassedCurrentPoint({
    @required List<TrackPoint> trackPoints,
    @required int trackPointIndex,
    @required LatLng currentPointLatLng,
    @required LatLng nextPointLatLng,
    @required LatLng userLocation,
  }) {
    final bool userBetweenCurrentAndNextPoint = _pointIsBetweenLineEnds(
        currentPointLatLng, nextPointLatLng, userLocation);
    if (userBetweenCurrentAndNextPoint) {
      return _userBetweenAllThreePoints(
          trackPoints: trackPoints,
          trackPointIndex: trackPointIndex,
          currentPointLatLng: currentPointLatLng,
          nextPointLatLng: nextPointLatLng,
          userLocation: userLocation);
    } else {
      return false;
    }
  }

  bool _userBetweenAllThreePoints({
    @required int trackPointIndex,
    @required List<TrackPoint> trackPoints,
    @required LatLng currentPointLatLng,
    @required LatLng userLocation,
    @required LatLng nextPointLatLng,
  }) {
    if (trackPointIndex > 0) {
      final LatLng previousPointLatLng =
          trackPoints[trackPointIndex - 1].latLng;
      return _userBetweenPreviousAndCurrentPoint(
          previousPointLatLng: previousPointLatLng,
          currentPointLatLng: currentPointLatLng,
          nextPointLatLng: nextPointLatLng,
          userLocation: userLocation);
    } else {
      final double distanceUserCurrentPoint =
          distanceBetweenLatLngs(userLocation, currentPointLatLng);
      if (distanceUserCurrentPoint >= _distanceNeededToPassTrackPoint) {
        return true;
      } else {
        return false;
      }
    }
  }

  bool _userBetweenPreviousAndCurrentPoint({
    @required LatLng previousPointLatLng,
    @required LatLng currentPointLatLng,
    @required LatLng userLocation,
    @required LatLng nextPointLatLng,
  }) {
    final bool userBetweenPreviousAndCurrentPoint = _pointIsBetweenLineEnds(
        previousPointLatLng, currentPointLatLng, userLocation);
    final double distanceUserCurrentPoint =
        distanceBetweenLatLngs(userLocation, currentPointLatLng);
    if (userBetweenPreviousAndCurrentPoint) {
      return _userCloserToNextTourSegment(
          previousPointLatLng: previousPointLatLng,
          currentPointLatLng: currentPointLatLng,
          nextPointLatLng: nextPointLatLng,
          userLocation: userLocation);
    } else if (distanceUserCurrentPoint >= _distanceNeededToPassTrackPoint) {
      return true;
    } else {
      return false;
    }
  }

  bool _userCloserToNextTourSegment({
    @required LatLng previousPointLatLng,
    @required LatLng currentPointLatLng,
    @required LatLng userLocation,
    @required LatLng nextPointLatLng,
  }) {
    final double distanceUserFirstTourSegment = _distanceToTourSegment(
        lineStart: previousPointLatLng,
        lineEnd: currentPointLatLng,
        point: userLocation);
    final double distanceUserSecondTourSegment = _distanceToTourSegment(
        lineStart: currentPointLatLng,
        lineEnd: nextPointLatLng,
        point: userLocation);
    final double distanceUserCurrentPoint =
        distanceBetweenLatLngs(userLocation, currentPointLatLng);
    if (distanceUserSecondTourSegment <= distanceUserFirstTourSegment &&
        distanceUserCurrentPoint >= _distanceNeededToPassTrackPoint) {
      return true;
    } else {
      return false;
    }
  }

  double distanceBetweenTourTrackPoints(
      Tour tour, int firstIndex, int secondIndex) {
    final firstTrackPoint = tour.trackPoints[firstIndex];
    final secondTrackPoint = tour.trackPoints[secondIndex];
    return secondTrackPoint.distanceFromStart -
        firstTrackPoint.distanceFromStart;
  }

  int getClosestTrackPointIndex(Tour tour, LatLng userLocation) {
    final List<TrackPoint> trackPoints = tour.trackPoints;

    double shortestDistance = double.infinity;
    int index = -1;
    for (int i = 0; i < trackPoints.length; i++) {
      final TrackPoint currentTrackPoint = trackPoints[i];
      final double currentDistance =
          distanceBetweenLatLngs(currentTrackPoint.latLng, userLocation);

      if (currentDistance < shortestDistance) {
        shortestDistance = currentDistance;
        index = i;
      }
    }

    return index;
  }

  double _distanceToTourSegment(
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
