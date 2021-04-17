import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/core/helpers/tour_conversion_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

class MockConstantsHelper extends Mock implements ConstantsHelper {}

void main() {
  TourConversionHelper tourConversionHelper;
  MockConstantsHelper mockConstantsHelper;
  final Map<String, String> tTurnSymbolAssetPaths = {
    'testid': 'test/assets/turnArrows/A01.svg'
  };
  final SvgPicture tSvgPictureWhite = SvgPicture.asset(
    tTurnSymbolAssetPaths['testid'],
    color: Colors.white,
    matchTextDirection: true,
    width: 48,
  );
  final SvgPicture tSvgPictureBlack = SvgPicture.asset(
    tTurnSymbolAssetPaths['testid'],
    color: Colors.black,
    matchTextDirection: true,
    width: 48,
  );
  const Icon tInfoIcon = Icon(Icons.info);

  setUp(() async {
    mockConstantsHelper = MockConstantsHelper();
    tourConversionHelper =
        TourConversionHelper(constantsHelper: mockConstantsHelper);
  });

  void setUpConstantsHelper() {
    when(mockConstantsHelper.turnSymbolAssetPaths)
        .thenReturn(tTurnSymbolAssetPaths);
  }

  bool svgPicturesEqual(SvgPicture first, SvgPicture second) {
    if (first.width == second.width &&
        first.colorFilter == second.colorFilter &&
        first.pictureProvider.toString() == second.pictureProvider.toString()) {
      return true;
    } else {
      return false;
    }
  }

  group('getTurnSymbolFromId', () {
    test('should return icon with id testId in white', () {
      // arrange
      setUpConstantsHelper();
      // act
      final SvgPicture result = tourConversionHelper.getTurnSymbolFromId(
          iconId: 'testid') as SvgPicture;
      // assert
      expect(svgPicturesEqual(result, tSvgPictureWhite), true);
    });

    test('should return icon with id testId in black', () {
      // arrange
      setUpConstantsHelper();
      // act
      final SvgPicture result = tourConversionHelper.getTurnSymbolFromId(
          iconId: 'testid', color: Colors.black) as SvgPicture;
      // assert
      expect(svgPicturesEqual(result, tSvgPictureBlack), true);
    });

    bool iconsEqual(Icon first, Icon second) {
      if (first.color == second.color &&
          first.icon == second.icon &&
          first.size == second.size) {
        return true;
      } else {
        return false;
      }
    }

    test('should return info icon for unknown icon ids', () {
      // arrange
      setUpConstantsHelper();
      // act
      final Icon result =
          tourConversionHelper.getTurnSymbolFromId(iconId: 'unknown') as Icon;
      // assert
      expect(iconsEqual(result, tInfoIcon), true);
    });
  });
}
