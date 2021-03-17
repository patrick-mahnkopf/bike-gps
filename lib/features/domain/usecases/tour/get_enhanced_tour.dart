import 'package:bike_gps/features/domain/repositories/tour/tour_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../entities/tour/entities.dart';

@lazySingleton
class GetEnhancedTour extends UseCase<Tour, EnhancedTourParams> {
  final TourRepository repository;

  GetEnhancedTour({@required this.repository});

  @override
  Future<Either<Failure, Tour>> call(EnhancedTourParams params) async {
    return repository.getEnhancedTour(tour: params.tour);
  }
}

class EnhancedTourParams extends Equatable {
  final Tour tour;

  const EnhancedTourParams({@required this.tour});

  @override
  List<Object> get props => [tour];
}
