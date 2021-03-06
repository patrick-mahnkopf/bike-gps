import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/repositories/tour/tour_repository.dart';
import 'package:bike_gps/features/domain/usecases/tour/get_tour.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mockito/mockito.dart';

class MockTourRepository extends Mock implements TourRepository {}

void main() {
  GetTour usecase;
  MockTourRepository mockTourRepository;

  setUp(() {
    mockTourRepository = MockTourRepository();
    usecase = GetTour(repository: mockTourRepository);
  });

  const tName = 'testName';
  final tTour = Tour(
      ascent: 1,
      bounds: LatLngBounds(
          northeast: const LatLng(1, 1), southwest: const LatLng(0, 0)),
      descent: 1,
      name: "testName",
      tourLength: 3,
      trackPoints: const [
        TrackPoint(
            latLng: LatLng(0, 0),
            elevation: 0,
            distanceFromStart: 0,
            surface: 'A',
            isWayPoint: false)
      ],
      wayPoints: const []);

  test('should get the tour with the specified name', () async {
    //arrange
    when(mockTourRepository.getTour(name: anyNamed('name')))
        .thenAnswer((_) async => Right(tTour));
    //act
    final result = await usecase(const TourParams(name: tName));
    //assert
    expect(result, Right(tTour));
    verify(mockTourRepository.getTour(name: tName));
    verifyNoMoreInteractions(mockTourRepository);
  });
}
