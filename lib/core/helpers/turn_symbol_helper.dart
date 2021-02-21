// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:injectable/injectable.dart';

import 'constants_helper.dart';

@singleton
class TurnSymbolHelper {
  final ConstantsHelper constantsHelper;

  TurnSymbolHelper({@required this.constantsHelper});

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
}
