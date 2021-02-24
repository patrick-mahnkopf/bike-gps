import 'dart:async';

import 'package:bike_gps/features/presentation/blocs/search/search_bloc.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

part 'map_event.dart';
part 'map_state.dart';

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

  Stream<MapState> _mapTourSelectionViewActivatedToState(
      TourSelectionViewActivated event) async* {
    final SearchBloc searchBloc = BlocProvider.of<SearchBloc>(event.context);
    final SearchState searchState = searchBloc.state;
    if (searchState is SearchBarInactive) {
      searchBloc.add(SearchBarRecovered(
          previousQuery: searchState.previousQuery,
          previousSearchResults: searchState.previousSearchResults));
    }
    yield TourSelectionViewActive();
  }

  Stream<MapState> _mapNavigationViewActivatedToState(
      NavigationViewActivated event) async* {
    final SearchBloc searchBloc = BlocProvider.of<SearchBloc>(event.context);
    final SearchState searchState = searchBloc.state;
    if (searchState is QueryLoadSuccess) {
      searchBloc.add(SearchBarDismissed(
          query: searchState.query, searchResults: searchState.searchResults));
    }
    yield NavigationViewActive();
  }
}
