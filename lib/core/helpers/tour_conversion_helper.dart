// Flutter imports:
import 'package:charts_flutter_cf/charts_flutter_cf.dart' as charts;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:injectable/injectable.dart';

import 'constants_helper.dart';

@singleton
class TourConversionHelper {
  final ConstantsHelper constantsHelper;

  TourConversionHelper({@required this.constantsHelper});

  Widget getTurnSymbolFromId({@required String iconId, Color color}) {
    if (constantsHelper.turnSymbolAssetPaths
        .containsKey(iconId.toLowerCase())) {
      return SvgPicture.asset(
        constantsHelper.turnSymbolAssetPaths[iconId.toLowerCase()],
        color: color ?? Colors.white,
        width: 48,
      );
    } else {
      return const Icon(Icons.info);
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
