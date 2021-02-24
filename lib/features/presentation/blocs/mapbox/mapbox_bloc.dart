import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

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
    if (state is MapboxInitial) {
      event.mapboxController.mapboxMapController.onLineTapped
          .add(event.mapboxController.onLineTapped);
    }
    yield MapboxLoadSuccess(controller: event.mapboxController);
  }
}
