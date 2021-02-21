import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../entities/tour/entities.dart';
import '../../repositories/repositories.dart';

@lazySingleton
class GetTour extends UseCase<Tour, Params> {
  final TourRepository repository;

  GetTour({@required this.repository});

  @override
  Future<Either<Failure, Tour>> call(Params params) async {
    return repository.getTour(name: params.name);
  }
}

class Params extends Equatable {
  final String name;

  const Params({@required this.name});

  @override
  List<Object> get props => [name];
}
