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
  String toString() =>
      'MapboxInitial { controller: $controller, trackingMode: ${controller.myLocationTrackingMode} }';

  @override
  List<Object> get props => [controller];
}

class MapboxLoading extends MapboxState {
  final MapboxController controller;

  const MapboxLoading({@required this.controller});

  @override
  String toString() =>
      'MapboxLoading { controller: $controller, mapboxMapController: ${controller.mapboxMapController}, trackingMode: ${controller.myLocationTrackingMode}, activeStyleString: ${controller.activeStyleString} }';

  @override
  List<Object> get props => [
        controller,
        controller.activeStyleString,
        controller.mapboxMapController,
        controller.myLocationTrackingMode,
        controller.tourLines
      ];
}

class MapboxLoadSuccess extends MapboxState {
  final MapboxController controller;
  final String activeStyleString;
  final MyLocationTrackingMode myLocationTrackingMode;

  const MapboxLoadSuccess(
      {@required this.controller,
      this.activeStyleString,
      this.myLocationTrackingMode});

  @override
  String toString() =>
      'MapboxLoadSuccess { controller: $controller, mapboxMapController: ${controller.mapboxMapController}, trackingMode: ${controller.myLocationTrackingMode}, activeStyleString: ${controller.activeStyleString} }';

  @override
  List<Object> get props => [
        controller,
        controller.activeStyleString,
        controller.mapboxMapController,
        controller.myLocationTrackingMode,
        controller.tourLines,
        activeStyleString,
        myLocationTrackingMode,
      ];
}

class MapboxLoadFailure extends MapboxState {
  final String message;

  const MapboxLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];
}
