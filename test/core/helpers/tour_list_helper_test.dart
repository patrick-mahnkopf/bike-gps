import 'dart:io';

import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_list_helper.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/tour_parser.dart';
import 'package:bike_gps/features/data/models/tour/tour_info_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:mockito/mockito.dart';

import '../../fixtures/fixture_reader.dart';

class MockConstantsHelper extends Mock implements ConstantsHelper {}

class MockTourParser extends Mock implements TourParser {}

void main() {
  TourListHelper tourListHelper;
  MockConstantsHelper mockConstantsHelper;
  MockTourParser mockTourParser;

  const String tTourListPath = 'test/fixtures/tourList.json';
  final File wrongExtensionFile = fixtureFile('wrong_extension.html');
  final File gpxFile = fixtureFile('tour.gpx');
  final TourInfoModel tourInfo = TourInfoModel(
    name: 'tour',
    bounds: LatLngBounds(
        northeast: const LatLng(0, 0), southwest: const LatLng(0, 0)),
    filePath: 'test/fixtures/tour.gpx',
    fileHash: 'test hash',
    firstPoint: const LatLng(0, 0),
  );

  void setUpConstantsHelperDirectories() {
    when(mockConstantsHelper.tourDirectoryPath).thenReturn('test/fixtures');
    when(mockConstantsHelper.tourListPath).thenReturn(tTourListPath);
  }

  void cleanTourListFile() {
    File(tTourListPath).writeAsStringSync('');
  }

  setUp(() async {
    mockConstantsHelper = MockConstantsHelper();
    mockTourParser = MockTourParser();
    setUpConstantsHelperDirectories();
    cleanTourListFile();
    tourListHelper = TourListHelper(
        constantsHelper: mockConstantsHelper, tourParser: mockTourParser);
  });

  void setUpTourParserExtensionListGpxOnly() {
    when(mockTourParser.fileExtensionPriority).thenReturn(['.gpx']);
  }

  void setUpConstantsHelperDifferentHash() {
    when(mockConstantsHelper.getFileHash(any))
        .thenAnswer((_) => Future.value('different hash'));
  }

  void setUpConstantsHelperCorrectHash() {
    when(mockConstantsHelper.getFileHash(any))
        .thenAnswer((_) => Future.value('test hash'));
  }

  Future<FunctionResult> setUpTourParserTourInfo() async {
    when(mockTourParser.getTourInfo(file: anyNamed('file')))
        .thenAnswer((_) => Future.value(tourInfo));
    await tourListHelper.initializeTourList();
    return FunctionResultSuccess();
  }

  group('shouldAddTourToList', () {
    test('should return false for files with the wrong file type', () async {
      // arrange
      setUpTourParserExtensionListGpxOnly();
      await setUpTourParserTourInfo();
      // act
      final bool result = await tourListHelper.shouldAddTourToList(
          filePath: wrongExtensionFile.path);
      // assert
      expect(result, false);
    });

    test(
        'should return true if the file already is in the tour but the hash is different',
        () async {
      // arrange
      setUpConstantsHelperDifferentHash();
      setUpTourParserExtensionListGpxOnly();
      await setUpTourParserTourInfo();
      // act
      final bool result =
          await tourListHelper.shouldAddTourToList(filePath: gpxFile.path);
      // assert
      expect(result, true);
    });

    test(
        'should return false if the file already is in the tour with the same hash',
        () async {
      // arrange
      setUpTourParserExtensionListGpxOnly();
      setUpTourParserTourInfo();
      setUpConstantsHelperCorrectHash();
      await tourListHelper.initializeTourList();
      // act
      final bool result =
          await tourListHelper.shouldAddTourToList(filePath: gpxFile.path);
      // assert
      expect(result, false);
    });
  });
}
