import 'package:bike_gps/core/error/exception.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
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

class MockConstantsHelper extends Mock implements ConstantsHelper {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TourRemoteDataSourceImpl dataSource;
  MockHttpClient mockHttpClient;
  MockTourParser mockTourParser;
  MockTourListHelper mockTourListHelper;
  MockSettingsHelper mockSettingsHelper;
  MockConstantsHelper mockConstantsHelper;
  Uri tServerStatusUri;
  Uri tServerRouteServiceUri;
  const tUserLocation = LatLng(0, 0);
  const tTourStart = LatLng(0, 0);
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
    tServerStatusUri = Uri.parse('testStatusUri');
    tServerRouteServiceUri = Uri.parse('testRouteServiceUri');
    mockHttpClient = MockHttpClient();
    mockTourParser = MockTourParser();
    mockTourListHelper = MockTourListHelper();
    mockSettingsHelper = MockSettingsHelper();
    mockConstantsHelper = MockConstantsHelper();
    dataSource = TourRemoteDataSourceImpl(
        client: mockHttpClient,
        tourParser: mockTourParser,
        tourListHelper: mockTourListHelper,
        settingsHelper: mockSettingsHelper,
        constantsHelper: mockConstantsHelper);
  });

  void setUpMockConstantsHelper() {
    when(mockConstantsHelper.serverStatusUri).thenReturn(tServerStatusUri);
    when(mockConstantsHelper.serverRouteServiceUri)
        .thenReturn(tServerRouteServiceUri);
  }

  void setUpMockHttpClientTourSuccess200() {
    when(mockHttpClient.post(tServerRouteServiceUri,
            headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response(fixture('tour.gpx'), 200));
  }

  void setUpMockHttpClientTourFailure404() {
    when(mockHttpClient.post(tServerRouteServiceUri,
            headers: anyNamed('headers'), body: anyNamed('body')))
        .thenAnswer((_) async => http.Response('Something went wrong', 404));
  }

  void setUpMockHttpClientStatusSuccess200() {
    when(mockHttpClient.get(tServerStatusUri, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('{"status":"ready"}', 200));
  }

  void setUpMockHttpClientStatusFailure404() {
    when(mockHttpClient.get(tServerStatusUri, headers: anyNamed('headers')))
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
    setUpMockConstantsHelper();
    setUpMockHttpClientStatusSuccess200();
    setUpMockHttpClientTourSuccess200();
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
      'should throw a ServerException when the server status response code is 404 or something other than 200',
      () async {
    // arrange
    setUpMockConstantsHelper();
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
    setUpMockConstantsHelper();
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
