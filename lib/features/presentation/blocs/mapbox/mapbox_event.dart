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
  final CameraUpdate cameraUpdate;

  const MapboxLoaded({@required this.mapboxController, this.cameraUpdate});

  @override
  List<Object> get props => [
        mapboxController,
        mapboxController.myLocationTrackingMode,
        mapboxController.activeStyleString,
      ];

  @override
  String toString() =>
      'MapboxLoaded { mapboxController: $mapboxController, myLocationTrackingMode: ${mapboxController.myLocationTrackingMode}, activeStyleString: ${mapboxController.activeStyleString} } }';
}
