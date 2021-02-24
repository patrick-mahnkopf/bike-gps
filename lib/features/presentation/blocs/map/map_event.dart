part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class TourSelectionViewActivated extends MapEvent {
  @override
  List<Object> get props => [];

  @override
  String toString() => 'TourSelectionViewActivated { }';
}

class NavigationViewActivated extends MapEvent {
  @override
  List<Object> get props => [];

  @override
  String toString() => 'NavigationViewActivated { }';
}
