import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/usecases/usecase.dart';
import '../../entities/tour/entities.dart';
import '../../repositories/repositories.dart';

@lazySingleton
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
