import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/helpers/distance_helper.dart';
import '../../../../core/usecases/usecase.dart';
import '../../entities/tour/entities.dart';

/// A use case that retrieves the data necessary to navigate for the current
/// tour and user location.
@lazySingleton
class GetNavigationData extends UseCase<NavigationData, NavigationDataParams> {
  final DistanceHelper distanceHelper;

  GetNavigationData({this.distanceHelper});

  /// Returns the current [NavigationData].
  ///
  /// Returns a [NavigationDataFailure] in case of an error.
  @override
  Future<Either<Failure, NavigationData>> call(NavigationDataParams params) {
    try {
      return Future.value(right(_getNavigationData(
          tour: params.tour, userLocation: params.userLocation)));
    } on Exception catch (error) {
      log(error.toString());
      return Future.value(left(NavigationDataFailure()));
    }
  }

  /// Gets the [NavigationData] on the [tour] from the current [userLocation].
  ///
  /// The [NavigationData] contains the [currentWayPoint], [nextWayPoint],
  /// [distanceToCurrentWayPoint], and [distanceToTourEnd].
  NavigationData _getNavigationData(
      {@required Tour tour, @required LatLng userLocation}) {
    final List<TrackPoint> trackPoints = tour.trackPoints;
    final int closestTrackPointIndex =
        distanceHelper.getClosestTrackPointIndex(tour, userLocation);
    final bool userPassedTrackPoint = distanceHelper.userPassedTrackPoint(
        tour: tour,
        userLocation: userLocation,
        trackPointIndex: closestTrackPointIndex);
    int currentTrackPointIndex = closestTrackPointIndex;

    /// Check the following point if it exists and the user already passed the
    /// closest one.
    if (userPassedTrackPoint &&
        currentTrackPointIndex < trackPoints.length - 1) {
      currentTrackPointIndex++;
    }

    WayPoint currentWayPoint;
    double distanceToCurrentWayPoint;
    WayPoint nextWayPoint;
    final double distanceToTourEnd =
        _getDistanceToTourEnd(tour, currentTrackPointIndex, userLocation);

    final int currentWayPointIndex =
        _closestUpcomingWayPointIndex(tour, currentTrackPointIndex);

    /// Return [NavigationData] with null values if there is no more upcoming
    /// waypoint.
    if (currentWayPointIndex == -1) {
      return NavigationData(
          currentWayPoint: null,
          nextWayPoint: null,
          distanceToCurrentWayPoint: null,
          distanceToTourEnd: distanceToTourEnd);
    }
    currentWayPoint = trackPoints[currentWayPointIndex].wayPoint;

    final TrackPoint closestTrackPoint = trackPoints[currentTrackPointIndex];
    final double distanceUserClosestTrackPoint = distanceHelper
        .distanceBetweenLatLngs(userLocation, closestTrackPoint.latLng);
    final double distanceClosestTrackPointCurrentWayPoint =
        distanceHelper.distanceBetweenTourTrackPoints(
            tour, currentTrackPointIndex, currentWayPointIndex);

    /// Calculates the distance from [userLocation] to [currentWayPoint].
    if (userPassedTrackPoint) {
      distanceToCurrentWayPoint = distanceClosestTrackPointCurrentWayPoint +
          distanceUserClosestTrackPoint;
    } else {
      distanceToCurrentWayPoint = (distanceClosestTrackPointCurrentWayPoint -
              distanceUserClosestTrackPoint)
          .abs();
    }

    /// Get the next [WayPoint] after [currentWayPoint] if it exists.
    final int nextWayPointIndex =
        _closestUpcomingWayPointIndex(tour, currentWayPointIndex + 1);
    if (nextWayPointIndex != -1) {
      nextWayPoint = trackPoints[nextWayPointIndex].wayPoint;
    }

    return NavigationData(
        currentWayPoint: currentWayPoint,
        nextWayPoint: nextWayPoint,
        distanceToCurrentWayPoint: distanceToCurrentWayPoint,
        distanceToTourEnd: distanceToTourEnd);
  }

  /// Returns the index of the closest upcoming waypoint to the current user
  /// location.
  int _closestUpcomingWayPointIndex(Tour tour, int currentTrackPointIndex) {
    final List<TrackPoint> trackPoints = tour.trackPoints;
    for (var i = currentTrackPointIndex; i < trackPoints.length; i++) {
      final TrackPoint trackPoint = trackPoints[i];
      if (trackPoint.isWayPoint) {
        return i;
      }
    }
    return -1;
  }

  /// Gets the distance to the tour end from the current [userLocation].
  double _getDistanceToTourEnd(
      Tour tour, int closestTrackPointIndex, LatLng userLocation) {
    final TrackPoint closestTrackPoint =
        tour.trackPoints[closestTrackPointIndex];
    final double distanceClosestTrackPointTourEnd =
        distanceHelper.distanceBetweenTourTrackPoints(
            tour, closestTrackPointIndex, tour.trackPoints.length - 1);
    final double distanceUserClosestTrackPoint = distanceHelper
        .distanceBetweenLatLngs(userLocation, closestTrackPoint.latLng);
    return distanceClosestTrackPointTourEnd + distanceUserClosestTrackPoint;
  }
}

class NavigationDataParams extends Equatable {
  final Tour tour;
  final LatLng userLocation;

  const NavigationDataParams(
      {@required this.tour, @required this.userLocation});

  @override
  List<Object> get props => [tour, userLocation];
}

class NavigationData extends Equatable {
  final WayPoint currentWayPoint;
  final double distanceToCurrentWayPoint;
  final WayPoint nextWayPoint;
  final double distanceToTourEnd;

  const NavigationData(
      {@required this.currentWayPoint,
      @required this.nextWayPoint,
      @required this.distanceToCurrentWayPoint,
      @required this.distanceToTourEnd});

  @override
  List<Object> get props =>
      [currentWayPoint, distanceToCurrentWayPoint, nextWayPoint];
}
