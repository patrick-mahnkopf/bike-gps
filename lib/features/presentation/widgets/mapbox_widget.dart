// Dart imports:
import 'dart:math';
import 'dart:typed_data';

// Flutter imports:
import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;

import '../../../core/controllers/controllers.dart';
import '../blocs/mapbox/mapbox_bloc.dart';

class MapboxWidget extends StatelessWidget {
  final MapboxController mapboxController;
  final ConstantsHelper constantsHelper;
  static const List<String> assetImageBasenames = [
    'start_location.png',
    'end_location.png',
    'place_pin.png'
  ];

  const MapboxWidget({Key key, this.mapboxController, this.constantsHelper})
      : super(key: key);

  void _onMapCreated(
      MapboxMapController mapboxMapController, BuildContext context) {
    BlocProvider.of<MapboxBloc>(context).add(MapboxLoaded(
        mapboxController: mapboxController.copyWith(
            mapboxMapController: mapboxMapController)));
  }

  void _onCameraTrackingDismissed(BuildContext context) {
    final MapboxBloc mapboxBloc = BlocProvider.of<MapboxBloc>(context);
    final MapboxState mapboxState = mapboxBloc.state;
    if (mapboxState is MapboxLoadSuccess) {
      if (mapboxState.controller.myLocationTrackingMode !=
          MyLocationTrackingMode.None) {
        mapboxBloc.add(MapboxLoaded(
            mapboxController: mapboxState.controller.copyWith(
                myLocationTrackingMode: MyLocationTrackingMode.None)));
      }
    }
  }

  Future<FunctionResult> _onStyleLoaded() async {
    try {
      for (final String imageBasename in assetImageBasenames) {
        _addImageToController(imageBasename);
      }
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  Future<FunctionResult> _addImageToController(String imageBasename) async {
    try {
      final String imagePath =
          p.join(constantsHelper.mapSymbolPath, imageBasename);
      final ByteData bytes = await rootBundle.load(imagePath);
      final Uint8List list = bytes.buffer.asUint8List();
      final String imageName = p.basenameWithoutExtension(imageBasename);
      mapboxController.mapboxMapController.addImage(imageName, list);
      return FunctionResultSuccess();
    } on Exception catch (error, stackTrace) {
      return FunctionResultFailure(error: error, stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapboxMap(
      accessToken: mapboxController.accessToken,
      styleString: mapboxController.activeStyleString,
      compassEnabled: mapboxController.compassEnabled,
      initialCameraPosition: mapboxController.initialCameraPosition,
      myLocationRenderMode: mapboxController.locationRenderMode,
      onMapCreated: (mapboxMapController) =>
          _onMapCreated(mapboxMapController, context),
      compassViewPosition: CompassViewPosition.BottomRight,
      compassViewMargins: const Point(32, 32),
      myLocationEnabled: true,
      myLocationTrackingMode: mapboxController.myLocationTrackingMode,
      onCameraTrackingDismissed: () => _onCameraTrackingDismissed(context),
      onStyleLoadedCallback: () => _onStyleLoaded(),
    );
  }
}
