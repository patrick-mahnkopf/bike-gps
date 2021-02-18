import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(TourSelectionViewActive());

  @override
  Stream<MapState> mapEventToState(
    MapEvent event,
  ) async* {
    if (event is TourSelectionViewActivated) {
      yield* _mapTourSelectionViewActivatedToState();
    } else if (event is NavigationViewActivated) {
      yield* _mapNavigationViewActivatedToState();
    }
  }

  Stream<MapState> _mapTourSelectionViewActivatedToState() async* {
    yield TourSelectionViewActive();
  }

  Stream<MapState> _mapNavigationViewActivatedToState() async* {
    yield NavigationViewActive();
  }
}
