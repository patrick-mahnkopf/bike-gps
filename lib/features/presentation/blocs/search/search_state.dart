part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

/// State of the SearchBloc while loading.
class QueryLoading extends SearchState {}

/// State of the SearchBloc when the query is empty.
///
/// Holds the [searchHistory] to display while the query is empty.
class QueryEmpty extends SearchState {
  final List<SearchResult> searchHistory;

  const QueryEmpty({@required this.searchHistory});

  @override
  List<Object> get props => [searchHistory];

  @override
  String toString() => 'QueryEmpty { searchHistory: $searchHistory}';
}

/// State of the SearchBloc if search results were retrieved successfully.
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

/// State of the SearchBloc if the search failed.
class QueryLoadFailure extends SearchState {
  final String message;

  const QueryLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];

  @override
  String toString() => 'QueryLoadFailure { message: $message}';
}

/// State of the SearchBloc after the search bar is dismissed.
///
/// Saves the [previousQuery] and [previousSearchResults] to restore them when
/// the search bar is reactivated.
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
