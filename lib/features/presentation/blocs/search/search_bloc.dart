import 'dart:async';

import 'package:bike_gps/core/helpers/search_history_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/domain/entities/search/search_history_item.dart';
import 'package:bike_gps/features/domain/entities/search/search_result.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

part 'search_event.dart';
part 'search_state.dart';

@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final TourListHelper tourListHelper;
  final SearchHistoryHelper searchHistoryHelper;
  final searchBarController = FloatingSearchBarController();
  SearchBloc(
      {@required this.tourListHelper, @required this.searchHistoryHelper})
      : super(QueryEmpty(searchHistory: searchHistoryHelper.searchHistory));

  @override
  Stream<SearchState> mapEventToState(
    SearchEvent event,
  ) async* {
    if (event is QueryChanged) {
      yield* _mapQueryChangedToState(event);
    }
  }

  Stream<SearchState> _mapQueryChangedToState(QueryChanged event) async* {
    yield QueryLoading();
    if (event.query.isEmpty || event.query == '') {
      yield QueryEmpty(searchHistory: searchHistoryHelper.searchHistory);
    } else {
      // TODO implement get search results
    }
  }
}
