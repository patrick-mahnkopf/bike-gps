import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:bike_gps/features/domain/entities/search/search_result.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';

abstract class SearchResultRepository {
  Future<Either<Failure, List<SearchResult>>> getSearchResults(
      {@required String query});

  Future<Either<Failure, List<SearchResult>>> getSearchHistory();

  Future<Either<Failure, FunctionResult>> addToSearchHistory(
      {@required SearchHistoryItemModel searchHistoryItemModel});
}
