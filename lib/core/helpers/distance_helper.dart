import 'dart:developer' as developer;
import 'dart:math';

import 'package:bike_gps/core/controllers/controllers.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/usecases/navigation/get_navigation_data.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gpx/gpx.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:vector_math/vector_math.dart';

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
    if (distance / 1000 >= 1) {
      return "${(distance / 1000).toStringAsFixed(1)} km";
    } else {
      return "${distance.toInt()} m";
    }
  }

  Future<double> distanceToTour(
      LatLng userLocation, Tour tour, NavigationData navigationData,
      {MapboxController mapboxController, bool isPath}) async {
    // TODO remove debugMode, mapboxController and logs
    const bool debugMode = false;
    // TODO handle distance to path correctly
    final TrackPoint currentTrackPoint =
        tour.trackPointForWayPoint(navigationData.currentWayPoint);
    final int currentTrackPointIndex =
        tour.trackPoints.indexOf(currentTrackPoint);
    TrackPoint firstTrackPoint;
    TrackPoint secondTrackPoint;

    if (currentTrackPointIndex == 0) {
      firstTrackPoint = currentTrackPoint;
      secondTrackPoint = tour.trackPoints[currentTrackPointIndex + 1];
    } else {
      firstTrackPoint = tour.trackPoints[currentTrackPointIndex - 1];
      secondTrackPoint = currentTrackPoint;
    }
    final double distance = _distanceBetweenPointAndLine(
        firstTrackPoint.latLng, secondTrackPoint.latLng, userLocation);
    if (mapboxController != null && debugMode) {
      final Line tourLine = await mapboxController.mapboxMapController.addLine(
          LineOptions(
              geometry: [firstTrackPoint.latLng, secondTrackPoint.latLng],
              lineColor: '#ff0000',
              lineWidth: 10));
      Future.delayed(const Duration(seconds: 2), () {
        mapboxController.mapboxMapController.removeLine(tourLine);
      });
    }
    return distance.abs();
  }

  /// Calculates the cross-track distance between a great-circle path and a point
  ///
  /// This can be used to calculate the distance between a line on the earth's surface
  /// and a third point made up of GPS coordinates,
  /// see https://www.movable-type.co.uk/scripts/latlong.html#cross-track.
  double _distanceBetweenPointAndLine(
      LatLng lineA, LatLng lineB, LatLng point) {
    final double distanceAPoint = distanceBetweenLatLngs(lineA, point);
    final double angularBearingAB =
        radians(bearingBetweenLatLngs(lineA, lineB));
    final double angularBearingAPoint =
        radians(bearingBetweenLatLngs(lineA, point));
    final double angle = sin(angularBearingAB - angularBearingAPoint);
    final double crossTrackDistance = angle * distanceAPoint;
    final double distanceBPoint = distanceBetweenLatLngs(lineB, point);
    double distance = crossTrackDistance;
    if (angle.abs() <= 0.1) {
      if (distanceAPoint < distanceBPoint) {
        distance = distanceAPoint;
      } else {
        distance = distanceBPoint;
      }
    }
    developer.log(
        'distance: $distance, angle: $angle, crossTrackDistance: $crossTrackDistance, distanceAPoint: $distanceAPoint, distanceBPoint: $distanceBPoint',
        name: 'NavigationBloc distanceToTour _distanceBetweenPointAndLine');
    return distance;
  }

  double bearingBetweenLatLngs(LatLng first, LatLng second) {
    developer.log(
        'Bearing: ${Geolocator.bearingBetween(first.latitude, first.longitude, second.latitude, second.longitude)}',
        name: 'NavigationBloc distanceToTour');
    final double bearing = Geolocator.bearingBetween(
        first.latitude, first.longitude, second.latitude, second.longitude);
    return 360 - ((bearing + 360) % 360);
  }
}
