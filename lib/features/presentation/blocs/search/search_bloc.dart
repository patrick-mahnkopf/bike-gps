import 'dart:async';

import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/core/usecases/usecase.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:bike_gps/features/domain/entities/search/search_result.dart';
import 'package:bike_gps/features/domain/usecases/search/add_to_search_history.dart';
import 'package:bike_gps/features/domain/usecases/search/get_search_history.dart';
import 'package:bike_gps/features/domain/usecases/search/get_search_results.dart';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

part 'search_event.dart';
part 'search_state.dart';

const String fileFailureMessage = 'File Failure';
const String serverFailureMessage = 'Server Failure';

@preResolve
@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final searchBarController = FloatingSearchBarController();
  final GetSearchResults getSearchResults;
  final GetSearchHistory getSearchHistory;
  final AddToSearchHistory addToSearchHistory;

  SearchBloc(
      {@required this.getSearchResults,
      @required this.getSearchHistory,
      @required this.addToSearchHistory,
      @required SearchState initialState})
      : super(initialState);

  @factoryMethod
  static Future<SearchBloc> create(
      {@required GetSearchResults getSearchResults,
      @required GetSearchHistory getSearchHistory,
      @required AddToSearchHistory addToSearchHistory}) async {
    final Either<Failure, List<SearchResult>> failureOrSearchHistory =
        await getSearchHistory(NoParams());
    final SearchState initialState = failureOrSearchHistory.fold(
      (failure) => QueryLoadFailure(message: _mapFailureToMessage(failure)),
      (searchHistory) => QueryEmpty(searchHistory: searchHistory),
    );
    return SearchBloc(
        getSearchHistory: getSearchHistory,
        getSearchResults: getSearchResults,
        addToSearchHistory: addToSearchHistory,
        initialState: initialState);
  }

  @override
  Stream<SearchState> mapEventToState(
    SearchEvent event,
  ) async* {
    if (event is QueryChanged) {
      yield* _mapQueryChangedToState(event);
    } else if (event is QuerySubmitted) {
      yield* _mapQuerySubmittedToState(event);
    } else if (event is SearchBarDismissed) {
      yield* _mapSearchBarDismissedToState(event);
    } else if (event is SearchBarRecovered) {
      yield* _mapSearchBarRecoveredToState(event);
    }
  }

  Stream<SearchState> _mapQueryChangedToState(QueryChanged event) async* {
    yield QueryLoading();
    if (event.query.isEmpty || event.query == '') {
      final Either<Failure, List<SearchResult>> failureOrSearchHistory =
          await getSearchHistory(NoParams());
      yield* _eitherEmptyOrLoadFailureState(failureOrSearchHistory);
    } else {
      final Either<Failure, List<SearchResult>> failureOrSearchResults =
          await getSearchResults(GetSearchResultsParams(query: event.query));
      yield* _eitherLoadSuccessOrLoadFailureState(
          failureOrSearchResults, event.query);
    }
  }

  Stream<SearchState> _eitherEmptyOrLoadFailureState(
      Either<Failure, List<SearchResult>> failureOrSearchHistory) async* {
    yield failureOrSearchHistory.fold(
      (failure) => QueryLoadFailure(message: _mapFailureToMessage(failure)),
      (searchHistory) {
        searchBarController.clear();
        return QueryEmpty(searchHistory: searchHistory);
      },
    );
  }

  Stream<SearchState> _eitherLoadSuccessOrLoadFailureState(
      Either<Failure, List<SearchResult>> failureOrSearchResults,
      String query) async* {
    yield failureOrSearchResults.fold(
      (failure) => QueryLoadFailure(message: _mapFailureToMessage(failure)),
      (searchResults) =>
          QueryLoadSuccess(query: query, searchResults: searchResults),
    );
  }

  Stream<SearchState> _mapQuerySubmittedToState(QuerySubmitted event) async* {
    yield QueryLoading();
    searchBarController.query = event.searchResult.name;
    final SearchHistoryItemModel searchHistoryItemModel =
        SearchHistoryItemModel.fromSearchResult(
            searchResult: event.searchResult);
    await addToSearchHistory(AddToSearchHistoryParams(
        searchHistoryItemModel: searchHistoryItemModel));
    yield QueryLoadSuccess(
        query: event.query, searchResults: event.searchResults);
  }

  static String _mapFailureToMessage(Failure failure) {
    switch (failure.runtimeType) {
      case FileFailure:
        return fileFailureMessage;
        break;
      case ServerFailure:
        return serverFailureMessage;
        break;
      default:
        return 'Unexpected error';
    }
  }

  Stream<SearchState> _mapSearchBarDismissedToState(
      SearchBarDismissed event) async* {
    yield SearchBarInactive(
        previousQuery: event.query, previousSearchResults: event.searchResults);
  }

  Stream<SearchState> _mapSearchBarRecoveredToState(
      SearchBarRecovered event) async* {
    yield QueryLoading();
    if (event.previousQuery != null && event.previousQuery != '') {
      yield QueryLoadSuccess(
          query: event.previousQuery,
          searchResults: event.previousSearchResults);
    } else {
      searchBarController.clear();
      yield QueryEmpty(searchHistory: event.previousSearchResults);
    }
  }
}
