import 'package:bike_gps/features/domain/entities/search/search_result.dart';
import 'package:bike_gps/features/domain/repositories/search/search_result_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';

@lazySingleton
class GetSearchHistory extends UseCase<List<SearchResult>, NoParams> {
  final SearchResultRepository repository;

  GetSearchHistory({@required this.repository});

  @override
  Future<Either<Failure, List<SearchResult>>> call(NoParams params) async {
    return repository.getSearchHistory();
  }
}
