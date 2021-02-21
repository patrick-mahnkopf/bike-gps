import 'package:bike_gps/core/helpers/helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TurnSymbolHelper turnSymbolHelper;
  ConstantsHelper constantsHelper;
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
    constantsHelper = ConstantsHelper(
        applicationDocumentsDirectoryPath: '',
        turnSymbolAssetPaths: tTurnSymbolAssetPaths);
    turnSymbolHelper = TurnSymbolHelper(constantsHelper: constantsHelper);
  });

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
      // act
      final SvgPicture result =
          turnSymbolHelper.getTurnSymbolFromId(iconId: 'testid') as SvgPicture;
      // assert
      expect(svgPicturesEqual(result, tSvgPictureWhite), true);
    });

    test('should return icon with id testId in black', () {
      // arrange
      // act
      final SvgPicture result = turnSymbolHelper.getTurnSymbolFromId(
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
      // act
      final Icon result =
          turnSymbolHelper.getTurnSymbolFromId(iconId: 'unknown') as Icon;
      // assert
      expect(iconsEqual(result, tInfoIcon), true);
    });
  });
}
