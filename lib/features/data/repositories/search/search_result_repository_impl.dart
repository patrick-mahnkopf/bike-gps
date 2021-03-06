import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/data_sources/search/search_result_local_data_source.dart';
import 'package:bike_gps/features/data/data_sources/search/search_result_remote_data_source.dart';
import 'package:bike_gps/features/data/models/search/models.dart';
import 'package:bike_gps/features/domain/entities/search/entities.dart';
import 'package:bike_gps/features/domain/repositories/search/search_result_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';

/// The SearchResultRepository handling communication with the search data
/// sources.
@Injectable(as: SearchResultRepository)
class SearchResultRepositoryImpl implements SearchResultRepository {
  final SearchResultLocalDataSource localDataSource;
  final SearchResultRemoteDataSource remoteDataSource;

  SearchResultRepositoryImpl(
      {@required this.localDataSource, @required this.remoteDataSource});

  /// Gets the current search history.
  ///
  /// Returns a [FileFailure] in case of a [FileException].
  @override
  Future<Either<Failure, List<SearchResult>>> getSearchHistory() async {
    try {
      return Right(await localDataSource.getSearchHistory());
    } on FileException {
      return Left(FileFailure());
    }
  }

  /// Adds [searchHistoryItemModel] to the current search history.
  ///
  /// Returns a [FileFailure] in case of a [FileException] and a
  /// [FunctionResultSuccess] otherwise.
  @override
  Future<Either<Failure, FunctionResult>> addToSearchHistory(
      {@required SearchHistoryItemModel searchHistoryItemModel,
      @required TourListHelper tourListHelper}) async {
    try {
      return Right(await localDataSource.addToSearchHistory(
          searchHistoryItemModel: searchHistoryItemModel));
    } on FileException {
      return Left(FileFailure());
    }
  }

  /// Gets the search results for the [query].
  ///
  /// Returns a [ServerFailure] in case of a [ServerException].
  @override
  Future<Either<Failure, List<SearchResult>>> getSearchResults(
      {@required String query}) async {
    try {
      return Right(await remoteDataSource.getSearchResults(query: query));
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
