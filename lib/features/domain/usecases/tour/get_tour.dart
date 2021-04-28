import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/core/usecases/usecase.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/repositories/tour/tour_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// A use case that gets a tour.
@lazySingleton
class GetTour extends UseCase<Tour, TourParams> {
  final TourRepository repository;

  GetTour({@required this.repository});

  /// Gets the tour with the given [name] from local storage.
  @override
  Future<Either<Failure, Tour>> call(TourParams params) async {
    return repository.getTour(name: params.name);
  }
}

class TourParams extends Equatable {
  final String name;

  const TourParams({@required this.name});

  @override
  List<Object> get props => [name];
}
