part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

/// Event of the NavigationBloc when loading was initiated.
class NavigationLoaded extends NavigationEvent {
  final Tour tour;
  final LatLng userLocation;
  final MapboxController mapboxController;

  const NavigationLoaded({
    @required this.tour,
    @required this.mapboxController,
    this.userLocation,
  });

  @override
  List<Object> get props => [userLocation, mapboxController, tour];

  @override
  String toString() =>
      'NavigationLoaded { userLocation: $userLocation, mapboxController: $mapboxController, tour: ${tour.name} }';
}

/// Event of the NavigationBloc when the navigation was stopped.
class NavigationStopped extends NavigationEvent {
  final String name = 'NavigationStopped';

  @override
  List<Object> get props => [name];

  @override
  String toString() => 'NavigationStopped';
}
