import 'package:bike_gps/features/data/data_sources/tour/tour_local_data_source.dart';
import 'package:bike_gps/features/data/data_sources/tour/tour_remote_data_source.dart';
import 'package:bike_gps/features/domain/repositories/tour/tour_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl_platform_interface/mapbox_gl_platform_interface.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../domain/entities/tour/entities.dart';

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