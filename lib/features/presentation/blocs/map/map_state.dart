part of 'map_bloc.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object> get props => [];
}

class TourSelectionViewActive extends MapState {
  final String name = 'TourSelectionViewActive';
  @override
  String toString() => 'TourSelectionViewActive';

  @override
  List<Object> get props => [name];
}

class NavigationViewActive extends MapState {
  final String name = 'NavigationViewActive';

  @override
  String toString() => 'NavigationViewActive';

  @override
  List<Object> get props => [name];
}
