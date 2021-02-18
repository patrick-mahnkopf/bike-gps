part of 'mapbox_bloc.dart';

abstract class MapboxEvent extends Equatable {
  const MapboxEvent();

  @override
  List<Object> get props => [];
}

class MapboxLoaded extends MapboxEvent {
  final MapboxController mapboxController;

  const MapboxLoaded({@required this.mapboxController});

  @override
  List<Object> get props => [mapboxController];

  @override
  String toString() => 'MapboxLoaded { mapboxController: $mapboxController }';
}
