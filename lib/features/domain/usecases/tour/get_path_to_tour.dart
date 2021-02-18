import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/core/usecases/usecase.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/repositories/repositories.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class GetPathToTour extends UseCase<Tour, Params> {
  final TourRepository repository;

  GetPathToTour({@required this.repository});

  @override
  Future<Either<Failure, Tour>> call(Params params) async {
    return repository.getPathToTour(
        userLocation: params.userLocation, tourStart: params.tourStart);
  }
}

class Params extends Equatable {
  final LatLng tourStart;
  final LatLng userLocation;

  const Params({@required this.tourStart, @required this.userLocation});

  @override
  List<Object> get props => [tourStart, userLocation];
}
