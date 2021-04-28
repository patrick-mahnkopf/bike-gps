part of 'map_bloc.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object> get props => [];
}

/// State of the MapBloc when the tour selection view is active.
///
/// This is the initial state of the MapBloc.
class TourSelectionViewActive extends MapState {
  final String name = 'TourSelectionViewActive';
  @override
  String toString() => 'TourSelectionViewActive';

  @override
  List<Object> get props => [name];
}

/// State of the MapBloc while the navigation view is active.
class NavigationViewActive extends MapState {
  final String name = 'NavigationViewActive';

  @override
  String toString() => 'NavigationViewActive';

  @override
  List<Object> get props => [name];
}
