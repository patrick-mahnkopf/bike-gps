import 'package:bike_gps/features/data/data_sources/tour/tour_local_data_source.dart';
import 'package:bike_gps/features/data/data_sources/tour/tour_remote_data_source.dart';
import 'package:bike_gps/features/data/models/tour/models.dart';
import 'package:bike_gps/features/domain/entities/tour/tour.dart';
import 'package:bike_gps/features/domain/repositories/tour/tour_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl_platform_interface/mapbox_gl_platform_interface.dart';

import '../../../../core/error/exception.dart';
import '../../../../core/error/failure.dart';

/// The TourRepository handling communication with the tour data sources.
@Injectable(as: TourRepository)
class TourRepositoryImpl implements TourRepository {
  final TourLocalDataSource localDataSource;
  final TourRemoteDataSource remoteDataSource;

  TourRepositoryImpl(
      {@required this.localDataSource, @required this.remoteDataSource});

  /// Gets a [TourModel] for the path from [userLocation] to [tourStart].
  ///
  /// Returns a [ServerFailure] in case of a [ServerException].
  @override
  Future<Either<Failure, TourModel>> getPathToTour(
      {@required LatLng userLocation, @required LatLng tourStart}) async {
    try {
      return Right(await remoteDataSource.getPathToTour(
          userLocation: userLocation, tourStart: tourStart));
    } on ServerException {
      return Left(ServerFailure());
    }
  }

  /// Gets a [TourModel] for the given tour [name].
  ///
  /// Returns a [ParserFailure] in case of a [ParserException].
  @override
  Future<Either<Failure, TourModel>> getTour({@required String name}) async {
    try {
      return Right(await localDataSource.getTour(name: name));
    } on ParserException {
      return Left(ParserFailure());
    }
  }

  /// Gets alternative tours for the given tour [mainTourName].
  ///
  /// Returns a [ParserFailure] in case of a [ParserException] and a
  /// [TourListFailure] in case of a [TourListException].
  @override
  Future<Either<Failure, List<TourModel>>> getAlternativeTours(
      {@required String mainTourName}) async {
    try {
      return Right(await localDataSource.getAlternativeTours(
          mainTourName: mainTourName));
    } on ParserException {
      return Left(ParserFailure());
    } on TourListException {
      return Left(TourListFailure());
    }
  }

  /// Gets an enhanced version of the [tour].
  ///
  /// Returns a [ParserFailure] in case of a [ParserException] and a
  /// [ServerFailure] in case of a [ServerException].
  @override
  Future<Either<Failure, Tour>> getEnhancedTour({Tour tour}) async {
    try {
      return Right(await remoteDataSource.getEnhancedTour(tour: tour));
    } on ParserException {
      return Left(ParserFailure());
    } on ServerException {
      return Left(ServerFailure());
    }
  }
}
