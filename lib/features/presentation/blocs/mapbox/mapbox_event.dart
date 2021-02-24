part of 'mapbox_bloc.dart';

abstract class MapboxEvent extends Equatable {
  const MapboxEvent();

  @override
  List<Object> get props => [];
}

class MapboxInitialized extends MapboxEvent {
  final MapboxController mapboxController;

  const MapboxInitialized({@required this.mapboxController});

  @override
  List<Object> get props => [mapboxController];

  @override
  String toString() =>
      'MapboxInitialized { mapboxController: $mapboxController }';
}

class MapboxLoaded extends MapboxEvent {
  final MapboxController mapboxController;

  const MapboxLoaded({@required this.mapboxController});

  @override
  List<Object> get props => [mapboxController];

  @override
  String toString() => 'MapboxLoaded { mapboxController: $mapboxController }';
}
