part of 'search_bloc.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object> get props => [];
}

class QueryLoading extends SearchState {}

class QueryEmpty extends SearchState {
  final List<SearchHistoryItem> searchHistory;

  const QueryEmpty({@required this.searchHistory});

  @override
  List<Object> get props => [searchHistory];

  @override
  String toString() => 'QueryEmpty { searchHistory: $searchHistory}';
}

class QueryLoadSuccess extends SearchState {
  final List<SearchResult> searchResults;

  const QueryLoadSuccess({@required this.searchResults});

  @override
  List<Object> get props => [searchResults];

  @override
  String toString() => 'QueryLoadSuccess { searchResults: $searchResults}';
}

class QueryLoadFailure extends SearchState {
  final String message;

  const QueryLoadFailure({@required this.message});

  @override
  List<Object> get props => [message];

  @override
  String toString() => 'QueryLoadFailure { message: $message}';
}

class SearchBarHidden extends SearchState {
  final String previousQuery;

  const SearchBarHidden({@required this.previousQuery});

  @override
  List<Object> get props => [previousQuery];

  @override
  String toString() => 'SearchBarHidden { previousQuery: $previousQuery}';
}
