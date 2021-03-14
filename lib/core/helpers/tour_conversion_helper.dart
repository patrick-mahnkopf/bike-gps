// Flutter imports:
import 'dart:developer';

import 'package:charts_flutter_cf/charts_flutter_cf.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:injectable/injectable.dart';

import 'constants_helper.dart';

@injectable
class TourConversionHelper {
  final ConstantsHelper constantsHelper;

  TourConversionHelper({@required this.constantsHelper});

  Widget getTurnSymbolFromId({@required String iconId, Color color}) {
    final String assetId = _mapTurnSymbolIdToAssetId(iconId);
    log('iconId: $iconId, assetId: $assetId, contained?: ${constantsHelper.turnSymbolAssetPaths.containsKey(assetId.toLowerCase())}',
        name: 'GetNavigationData navigation turnSymbol _getNavigationData');
    if (constantsHelper.turnSymbolAssetPaths
        .containsKey(assetId.toLowerCase())) {
      return SvgPicture.asset(
        constantsHelper.turnSymbolAssetPaths[assetId.toLowerCase()],
        color: color ?? Colors.white,
        width: 48,
      );
    } else {
      return const Icon(Icons.info);
    }
  }

  String _mapTurnSymbolIdToAssetId(String turnSymbolId) {
    switch (turnSymbolId) {
      // Turn left
      case '0':
        return 'A02';
        break;
      // Turn right
      case '1':
        return 'A04';
        break;
      // Turn sharp left
      case '2':
        return 'A11';
        break;
      // Turn sharp right
      case '3':
        return 'A12';
        break;
      // Turn slight left
      case '4':
        return 'A09';
        break;
      // Turn slight right
      case '5':
        return 'A10';
        break;
      // Continue
      case '6':
        return 'GR01';
        break;
      // Enter roundabout
      case '7':
        return '';
        break;
      // Exit roundabout
      case '8':
        return '';
        break;
      // U-turn
      case '9':
        return 'Z01';
        break;
      // Finish
      case '10':
        return 'P01';
        break;
      // Depart
      case '11':
        return 'GR01';
        break;
      // Keep left
      case '12':
        return '';
        break;
      // Keep right
      case '13':
        return '';
        break;
      // Unknown
      case '14':
        return '';
        break;
      default:
        return turnSymbolId;
        break;
    }
  }

  charts.Color mapSurfaceToChartColor({@required String surface}) {
    switch (surface) {
      case 'A':
        return charts.MaterialPalette.blue.shadeDefault;
        break;
      case 'R':
        return charts.MaterialPalette.purple.shadeDefault;
        break;
      case 'S':
        return charts.MaterialPalette.green.shadeDefault;
        break;
      case 'W':
        return charts.MaterialPalette.deepOrange.shadeDefault;
        break;
      case 'P':
        return charts.MaterialPalette.red.shadeDefault;
        break;
      case 'T':
        return charts.MaterialPalette.black;
        break;
      case 'X':
        return charts.MaterialPalette.purple.makeShades(2).last;
        break;
      default:
        return charts.MaterialPalette.blue.shadeDefault;
        break;
    }
  }
}
