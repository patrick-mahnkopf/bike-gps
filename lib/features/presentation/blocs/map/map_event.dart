part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

/// Event of the MapBloc when the tour selection view was activated.
class TourSelectionViewActivated extends MapEvent {
  @override
  List<Object> get props => [];

  @override
  String toString() => 'TourSelectionViewActivated { }';
}

/// Event of the MapBloc when the navigation view was activated.
class NavigationViewActivated extends MapEvent {
  @override
  List<Object> get props => [];

  @override
  String toString() => 'NavigationViewActivated { }';
}
