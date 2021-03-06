import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:bike_gps/features/domain/repositories/search/search_result_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';

/// A use case that adds a search result to the search history.
@lazySingleton
class AddToSearchHistory extends UseCase<void, AddToSearchHistoryParams> {
  final SearchResultRepository repository;

  AddToSearchHistory({@required this.repository});

  /// Adds the [SearchHistoryItemModel] to the search history.
  ///
  /// Returns a [FunctionResultFailure] if an exception occurs and a
  /// [FunctionResultSuccess] otherwise.
  @override
  Future<Either<Failure, FunctionResult>> call(
      AddToSearchHistoryParams params) async {
    return repository.addToSearchHistory(
        searchHistoryItemModel: params.searchHistoryItemModel);
  }
}

class AddToSearchHistoryParams extends Equatable {
  final SearchHistoryItemModel searchHistoryItemModel;

  const AddToSearchHistoryParams({@required this.searchHistoryItemModel});

  @override
  List<Object> get props => [searchHistoryItemModel];
}
