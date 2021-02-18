part of 'navigation_bloc.dart';

abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class NavigationLoaded extends NavigationEvent {
  final LatLng userLocation;
  final Tour tour;

  const NavigationLoaded({@required this.userLocation, @required this.tour});

  @override
  List<Object> get props => [userLocation, tour];

  @override
  String toString() =>
      'NavigationLoaded { userLocation: $userLocation, tour: $tour }';
}
