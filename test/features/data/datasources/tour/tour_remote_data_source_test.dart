import 'dart:convert';
import 'dart:io';

import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/core/helpers/settings_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
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

class MockTourListHelper extends Mock implements TourListHelper {}

class MockSettingsHelper extends Mock implements SettingsHelper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TourRemoteDataSourceImpl dataSource;
  MockHttpClient mockHttpClient;
  MockTourParser mockTourParser;
  MockTourListHelper mockTourListHelper;
  MockSettingsHelper mockSettingsHelper;
  Uri serverStatusUri;
  Uri serverTourUri;
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
      trackPoints: const [
        TrackPointModel(
            latLng: LatLng(0, 0),
            elevation: 0,
            distanceFromStart: 0,
            surface: 'A',
            isWayPoint: false)
      ],
      wayPoints: const []);

  setUp(() {
    serverStatusUri = Uri.parse(
        File('assets/tokens/route_service_status_url.txt').readAsStringSync());
    serverTourUri = Uri.parse(
        File('assets/tokens/route_service_url.txt').readAsStringSync());
    mockHttpClient = MockHttpClient();
    mockTourParser = MockTourParser();
    mockTourListHelper = MockTourListHelper();
    mockSettingsHelper = MockSettingsHelper();
    dataSource = TourRemoteDataSourceImpl(
        client: mockHttpClient,
        tourParser: mockTourParser,
        tourListHelper: mockTourListHelper,
        settingsHelper: mockSettingsHelper);
  });

  void setUpMockHttpClientTourSuccess200() {
    print('ServerURL: $serverTourUri');
    when(mockHttpClient.post(serverTourUri,
            headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(fixture('tour.gpx'), 200));
  }

  void setUpMockHttpClientTourFailure404() {
    when(mockHttpClient.post(serverTourUri,
            headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response('Something went wrong', 404));
  }

  void setUpMockHttpClientStatusSuccess200() {
    print('StatusURL: $serverStatusUri');
    when(mockHttpClient.get(serverStatusUri, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('{"status":"ready"}', 200));
  }

  void setUpMockHttpClientStatusFailure404() {
    when(mockHttpClient.get(serverStatusUri, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('Something went wrong', 404));
  }

  void setUpTourParserGetTourFromFileContentSuccess() {
    when(mockTourParser.getTourFromFileContent(
            tourFileContent: anyNamed('tourFileContent'),
            tourName: anyNamed('tourName'),
            tourType: anyNamed('tourType')))
        .thenAnswer((_) async => Future.value(tTourModel));
  }

  test('should return a Tour when the response code is 200 (success)',
      () async {
    // arrange
    setUpMockHttpClientStatusSuccess200();
    setUpMockHttpClientTourSuccess200();
    setUpTourParserGetTourFromFileContentSuccess();
    final response =
        await mockHttpClient.get(serverStatusUri, headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept':
          '	text/html, application/xhtml+xml, application/xml; charset=utf-8',
    });
    print('response ${response.statusCode}');
    // act
    final result = await dataSource.getPathToTour(
        tourStart: tTourStart, userLocation: tUserLocation);
    // assert
    verify(mockHttpClient.post(any,
        headers: anyNamed('headers'), body: anyNamed('body')));
    expect(result, equals(tTourModel));
  });

  test(
      'should throw a ServerException when the server status response code is 404 or something other than 200',
      () async {
    // arrange
    setUpMockHttpClientStatusFailure404();
    setUpTourParserGetTourFromFileContentSuccess();
    // act
    final call = dataSource.getPathToTour;
    // assert
    expect(() => call(tourStart: tTourStart, userLocation: tUserLocation),
        throwsA(isA<ServerException>()));
  });

  test(
      'should throw a ServerException when the response code is 404 or something other than 200',
      () async {
    // arrange
    setUpMockHttpClientStatusSuccess200();
    setUpMockHttpClientTourFailure404();
    setUpTourParserGetTourFromFileContentSuccess();
    // act
    final call = dataSource.getPathToTour;
    // assert
    expect(() => call(tourStart: tTourStart, userLocation: tUserLocation),
        throwsA(isA<ServerException>()));
  });
}
