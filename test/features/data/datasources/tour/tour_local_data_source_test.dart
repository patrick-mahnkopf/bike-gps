import 'dart:io';

import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/data_sources/tour/tour_local_data_source.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/tour_parser.dart';
import 'package:bike_gps/features/data/models/tour/models.dart';
import 'package:bike_gps/features/domain/entities/tour/tour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mockito/mockito.dart';

class MockTourParser extends Mock implements TourParser {}

class MockConstantsHelper extends Mock implements ConstantsHelper {}

class MockTourListHelper extends Mock implements TourListHelper {}

void main() {
  MockTourParser mockTourParser;
  MockConstantsHelper mockConstantsHelper;
  MockTourListHelper mockTourListHelper;
  TourLocalDataSource tourLocalDataSource;

  setUp(() {
    mockTourParser = MockTourParser();
    mockConstantsHelper = MockConstantsHelper();
    mockTourListHelper = MockTourListHelper();
    tourLocalDataSource = TourLocalDataSourceImpl(
        tourParser: mockTourParser,
        constantsHelper: mockConstantsHelper,
        tourListHelper: mockTourListHelper);
  });

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
  final File tFile = File('');

  test('should return tour when the file was parsed successfully', () async {
    // arrange
    when(mockTourParser.getTour(file: anyNamed('file')))
        .thenAnswer((_) async => tTourModel);
    when(mockTourListHelper.getFile(any)).thenReturn(tFile);
    // act
    final result = await tourLocalDataSource.getTour(name: tTourName);
    // assert
    verify(mockTourParser.getTour(file: tFile));
    expect(result, equals(tTour));
  });

  test('should throw parser exception when the file was parsed unsuccessfully',
      () async {
    // arrange
    when(mockTourParser.getTour(file: anyNamed('file'))).thenReturn(null);
    // act
    final call = tourLocalDataSource.getTour;
    // assert
    expect(() => call(name: tTourName), throwsA(isA<ParserException>()));
  });
}
