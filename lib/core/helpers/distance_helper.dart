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
      {MapboxController mapboxController}) async {
    // TODO remove debugMode, mapboxController and logs
    const bool debugMode = true;
    // TODO handle distance to path correctly
    final TrackPoint currentTrackPoint =
        tour.trackPointForWayPoint(navigationData.currentWayPoint);
    final int currentTrackPointIndex =
        tour.trackPoints.indexOf(currentTrackPoint);
    double au;
    double alpha;

    if (navigationData.currentWayPoint == tour.wayPoints.first) {
      final TrackPoint nextTrackPoint =
          tour.trackPoints.elementAt(currentTrackPointIndex + 1);
      au = distanceBetweenLatLngs(currentTrackPoint.latLng, userLocation);
      alpha = ((bearingBetweenLatLngs(
                      currentTrackPoint.latLng, nextTrackPoint.latLng) -
                  bearingBetweenLatLngs(currentTrackPoint.latLng, userLocation))
              .abs()) /
          180 *
          pi;
      if (mapboxController != null && debugMode) {
        final Line tourLine = await mapboxController.mapboxMapController
            .addLine(LineOptions(
                geometry: [currentTrackPoint.latLng, nextTrackPoint.latLng],
                lineColor: '#ff0000',
                lineWidth: 10));
        final Line distanceLine = await mapboxController.mapboxMapController
            .addLine(LineOptions(
                geometry: [userLocation, currentTrackPoint.latLng],
                lineColor: '#ff0000',
                lineWidth: 10));
        Future.delayed(const Duration(seconds: 5), () {
          mapboxController.mapboxMapController.removeLine(tourLine);
          mapboxController.mapboxMapController.removeLine(distanceLine);
        });
      }
    } else {
      final TrackPoint previousTrackPoint =
          tour.trackPoints.elementAt(currentTrackPointIndex - 1);
      au = distanceBetweenLatLngs(previousTrackPoint.latLng, userLocation);
      alpha = ((bearingBetweenLatLngs(
                      previousTrackPoint.latLng, currentTrackPoint.latLng) -
                  bearingBetweenLatLngs(
                      previousTrackPoint.latLng, userLocation))
              .abs()) /
          180 *
          pi;
      if (mapboxController != null && debugMode) {
        final Line tourLine = await mapboxController.mapboxMapController
            .addLine(LineOptions(
                geometry: [previousTrackPoint.latLng, currentTrackPoint.latLng],
                lineColor: '#ff0000',
                lineWidth: 10));
        final Line distanceLine = await mapboxController.mapboxMapController
            .addLine(LineOptions(
                geometry: [userLocation, previousTrackPoint.latLng],
                lineColor: '#ff0000',
                lineWidth: 10));
        Future.delayed(const Duration(seconds: 5), () {
          mapboxController.mapboxMapController.removeLine(tourLine);
          mapboxController.mapboxMapController.removeLine(distanceLine);
        });
      }
    }
    if (mapboxController != null && debugMode) {
      developer.log(
          'WayPoint $currentTrackPointIndex: au: $au, alpha: $alpha, sin(alpha): ${sin(alpha)}, distance: ${sin(alpha) * au}',
          name: 'NavigationBloc distanceToTour');
    }
    return sin(alpha) * au;
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
