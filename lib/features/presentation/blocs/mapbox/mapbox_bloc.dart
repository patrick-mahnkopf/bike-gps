import 'dart:async';

import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../../core/controllers/controllers.dart';

part 'mapbox_event.dart';
part 'mapbox_state.dart';

@injectable
class MapboxBloc extends Bloc<MapboxEvent, MapboxState> {
  MapboxBloc() : super(MapboxPreInitial());

  @override
  Stream<MapboxState> mapEventToState(
    MapboxEvent event,
  ) async* {
    if (event is MapboxInitialized) {
      yield* _mapMapboxInitializedToState(event);
    } else if (event is MapboxLoaded) {
      yield* _mapMapboxLoadedToState(event);
    }
  }

  Stream<MapboxState> _mapMapboxInitializedToState(
      MapboxInitialized event) async* {
    yield MapboxInitial(controller: event.mapboxController);
  }

  Stream<MapboxState> _mapMapboxLoadedToState(MapboxLoaded event) async* {
    await _applyControllerChanges(event);
    yield MapboxLoadSuccess(controller: event.mapboxController);
  }

  Future<FunctionResult> _applyControllerChanges(MapboxLoaded event) async {
    // final CameraUpdate cameraUpdate;
    // final String activeStyleString;
    // final bool compassEnabled;
    // final MyLocationRenderMode locationRenderMode;
    // final MapboxMapController mapboxMapController;
    // final MyLocationTrackingMode myLocationTrackingMode;
    if (event.mapboxController != null) {
      if (event.cameraUpdate != null) {
        await event.mapboxController.mapboxMapController
            .moveCamera(event.cameraUpdate);
      }
      if (event.mapboxMapController != null) {
        event.mapboxController.mapboxMapController = event.mapboxMapController;
      }
      if (event.myLocationTrackingMode != null) {
        event.mapboxController.myLocationTrackingMode =
            event.myLocationTrackingMode;
        event.mapboxController.mapboxMapController.updateMyLocationTrackingMode(
            event.mapboxController.myLocationTrackingMode);
      }
      if (event.activeStyleString != null) {
        event.mapboxController.activeStyleString = event.activeStyleString;
      }
      event.mapboxController.mapboxMapController.onLineTapped
          .remove(event.mapboxController.onLineTapped);
      event.mapboxController.mapboxMapController.onLineTapped
          .add(event.mapboxController.onLineTapped);
    }
    return FunctionResultSuccess();
  }
}
