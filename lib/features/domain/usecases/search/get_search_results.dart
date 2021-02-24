import 'package:bike_gps/features/domain/entities/search/search_result.dart';
import 'package:bike_gps/features/domain/repositories/search/search_result_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';

@lazySingleton
class GetSearchResults
    extends UseCase<List<SearchResult>, GetSearchResultsParams> {
  final SearchResultRepository repository;

  GetSearchResults({@required this.repository});

  @override
  Future<Either<Failure, List<SearchResult>>> call(
      GetSearchResultsParams params) async {
    return repository.getSearchResults(query: params.query);
  }
}

class GetSearchResultsParams extends Equatable {
  final String query;

  const GetSearchResultsParams({@required this.query});

  @override
  List<Object> get props => [query];
}
