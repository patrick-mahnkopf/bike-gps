import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:flutter/cupertino.dart';
import 'package:geodesy/geodesy.dart' as gd;
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

/// Helper class that handles the app's distance calculations and conversions.
@injectable
class DistanceHelper {
  static const _distanceNeededToPassTrackPoint = 5;

  /// Convenience method calculating the distance between the [LatLng]s [first]
  /// and [second].
  double distanceBetweenLatLngs(LatLng first, LatLng second) {
    return Geolocator.distanceBetween(
        first.latitude, first.longitude, second.latitude, second.longitude);
  }

  /// Convenience method calculating the distance between the [Wpt]s [first]
  /// and [second].
  double distanceBetweenWpts(Wpt first, Wpt second) {
    final LatLng firstLatLng = LatLng(first.lat, first.lon);
    final LatLng secondLatLng = LatLng(second.lat, second.lon);
    return distanceBetweenLatLngs(firstLatLng, secondLatLng);
  }

  /// Converts the [distance] to a string with the appropriate unit.
  ///
  /// Uses km for distances >= 1 km, otherwise uses m.
  String distanceToString(double distance) {
    if (distance / 1000 >= 1.0) {
      return "${(distance / 1000).toStringAsFixed(1)} km";
    } else {
      return "${distance.toInt()} m";
    }
  }

  /// Calculates the distance from [userLocation] to the closest point on the
  /// [tour].
  Future<double> distanceToTour(
    LatLng userLocation,
    Tour tour,
  ) async {
    /// Finds the index of the closest trackpoint.
    int closestTrackPointIndex = getClosestTrackPointIndex(tour, userLocation);

    /// Uses the next trackpoint if the user already passed the closest one.
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

    /// Determines the tour segment the user is next to.
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

  /// Determines if the user already passed the trackpoint at [trackPointIndex].
  bool userPassedTrackPoint(
      {Tour tour, LatLng userLocation, int trackPointIndex}) {
    final List<TrackPoint> trackPoints = tour.trackPoints;
    final bool currentIsLastPointInTour =
        trackPointIndex == trackPoints.length - 1;
    final LatLng currentPointLatLng = trackPoints[trackPointIndex].latLng;

    /// Handles edge case when the closest trackpoint is the last one of the
    /// track.
    if (currentIsLastPointInTour) {
      final LatLng previousPointLatLng =
          trackPoints[trackPointIndex - 1].latLng;
      return _userBeforeLastPoint(
          previousPointLatLng: previousPointLatLng,
          currentPointLatLng: currentPointLatLng,
          userLocation: userLocation);

      /// Checks if the user passed the current point.
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

  /// Determines if the user is between the last and the previous trackpoint of
  /// the track.
  ///
  /// Returns true if the last point has not been passed yet. Returns false
  /// otherwise.
  bool _userBeforeLastPoint({
    @required LatLng previousPointLatLng,
    @required LatLng currentPointLatLng,
    @required LatLng userLocation,
  }) {
    final double distanceUserPreviousPoint =
        distanceBetweenLatLngs(userLocation, previousPointLatLng);
    final double distanceUserCurrentPoint =
        distanceBetweenLatLngs(userLocation, currentPointLatLng);

    /// Returns true if the user is between the two points and is closer to the
    /// current point than to the previous one.
    if (!_pointIsBetweenLineEnds(
            previousPointLatLng, currentPointLatLng, userLocation) &&
        distanceUserCurrentPoint < distanceUserPreviousPoint) {
      return true;
    } else {
      return false;
    }
  }

  /// Determines if the user passed the [currentPointLatLng].
  ///
  /// Continues with the next check if the [userLocation] is between the
  /// [currentPointLatLng] and the [nextPointLatLng]. Returns false otherwise.
  bool _userPassedCurrentPoint({
    @required List<TrackPoint> trackPoints,
    @required int trackPointIndex,
    @required LatLng currentPointLatLng,
    @required LatLng nextPointLatLng,
    @required LatLng userLocation,
  }) {
    final bool userBetweenCurrentAndNextPoint = _pointIsBetweenLineEnds(
        currentPointLatLng, nextPointLatLng, userLocation);

    /// Continues with the next check if the user is between the current and
    /// next point.
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

  /// Determines if the user is between all three points.
  ///
  /// Checks if [userLocation] is also between the previous point and
  /// [currentPointLatLng].
  bool _userBetweenAllThreePoints({
    @required int trackPointIndex,
    @required List<TrackPoint> trackPoints,
    @required LatLng currentPointLatLng,
    @required LatLng userLocation,
    @required LatLng nextPointLatLng,
  }) {
    /// Continues with the next check if the user is between the previous and
    /// current point.
    if (trackPointIndex > 0) {
      final LatLng previousPointLatLng =
          trackPoints[trackPointIndex - 1].latLng;
      return _userBetweenPreviousAndCurrentPoint(
          previousPointLatLng: previousPointLatLng,
          currentPointLatLng: currentPointLatLng,
          nextPointLatLng: nextPointLatLng,
          userLocation: userLocation);

      /// Uses a different check if there is no previous point.
    } else {
      final double distanceUserCurrentPoint =
          distanceBetweenLatLngs(userLocation, currentPointLatLng);

      /// Returns true if the user's distance to the current point is larger
      /// than the required threshold.
      if (distanceUserCurrentPoint >= _distanceNeededToPassTrackPoint) {
        return true;
      } else {
        return false;
      }
    }
  }

  /// Determines if the user is between the previous and the current point.
  ///
  /// Checks if the [userLocation] is between the [previousPointLatLng] and
  /// the [currentPointLatLng].
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

    /// Continues with the next check if the user is between the previous and
    /// current point.
    if (userBetweenPreviousAndCurrentPoint) {
      return _userCloserToNextTourSegment(
          previousPointLatLng: previousPointLatLng,
          currentPointLatLng: currentPointLatLng,
          nextPointLatLng: nextPointLatLng,
          userLocation: userLocation);

      /// Returns true if the user's distance to the current point is larger
      /// than the required threshold.
    } else if (distanceUserCurrentPoint >= _distanceNeededToPassTrackPoint) {
      return true;
    } else {
      return false;
    }
  }

  /// Determines if the user is closer to the first than to the
  /// second segment.
  ///
  /// Checks if [userLocation] is closer to the segment between
  /// [previousPointLatLng] and [currentPointLatLng] than to the one between
  /// [currentPointLatLng] and [nextPointLatLng].
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

    /// Returns true if the user is closer to the first than to the second tour
    /// segment and that distance is larger than the required threshold.
    if (distanceUserSecondTourSegment <= distanceUserFirstTourSegment &&
        distanceUserCurrentPoint >= _distanceNeededToPassTrackPoint) {
      return true;
    } else {
      return false;
    }
  }

  /// Convenience method calculating the distance between the [tour]'s
  /// trackpoints at index [firstIndex] and [secondIndex].
  double distanceBetweenTourTrackPoints(
      Tour tour, int firstIndex, int secondIndex) {
    final firstTrackPoint = tour.trackPoints[firstIndex];
    final secondTrackPoint = tour.trackPoints[secondIndex];
    return secondTrackPoint.distanceFromStart -
        firstTrackPoint.distanceFromStart;
  }

  /// Gets the trackpoint of the [tour] closest to the [userLocation].
  int getClosestTrackPointIndex(Tour tour, LatLng userLocation) {
    final List<TrackPoint> trackPoints = tour.trackPoints;

    double shortestDistance = double.infinity;
    int index = -1;

    /// Finds the closest trackpoint to the current user location.
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

  /// Calculates the distance from [point] to the tour segment between
  /// [lineStart] and [lineEnd].
  ///
  /// Uses the cross-track distance if [point] is between [lineStart] and
  /// [lineEnd]. Otherwise uses the straight distance to the closer point.
  double _distanceToTourSegment(
      {@required LatLng lineStart,
      @required LatLng lineEnd,
      @required LatLng point}) {
    /// Calculates the cross-track distance if point is next to the segment.
    if (_pointIsBetweenLineEnds(lineStart, lineEnd, point)) {
      return _getCrossTrackDistance(
              lineStart: lineStart, lineEnd: lineEnd, point: point)
          .abs();

      /// Calculates the distance to the closer point.
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

  /// Determines if [point] is between [lineA] and [lineB].
  ///
  /// Compares the bearings from [point] to the other points and those between
  /// each other.
  bool _pointIsBetweenLineEnds(LatLng lineA, LatLng lineB, LatLng point) {
    final double bearingAB = bearingBetweenLatLngs(lineA, lineB);
    final double bearingAP = bearingBetweenLatLngs(lineA, point);
    final double bearingBA = bearingBetweenLatLngs(lineB, lineA);
    final double bearingBP = bearingBetweenLatLngs(lineB, point);

    /// Checks if the point is somewhere below the line perpendicular to AB
    /// that intersects B.
    final bool pointIsBelowB =
        bearingAB - 90 <= bearingAP && bearingAP <= bearingAB + 90;

    /// Checks if the point is somewhere above the line perpendicular to AB
    /// that intersects A.
    final bool pointIsAboveA =
        bearingBA - 90 <= bearingBP && bearingBP <= bearingBA + 90;

    /// Returns true if the point is between both line ends.
    if (pointIsBelowB && pointIsAboveA) {
      return true;
    }
    return false;
  }

  /// Calculates the cross-track distance from [point] to the line between
  /// [lineStart] and [lineEnd].
  ///
  /// See https://www.movable-type.co.uk/scripts/latlong.html#cross-track
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

  /// Calculates the bearing from [first] to [second].
  ///
  /// The result is normalized to a compass bearing of 360°.
  /// See https://www.movable-type.co.uk/scripts/latlong.html#bearing
  double bearingBetweenLatLngs(LatLng first, LatLng second) {
    final double bearing = Geolocator.bearingBetween(
        first.latitude, first.longitude, second.latitude, second.longitude);
    return (bearing + 360) % 360;
  }
}
