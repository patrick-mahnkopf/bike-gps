import 'dart:math';

import 'package:bike_gps/features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../core/controllers/controllers.dart';
import '../../../injection_container.dart';

class MapboxWidget extends StatelessWidget {
  final MapboxController mapboxController;

  const MapboxWidget({Key key, this.mapboxController}) : super(key: key);

  void _onMapCreated(MapboxMapController mapboxMapController) {
    getIt<MapboxBloc>().add(MapboxLoaded(
        mapboxController: mapboxController.copyWith(
            mapboxMapController: mapboxMapController)));
  }

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: mapboxController.accessToken,
      styleString: mapboxController.activeStyleString,
      compassEnabled: mapboxController.compassEnabled,
      initialCameraPosition: mapboxController.initialCameraPosition,
      myLocationRenderMode: mapboxController.locationRenderMode,
      onMapCreated: _onMapCreated,
      compassViewPosition: CompassViewPosition.BottomRight,
      compassViewMargins: const Point(32, 32),
      myLocationEnabled: true,
      myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
    );
  }
}
