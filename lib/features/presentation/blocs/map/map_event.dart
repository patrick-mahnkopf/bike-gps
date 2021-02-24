part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class TourSelectionViewActivated extends MapEvent {
  final BuildContext context;

  const TourSelectionViewActivated({@required this.context});

  @override
  List<Object> get props => [context];

  @override
  String toString() => 'TourSelectionViewActivated { context: $context}';
}

class NavigationViewActivated extends MapEvent {
  final BuildContext context;

  const NavigationViewActivated({@required this.context});

  @override
  List<Object> get props => [context];

  @override
  String toString() => 'NavigationViewActivated { context: $context}';
}
