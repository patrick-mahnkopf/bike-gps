import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'map_event.dart';
part 'map_state.dart';

/// BLoC responsible for the map screen.
@injectable
class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(TourSelectionViewActive());

  @override
  Stream<MapState> mapEventToState(
    MapEvent event,
  ) async* {
    if (event is TourSelectionViewActivated) {
      yield* _mapTourSelectionViewActivatedToState(event);
    } else if (event is NavigationViewActivated) {
      yield* _mapNavigationViewActivatedToState(event);
    }
  }

  /// Activates the tour selection view.
  ///
  /// Yields [TourSelectionViewActive] state.
  Stream<MapState> _mapTourSelectionViewActivatedToState(
      TourSelectionViewActivated event) async* {
    yield TourSelectionViewActive();
  }

  /// Activates the navigation view.
  ///
  /// Yields [NavigationViewActive] state.
  Stream<MapState> _mapNavigationViewActivatedToState(
      NavigationViewActivated event) async* {
    yield NavigationViewActive();
  }
}
