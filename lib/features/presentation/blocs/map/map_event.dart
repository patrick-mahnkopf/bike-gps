part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class TourSelectionViewActivated extends MapEvent {}

class NavigationViewActivated extends MapEvent {}
