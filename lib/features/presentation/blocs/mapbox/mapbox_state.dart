part of 'mapbox_bloc.dart';

abstract class MapboxState extends Equatable {
  const MapboxState();

  @override
  List<Object> get props => [];
}

class MapboxPreInitial extends MapboxState {
  @override
  String toString() => 'MapboxPreInitial { }';

  @override
  List<Object> get props => [];
}

class MapboxInitial extends MapboxState {
  final MapboxController controller;

  const MapboxInitial({@required this.controller});

  @override
  String toString() => 'MapboxInitial { controller: $controller }';

  @override
  List<Object> get props => [controller];
}

class MapboxLoadSuccess extends MapboxState {
  final MapboxController controller;

  const MapboxLoadSuccess({@required this.controller});

  @override
  String toString() =>
      'MapboxLoadSuccess { controller: $controller, mapboxMapController: ${controller.mapboxMapController} }';

  @override
  List<Object> get props => [controller];
}

class MapboxLoadFailure extends MapboxState {
  final String message;

  const MapboxLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
