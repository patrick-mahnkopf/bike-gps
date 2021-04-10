// Dart imports:
import 'dart:math' show Point;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../core/controllers/controllers.dart';
import '../blocs/mapbox/mapbox_bloc.dart';

class MapboxWidget extends StatelessWidget {
  final MapboxController uninitializedMapboxController;

  const MapboxWidget({Key key, this.uninitializedMapboxController})
      : super(key: key);

  void _onMapCreated(
      MapboxMapController mapboxMapController, BuildContext context) {
    BlocProvider.of<MapboxBloc>(context).add(MapboxLoaded(
        mapboxController: uninitializedMapboxController,
        mapboxMapController: mapboxMapController));
  }

  void _onCameraTrackingDismissed(BuildContext context) {
    final MapboxBloc mapboxBloc = BlocProvider.of<MapboxBloc>(context);
    final MapboxState mapboxState = mapboxBloc.state;
    if (mapboxState is MapboxLoadSuccess) {
      if (mapboxState.controller.myLocationTrackingMode !=
          MyLocationTrackingMode.None) {
        mapboxBloc.add(MapboxLoaded(
            mapboxController: mapboxState.controller,
            myLocationTrackingMode: MyLocationTrackingMode.None));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: uninitializedMapboxController.accessToken,
      styleString: uninitializedMapboxController.activeStyleString,
      compassEnabled: uninitializedMapboxController.compassEnabled,
      initialCameraPosition:
          uninitializedMapboxController.initialCameraPosition,
      myLocationRenderMode: uninitializedMapboxController.locationRenderMode,
      onMapCreated: (mapboxMapController) =>
          _onMapCreated(mapboxMapController, context),
      compassViewPosition: CompassViewPosition.BottomRight,
      compassViewMargins: const Point(32, 32),
      myLocationEnabled: true,
      myLocationTrackingMode:
          uninitializedMapboxController.myLocationTrackingMode,
      onCameraTrackingDismissed: () => _onCameraTrackingDismissed(context),
    );
  }
}
