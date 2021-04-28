import 'package:bike_gps/features/domain/repositories/tour/tour_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../entities/tour/entities.dart';

/// A use case that gets a path to the tour.
@lazySingleton
class GetPathToTour extends UseCase<Tour, PathToTourParams> {
  final TourRepository repository;

  GetPathToTour({@required this.repository});

  /// Gets a path from the [userLocation] to the [tourStart].
  @override
  Future<Either<Failure, Tour>> call(PathToTourParams params) async {
    return repository.getPathToTour(
        userLocation: params.userLocation, tourStart: params.tourStart);
  }
}

class PathToTourParams extends Equatable {
  final LatLng tourStart;
  final LatLng userLocation;

  const PathToTourParams(
      {@required this.tourStart, @required this.userLocation});

  @override
  List<Object> get props => [tourStart, userLocation];
}
