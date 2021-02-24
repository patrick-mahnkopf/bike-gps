part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class QueryLoading extends SearchState {}

class QueryEmpty extends SearchState {
  final List<SearchResult> searchHistory;

  const QueryEmpty({@required this.searchHistory});

  @override
  List<Object> get props => [searchHistory];

  @override
  String toString() => 'QueryEmpty { searchHistory: $searchHistory}';
}

class QueryLoadSuccess extends SearchState {
  final String query;
  final List<SearchResult> searchResults;

  const QueryLoadSuccess({@required this.query, @required this.searchResults});

  @override
  List<Object> get props => [query, searchResults];

  @override
  String toString() =>
      'QueryLoadSuccess { query: $query, searchResults: $searchResults}';
}

class QueryLoadFailure extends SearchState {
  final String message;

  const QueryLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];

  @override
  String toString() => 'QueryLoadFailure { message: $message}';
}

class SearchBarInactive extends SearchState {
  final String previousQuery;
  final List<SearchResult> previousSearchResults;

  const SearchBarInactive(
      {@required this.previousQuery, @required this.previousSearchResults});

  @override
  List<Object> get props => [previousQuery, previousSearchResults];

  @override
  String toString() =>
      'SearchBarInactive { previousQuery: $previousQuery, previousSearchResults: $previousSearchResults }';
}
