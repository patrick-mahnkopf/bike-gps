import 'dart:developer' as developer;
import 'dart:math';

import 'package:bike_gps/core/controllers/controllers.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/usecases/navigation/get_navigation_data.dart';
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
    TrackPoint otherTrackPoint;

    if (currentTrackPointIndex == 0) {
      otherTrackPoint = tour.trackPoints[currentTrackPointIndex + 1];
    } else {
      otherTrackPoint = tour.trackPoints[currentTrackPointIndex - 1];
    }
    final double distance = _distanceBetweenPointAndLine(
        currentTrackPoint.latLng, otherTrackPoint.latLng, userLocation);
    if (mapboxController != null && debugMode) {
      final Line tourLine = await mapboxController.mapboxMapController.addLine(
          LineOptions(
              geometry: [currentTrackPoint.latLng, otherTrackPoint.latLng],
              lineColor: '#ff0000',
              lineWidth: 10));
      Future.delayed(const Duration(seconds: 2), () {
        mapboxController.mapboxMapController.removeLine(tourLine);
      });
    }
    final double distanceToClosestTrackPoint =
        distanceBetweenLatLngs(userLocation, currentTrackPoint.latLng);
    if (isPath != null && isPath) {
      developer.log(
          'distance: $distance, distanceToClosestTrackPoint: $distanceToClosestTrackPoint',
          name: 'NavigationBloc distanceToTour pathDistance');
    } else {
      developer.log(
          'distance: $distance, distanceToClosestTrackPoint: $distanceToClosestTrackPoint',
          name: 'NavigationBloc distanceToTour tourDistance');
    }
    return min(distance, distanceToClosestTrackPoint);
  }

  double _distanceBetweenPointAndLine(
      LatLng lineA, LatLng lineB, LatLng point) {
    final double distanceAPoint = distanceBetweenLatLngs(lineA, point);
    final double alpha = ((bearingBetweenLatLngs(lineA, lineB) -
                bearingBetweenLatLngs(lineA, point))
            .abs()) /
        180 *
        pi;
    return sin(alpha) * distanceAPoint;
  }

  double bearingBetweenLatLngs(LatLng first, LatLng second) {
    developer.log(
        'Bearing: ${Geolocator.bearingBetween(first.latitude, first.longitude, second.latitude, second.longitude)}',
        name: 'NavigationBloc distanceToTour');
    return Geolocator.bearingBetween(
            first.latitude, first.longitude, second.latitude, second.longitude)
        .abs();
  }
}
