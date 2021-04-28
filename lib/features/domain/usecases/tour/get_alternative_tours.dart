import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/core/usecases/usecase.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/repositories/tour/tour_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

/// A use case that gets alternative tours.
@lazySingleton
class GetAlternativeTours extends UseCase<List<Tour>, AlternativeTourParams> {
  final TourRepository repository;

  GetAlternativeTours({@required this.repository});

  /// Gets alternative tours to the main one.
  @override
  Future<Either<Failure, List<Tour>>> call(AlternativeTourParams params) async {
    return repository.getAlternativeTours(mainTourName: params.mainTourName);
  }
}

class AlternativeTourParams extends Equatable {
  final String mainTourName;

  const AlternativeTourParams({@required this.mainTourName});

  @override
  List<Object> get props => [mainTourName];
}
