import 'dart:async';

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
    yield MapboxLoading(controller: event.mapboxController);
    event.mapboxController.devicePixelRatio = event.devicePixelRatio;
    yield MapboxInitial(controller: event.mapboxController);
  }

  Stream<MapboxState> _mapMapboxLoadedToState(MapboxLoaded event) async* {
    final MapboxController controller = event.mapboxController;
    MyLocationTrackingMode myLocationTrackingMode;
    String activeStyleString;
    if (controller != null) {
      if (event.cameraUpdate != null) {
        await controller.mapboxMapController.moveCamera(event.cameraUpdate);
      }
      if (event.mapboxMapController != null) {
        controller.mapboxMapController = event.mapboxMapController;
      }
      if (event.myLocationTrackingMode != null) {
        controller.myLocationTrackingMode = event.myLocationTrackingMode;
        await controller.mapboxMapController
            .updateMyLocationTrackingMode(controller.myLocationTrackingMode);
        myLocationTrackingMode = event.myLocationTrackingMode;
      }
      controller.mapboxMapController.onLineTapped
          .remove(controller.onLineTapped);
      controller.mapboxMapController.onLineTapped.add(controller.onLineTapped);
      if (event.activeStyleString != null) {
        controller.activeStyleString = event.activeStyleString;
        activeStyleString = event.activeStyleString;
      }
    }
    yield MapboxLoadSuccess(
        controller: event.mapboxController,
        activeStyleString: activeStyleString,
        myLocationTrackingMode: myLocationTrackingMode);
  }
}
