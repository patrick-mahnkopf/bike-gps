import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/features/data/data_sources/tour/data_sources.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/data_sources.dart';
import 'package:bike_gps/features/data/models/tour/models.dart';
import 'package:bike_gps/features/domain/entities/tour/tour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mockito/mockito.dart';

class MockTourParser extends Mock implements TourParser {}

void main() {
  MockTourParser mockTourParser;
  TourLocalDataSource tourLocalDataSource;

  setUp(() {
    mockTourParser = MockTourParser();
    tourLocalDataSource = TourLocalDataSourceImpl(tourParser: mockTourParser);
  });

  const tTourName = 'testName';
  final tTourModel = TourModel(
      ascent: 1,
      bounds: LatLngBounds(
          northeast: const LatLng(1, 1), southwest: const LatLng(0, 0)),
      descent: 1,
      filePath: "testPath",
      name: "testName",
      tourLength: 3,
      trackPoints: const [],
      wayPoints: const []);
  final Tour tTour = tTourModel;

  test('should return tour when the file was parsed successfully', () async {
    // arrange
    when(mockTourParser.getTour(name: anyNamed('name')))
        .thenAnswer((_) async => tTourModel);
    // act
    final result = await tourLocalDataSource.getTour(name: tTourName);
    // assert
    verify(mockTourParser.getTour(name: tTourName));
    expect(result, equals(tTour));
  });

  test('should throw parser exception when the file was parsed unsuccessfully',
      () async {
    // arrange
    when(mockTourParser.getTour(name: anyNamed('name'))).thenReturn(null);
    // act
    final call = tourLocalDataSource.getTour;
    // assert
    expect(() => call(name: tTourName), throwsA(isA<ParserException>()));
  });
}
