part of 'navigation_bloc.dart';

abstract class NavigationState extends Equatable {
  const NavigationState();

  @override
  List<Object> get props => [];
}

class NavigationInitial extends NavigationState {}

class NavigationLoading extends NavigationState {}

class NavigationLoadSuccess extends NavigationState {
  final WayPoint currentWayPoint;
  final WayPoint nextWayPoint;
  final double currentWayPointDistance;
  final double distanceToTourEnd;
  final LatLng userLocation;

  const NavigationLoadSuccess({
    @required this.currentWayPoint,
    @required this.nextWayPoint,
    @required this.currentWayPointDistance,
    @required this.distanceToTourEnd,
    @required this.userLocation,
  });

  @override
  String toString() {
    if (currentWayPoint != null) {
      return 'NavigationLoadSuccess { currentWayPoint: ${currentWayPoint.latLng},${currentWayPoint.name}, nextWayPoint: ${nextWayPoint.latLng},${nextWayPoint.name}, currentWayPointDistance: $currentWayPointDistance, distanceToTourEnd: $distanceToTourEnd, userLocation: $userLocation }';
    } else {
      return 'NavigationLoadSuccess { currentWayPoint: None, distanceToTourEnd: $distanceToTourEnd, userLocation: $userLocation }';
    }
  }

  @override
  List<Object> get props => [
        currentWayPoint,
        nextWayPoint,
        currentWayPointDistance,
        distanceToTourEnd,
        userLocation
      ];
}

class NavigationToTourLoadSuccess extends NavigationState {
  final WayPoint currentWayPoint;
  final WayPoint nextWayPoint;
  final double currentWayPointDistance;
  final double distanceToTourEnd;
  final LatLng userLocation;
  final Tour pathToTour;

  const NavigationToTourLoadSuccess({
    @required this.currentWayPoint,
    @required this.nextWayPoint,
    @required this.currentWayPointDistance,
    @required this.distanceToTourEnd,
    @required this.userLocation,
    @required this.pathToTour,
  });

  @override
  String toString() =>
      'NavigationToTourLoadSuccess { currentWayPoint: ${currentWayPoint.latLng},${currentWayPoint.name}, nextWayPoint: ${nextWayPoint?.latLng},${nextWayPoint?.name}, currentWayPointDistance: $currentWayPointDistance, distanceToTourEnd: $distanceToTourEnd, userLocation: $userLocation, pathToTour: $pathToTour }';

  @override
  List<Object> get props => [
        currentWayPoint,
        nextWayPoint,
        currentWayPointDistance,
        distanceToTourEnd,
        pathToTour,
        userLocation
      ];
}

class NavigationLoadFailure extends NavigationState {
  final String message;

  const NavigationLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
