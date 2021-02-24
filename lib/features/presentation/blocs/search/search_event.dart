part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class QueryCleared extends SearchEvent {
  @override
  List<Object> get props => [];

  @override
  String toString() => 'QueryCleared { }';
}

class QueryChanged extends SearchEvent {
  final String query;

  const QueryChanged({@required this.query});

  @override
  List<Object> get props => [query];

  @override
  String toString() => 'QueryChanged { query: $query }';
}

class QuerySubmitted extends SearchEvent {
  final SearchResult searchResult;
  final String query;
  final List<SearchResult> searchResults;

  const QuerySubmitted(
      {@required this.searchResult,
      @required this.query,
      @required this.searchResults});

  @override
  List<Object> get props => [searchResult, query, searchResults];

  @override
  String toString() =>
      'QuerySubmitted { searchResult: $searchResult, query: $query, searchResults: $searchResults }';
}

class SearchBarDismissed extends SearchEvent {
  final String query;
  final List<SearchResult> searchResults;

  const SearchBarDismissed(
      {@required this.query, @required this.searchResults});

  @override
  List<Object> get props => [query, searchResults];

  @override
  String toString() =>
      'SearchBarDismissed { query: $query, searchResults: $searchResults }';
}

class SearchBarRecovered extends SearchEvent {
  final String previousQuery;
  final List<SearchResult> previousSearchResults;

  const SearchBarRecovered(
      {@required this.previousQuery, @required this.previousSearchResults});

  @override
  List<Object> get props => [previousQuery, previousSearchResults];

  @override
  String toString() =>
      'SearchBarRecovered { previousQuery: $previousQuery, previousSearchResults: $previousSearchResults }';
}
