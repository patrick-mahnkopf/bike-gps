import 'dart:convert';

import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/features/data/data_sources/tour/tour_remote_data_source.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/tour_parser.dart';
import 'package:bike_gps/features/data/models/tour/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mockito/mockito.dart';

import '../../../../fixtures/fixture_reader.dart';

class MockHttpClient extends Mock implements http.Client {}

class MockTourParser extends Mock implements TourParser {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TourRemoteDataSourceImpl dataSource;
  MockHttpClient mockHttpClient;
  MockTourParser mockTourParser;
  const tUserLocation = LatLng(0, 0);
  const tTourStart = LatLng(0, 0);
  final Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    'Accept':
        'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8',
  };
  final body = jsonEncode(<String, dynamic>{
    'coordinates': [
      [tUserLocation.longitude, tUserLocation.latitude],
      [tTourStart.longitude, tTourStart.latitude]
    ],
    'extra_info': [
      'surface',
      'waycategory',
      'waytype',
      'traildifficulty',
    ],
    'instructions': 'true',
    'instructions_format': 'text',
  });
  final TourModel tTourModel = TourModel(
      ascent: 1,
      bounds: LatLngBounds(
          northeast: const LatLng(52.344188, 9.771605),
          southwest: const LatLng(52.334831, 9.755204)),
      descent: 1,
      name: "testName",
      tourLength: 3,
      trackPoints: const [],
      wayPoints: const []);

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockTourParser = MockTourParser();
    dataSource = TourRemoteDataSourceImpl(
        client: mockHttpClient, tourParser: mockTourParser);
  });

  void setUpMockHttpClientSuccess200() {
    when(mockHttpClient.post(any,
            headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(fixture('tour.gpx'), 200));
  }

  void setUpMockHttpClientFailure404() {
    when(mockHttpClient.post(any,
            headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response('Something went wrong', 404));
  }

  void setUpTourParserGetTourFromFileContentSuccess() {
    when(mockTourParser.getTourFromFileContent(
            tourFileContent: anyNamed('tourFileContent'),
            tourName: anyNamed('tourName')))
        .thenAnswer((_) async => Future.value(tTourModel));
  }

  test('should return a Tour when the response code is 200 (success)',
      () async {
    // arrange
    setUpMockHttpClientSuccess200();
    setUpTourParserGetTourFromFileContentSuccess();
    // act
    final result = await dataSource.getPathToTour(
        tourStart: tTourStart, userLocation: tUserLocation);
    // assert
    verify(mockHttpClient.post(any,
        headers: anyNamed('headers'), body: anyNamed('body')));
    expect(result, equals(tTourModel));
  });

  test(
      'should throw a ServerException when the response code is 404 or something other than 200',
      () async {
    // arrange
    setUpMockHttpClientFailure404();
    setUpTourParserGetTourFromFileContentSuccess();
    // act
    final call = dataSource.getPathToTour;
    // assert
    expect(() => call(tourStart: tTourStart, userLocation: tUserLocation),
        throwsA(isA<ServerException>()));
  });
}
