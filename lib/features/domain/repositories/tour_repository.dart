import 'package:bike_gps/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../entities/tour/entities.dart';

abstract class TourRepository {
  Future<Either<Failure, Tour>> getTour({@required String name});

  Future<Either<Failure, Tour>> getPathToTour(
      {@required LatLng userLocation, @required LatLng tourStart});
}
