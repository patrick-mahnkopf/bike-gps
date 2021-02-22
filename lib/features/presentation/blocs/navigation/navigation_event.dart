part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigationLoaded extends NavigationEvent {
  final LocationData userLocation;
  final Tour tour;
  final BuildContext context;

  const NavigationLoaded({
    @required this.tour,
    @required this.context,
    this.userLocation,
  });

  @override
  List<Object> get props => [userLocation, tour];

  @override
  String toString() =>
      'NavigationLoaded { userLocation: $userLocation, tour: $tour }';
}

class NavigationStopped extends NavigationEvent {
  final String name = 'NavigationStopped';

  @override
  List<Object> get props => [name];

  @override
  String toString() => 'NavigationStopped';
}
