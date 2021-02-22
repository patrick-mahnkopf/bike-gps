part of 'search_bloc.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();

  @override
  List<Object> get props => [];
}

class SearchHistoryLoaded extends SearchEvent {
  @override
  List<Object> get props => [];

  @override
  String toString() => 'SearchHistoryLoaded { }';
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

  const QuerySubmitted({@required this.searchResult});

  @override
  List<Object> get props => [searchResult];

  @override
  String toString() => 'QuerySubmitted { searchResult: $searchResult }';
}
