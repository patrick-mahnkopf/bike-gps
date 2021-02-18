import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/core/usecases/usecase.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/repositories/repositories.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

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
