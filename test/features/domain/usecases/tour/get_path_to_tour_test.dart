// TODO implement
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/repositories/repositories.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_path_to_tour.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mockito/mockito.dart';

class MockTourRepository extends Mock implements TourRepository {}

void main() {
  GetPathToTour usecase;
  MockTourRepository mockTourRepository;

  setUp(() {
    mockTourRepository = MockTourRepository();
    usecase = GetPathToTour(repository: mockTourRepository);
  });

  const tUserLocation = LatLng(0, 0);
  const tTourStart = LatLng(0, 0);
  final tTour = Tour(
      ascent: 1,
      bounds: LatLngBounds(
          northeast: const LatLng(1, 1), southwest: const LatLng(0, 0)),
      descent: 1,
      filePath: "testPath",
      name: "testName",
      tourLength: 3,
      trackPoints: const [],
      wayPoints: const []);

  test(
      'should get a tour from the curent userLocation to the specified tour starting point',
      () async {
    //arrange
    when(mockTourRepository.getPathToTour(
            userLocation: anyNamed('userLocation'),
            tourStart: anyNamed('tourStart')))
        .thenAnswer((_) async => Right(tTour));
    //act
    final result = await usecase(
        const Params(userLocation: tUserLocation, tourStart: tTourStart));
    //assert
    expect(result, Right(tTour));
    verify(mockTourRepository.getPathToTour(
        userLocation: tUserLocation, tourStart: tTourStart));
    verifyNoMoreInteractions(mockTourRepository);
  });
}
