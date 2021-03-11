part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

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

class NavigationStopped extends NavigationEvent {
  final String name = 'NavigationStopped';

  @override
  List<Object> get props => [name];

  @override
  String toString() => 'NavigationStopped';
}
