import 'dart:async';

import 'package:bike_gps/core/controllers/controllers.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

part 'mapbox_event.dart';
part 'mapbox_state.dart';

class MapboxBloc extends Bloc<MapboxEvent, MapboxState> {
  MapboxBloc() : super(MapboxInitial());

  @override
  Stream<MapboxState> mapEventToState(
    MapboxEvent event,
  ) async* {
    if (event is MapboxLoaded) {
      yield* _mapMapboxLoadedToState(event);
    }
  }

  Stream<MapboxState> _mapMapboxLoadedToState(MapboxLoaded event) async* {
    yield MapboxLoadSuccess(controller: event.mapboxController);
  }
}
