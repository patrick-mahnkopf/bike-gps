part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigationLoaded extends NavigationEvent {
  final LocationData userLocation;
  final Tour tour;
  final LatLng previousLocation;
  final NavigationData navigationData;

  const NavigationLoaded(
      {@required this.tour,
      this.userLocation,
      this.previousLocation,
      this.navigationData});

  @override
  List<Object> get props =>
      [userLocation, tour, previousLocation, navigationData];

  @override
  String toString() =>
      'NavigationLoaded { userLocation: $userLocation, tour: $tour, previousLocation: $previousLocation, navigationData: $navigationData }';
}

class NavigationStopped extends NavigationEvent {
  final String name = 'NavigationStopped';

  @override
  List<Object> get props => [name];

  @override
  String toString() => 'NavigationStopped';
}
