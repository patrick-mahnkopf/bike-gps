import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl_platform_interface/mapbox_gl_platform_interface.dart';

import '../../../domain/entities/tour/entities.dart';
import '../../../domain/repositories/tour_repository.dart';
import '../../data_sources/tour/data_sources.dart';

@Injectable(as: TourRepository)
class TourRepositoryImpl implements TourRepository {
  final TourLocalDataSource localDataSource;
  final TourRemoteDataSource remoteDataSource;

  TourRepositoryImpl(
      {@required this.localDataSource, @required this.remoteDataSource});

  @override
  Future<Either<Failure, Tour>> getPathToTour(
      {@required LatLng userLocation, @required LatLng tourStart}) async {
    try {
      return Right(await remoteDataSource.getPathToTour(
          userLocation: userLocation, tourStart: tourStart));
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, Tour>> getTour({@required String name}) async {
    try {
      return Right(await localDataSource.getTour(name: name));
    } on ParserException {
      return Left(ParserFailure());
    }
  }
}
