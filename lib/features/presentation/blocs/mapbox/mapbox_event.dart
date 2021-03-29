part of 'mapbox_bloc.dart';

abstract class MapboxEvent extends Equatable {
  const MapboxEvent();

  @override
  List<Object> get props => [];
}

class MapboxInitialized extends MapboxEvent {
  final MapboxController mapboxController;
  final double devicePixelRatio;

  const MapboxInitialized(
      {@required this.mapboxController, @required this.devicePixelRatio});

  @override
  List<Object> get props => [mapboxController, devicePixelRatio];

  @override
  String toString() =>
      'MapboxInitialized { mapboxController: $mapboxController, devicePixelRatio: $devicePixelRatio }';
}

class MapboxLoaded extends MapboxEvent {
  final MapboxController mapboxController;
  final CameraUpdate cameraUpdate;
  final String accessToken;
  final String activeStyleString;
  final bool compassEnabled;
  final MyLocationRenderMode locationRenderMode;
  final CameraPosition initialCameraPosition;
  final MapboxMapController mapboxMapController;
  final MyLocationTrackingMode myLocationTrackingMode;

  const MapboxLoaded(
      {@required this.mapboxController,
      this.cameraUpdate,
      this.accessToken,
      this.activeStyleString,
      this.compassEnabled,
      this.locationRenderMode,
      this.initialCameraPosition,
      this.mapboxMapController,
      this.myLocationTrackingMode});

  @override
  List<Object> get props => [
        mapboxController,
        mapboxController.myLocationTrackingMode,
        mapboxController.activeStyleString,
        activeStyleString,
        myLocationTrackingMode,
      ];

  @override
  String toString() =>
      'MapboxLoaded { mapboxController: $mapboxController, myLocationTrackingMode: $myLocationTrackingMode, activeStyleString: $activeStyleString }';
}
