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
