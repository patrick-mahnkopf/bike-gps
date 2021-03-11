import 'dart:math';

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

  double distanceToTour(
      LatLng userLocation, Tour tour, NavigationData navigationData) {
    // TODO handle distance to path correctly
    final TrackPoint currentTrackPoint =
        tour.trackPointForWayPoint(navigationData.currentWayPoint);
    final int currentTrackPointIndex =
        tour.trackPoints.indexOf(currentTrackPoint);
    double au;
    double alpha;

    if (navigationData.currentWayPoint != tour.wayPoints.first) {
      final TrackPoint previousTrackPoint =
          tour.trackPoints.elementAt(currentTrackPointIndex - 1);
      au = distanceBetweenLatLngs(previousTrackPoint.latLng, userLocation);
      alpha =
          (bearingBetween(previousTrackPoint.latLng, currentTrackPoint.latLng) -
                      bearingBetween(previousTrackPoint.latLng, userLocation))
                  .abs() /
              180 *
              pi;
    } else {
      final TrackPoint nextTrackPoint =
          tour.trackPoints.elementAt(currentTrackPointIndex + 1);
      au = distanceBetweenLatLngs(currentTrackPoint.latLng, userLocation);
      alpha = (bearingBetween(currentTrackPoint.latLng, nextTrackPoint.latLng) -
                  bearingBetween(currentTrackPoint.latLng, userLocation))
              .abs() /
          180 *
          pi;
    }
    return (sin(alpha) * au).abs();
  }

  double bearingBetween(LatLng first, LatLng second) {
    return Geolocator.bearingBetween(
        first.latitude, first.longitude, second.latitude, second.longitude);
  }
}
