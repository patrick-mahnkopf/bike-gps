import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/features/data/data_sources/tour/tour_local_data_source.dart';
import 'package:bike_gps/features/data/data_sources/tour/tour_remote_data_source.dart';
import 'package:bike_gps/features/data/models/tour/models.dart';
import 'package:bike_gps/features/data/repositories/tour/tour_repository_impl.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mockito/mockito.dart';

class MockLocalDataSource extends Mock implements TourLocalDataSource {}

class MockRemoteDataSource extends Mock implements TourRemoteDataSource {}

void main() {
  TourRepositoryImpl repository;
  MockLocalDataSource mockLocalDataSource;
  MockRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockLocalDataSource();
    mockRemoteDataSource = MockRemoteDataSource();
    repository = TourRepositoryImpl(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource);
  });

  group('getTour', () {
    const tTourName = 'testName';
    final tTourModel = TourModel(
        ascent: 1,
        bounds: LatLngBounds(
            northeast: const LatLng(1, 1), southwest: const LatLng(0, 0)),
        descent: 1,
        name: "testName",
        tourLength: 3,
        trackPoints: const [],
        wayPoints: const []);
    final Tour tTour = tTourModel;

    test('should return tour when the file was parsed successfully', () async {
      // arrange
      when(mockLocalDataSource.getTour(name: anyNamed('name')))
          .thenAnswer((_) async => tTourModel);
      // act
      final result = await repository.getTour(name: tTourName);
      // assert
      verify(mockLocalDataSource.getTour(name: tTourName));
      expect(result, equals(Right(tTour)));
    });

    test('should return parser failure when the file was parsed unsuccessfully',
        () async {
      // arrange
      when(mockLocalDataSource.getTour(name: anyNamed('name')))
          .thenThrow(ParserException());
      // act
      final result = await repository.getTour(name: tTourName);
      // assert
      verify(mockLocalDataSource.getTour(name: tTourName));
      verifyZeroInteractions(mockRemoteDataSource);
      expect(result, equals(Left(ParserFailure())));
    });
  });

  group('getPathToTour', () {
    const tUserLocation = LatLng(0, 0);
    const tTourStart = LatLng(0, 0);
    final tTourModel = TourModel(
        ascent: 1,
        bounds: LatLngBounds(
            northeast: const LatLng(1, 1), southwest: const LatLng(0, 0)),
        descent: 1,
        name: "testName",
        tourLength: 3,
        trackPoints: const [],
        wayPoints: const []);
    final Tour tTour = tTourModel;

    test(
        'should return tour when the call to the remote data source is successful',
        () async {
      // arrange
      when(mockRemoteDataSource.getPathToTour(
              tourStart: anyNamed('tourStart'),
              userLocation: anyNamed('userLocation')))
          .thenAnswer((_) async => tTourModel);
      // act
      final result = await repository.getPathToTour(
          userLocation: tUserLocation, tourStart: tTourStart);
      // assert
      verify(mockRemoteDataSource.getPathToTour(
          userLocation: tUserLocation, tourStart: tTourStart));
      expect(result, equals(Right(tTour)));
    });

    test(
        'should return a server failure when the call to the remote data source is unsuccessful',
        () async {
      // arrange
      when(mockRemoteDataSource.getPathToTour(
              tourStart: anyNamed('tourStart'),
              userLocation: anyNamed('userLocation')))
          .thenThrow(ServerException());
      // act
      final result = await repository.getPathToTour(
          userLocation: tUserLocation, tourStart: tTourStart);
      // assert
      verify(mockRemoteDataSource.getPathToTour(
          userLocation: tUserLocation, tourStart: tTourStart));
      verifyZeroInteractions(mockLocalDataSource);
      expect(result, equals(Left(ServerFailure())));
    });
  });
}
