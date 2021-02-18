part of 'mapbox_bloc.dart';

abstract class MapboxState extends Equatable {
  const MapboxState();

  @override
  List<Object> get props => [];
}

class MapboxInitial extends MapboxState {}

class MapboxLoadSuccess extends MapboxState {
  final MapboxController controller;

  const MapboxLoadSuccess({@required this.controller});

  @override
  String toString() => 'MapboxLoadSuccess { controller: $controller }';

  @override
  List<Object> get props => [controller];
}

class MapboxLoadFailure extends MapboxState {
  final String message;

  const MapboxLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
