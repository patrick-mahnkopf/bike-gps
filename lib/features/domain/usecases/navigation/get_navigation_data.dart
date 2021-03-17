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

@lazySingleton
class GetNavigationData extends UseCase<NavigationData, NavigationDataParams> {
  final DistanceHelper distanceHelper;

  GetNavigationData({this.distanceHelper});

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

  NavigationData _getNavigationData(
      {@required Tour tour, @required LatLng userLocation}) {
    final int closestTrackPointIndex =
        distanceHelper.getClosestTrackPointIndex(tour, userLocation);
    final double distanceToTourEnd =
        _getDistanceToTourEnd(tour, closestTrackPointIndex, userLocation);
    final List<TrackPoint> trackPoints = tour.trackPoints;

    WayPoint currentWayPoint;
    WayPoint nextWayPoint;
    double currentWayPointDistance = 0;
    int currentWayPointIndex;
    for (int i = closestTrackPointIndex; i < trackPoints.length; i++) {
      if (i == closestTrackPointIndex) {
        currentWayPointDistance += distanceHelper.distanceBetweenLatLngs(
            userLocation, trackPoints[i].latLng);
      } else {
        currentWayPointDistance += distanceHelper.distanceBetweenLatLngs(
            trackPoints[i - 1].latLng, trackPoints[i].latLng);
      }
      if (trackPoints[i].isWayPoint) {
        currentWayPoint = trackPoints[i].wayPoint;
        currentWayPointIndex = i;
        break;
      }
    }

    if (currentWayPointIndex != null &&
        currentWayPointIndex + 1 <= trackPoints.length) {
      final int nextWayPointIndex = trackPoints.indexWhere(
          (trackPoint) => trackPoint.isWayPoint, currentWayPointIndex + 1);
      if (nextWayPointIndex != -1) {
        nextWayPoint = trackPoints[nextWayPointIndex].wayPoint;
      } else {
        nextWayPoint = null;
      }
    }
    log('tour: ${tour.name}, currentWayPointIndex: $currentWayPointIndex, currentWayPoint: ${currentWayPoint.direction ?? currentWayPoint.name}, nextWayPoint: ${nextWayPoint?.direction ?? nextWayPoint?.name}',
        name: 'GetNavigationData navigation _getNavigationData');
    log('tour: ${tour.name}, turnSymbol: ${currentWayPoint?.turnSymboldId}',
        name: 'GetNavigationData navigation turnSymbol _getNavigationData');
    return NavigationData(
        currentWayPoint: currentWayPoint,
        nextWayPoint: nextWayPoint,
        currentWayPointDistance: currentWayPointDistance,
        distanceToTourEnd: distanceToTourEnd);
  }

  // TODO remove
  int _getClosestTrackPointIndex(Tour tour, LatLng userLocation) {
    final List<TrackPoint> trackPoints = tour.trackPoints;

    double shortestDistance = double.infinity;
    int index = -1;
    for (int i = 0; i < trackPoints.length; i++) {
      final TrackPoint currentTrackPoint = trackPoints[i];
      final double currentDistance = distanceHelper.distanceBetweenLatLngs(
          currentTrackPoint.latLng, userLocation);

      if (currentDistance < shortestDistance) {
        shortestDistance = currentDistance;
        index = i;
      }
    }

    final bool currentIsLastPointInTour = index == trackPoints.length;
    if (!currentIsLastPointInTour) {
      final TrackPoint currentTrackPoint = trackPoints[index];
      final TrackPoint nextTrackPoint = trackPoints[index + 1];

      final double userDistanceToNextTrackPoint = distanceHelper
          .distanceBetweenLatLngs(userLocation, nextTrackPoint.latLng);
      final double distanceBetweenCurrentAndNextTrackPoint =
          distanceHelper.distanceBetweenLatLngs(
              currentTrackPoint.latLng, nextTrackPoint.latLng);

      // User passed closest track point, should thus return the next one
      if (userDistanceToNextTrackPoint <
          distanceBetweenCurrentAndNextTrackPoint) {
        index++;
      }
    }
    return index;
  }

  double _getDistanceToTourEnd(
      Tour tour, int closestTrackPointIndex, LatLng userLocation) {
    final TrackPoint closestTrackPoint =
        tour.trackPoints[closestTrackPointIndex];
    return (tour.tourLength - closestTrackPoint.distanceFromStart) +
        distanceHelper.distanceBetweenLatLngs(
            userLocation, closestTrackPoint.latLng);
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
  final double currentWayPointDistance;
  final WayPoint nextWayPoint;
  final double distanceToTourEnd;

  const NavigationData(
      {@required this.currentWayPoint,
      @required this.nextWayPoint,
      @required this.currentWayPointDistance,
      @required this.distanceToTourEnd});

  @override
  List<Object> get props =>
      [currentWayPoint, currentWayPointDistance, nextWayPoint];
}
