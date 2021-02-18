import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:injectable/injectable.dart';

@injectable
class TurnSymbolHelper {
  final Map<String, String> turnSymbolAssetPaths;

  TurnSymbolHelper({@required this.turnSymbolAssetPaths});

  Widget getTurnSymbolFromId({@required String iconId, Color color}) {
    if (turnSymbolAssetPaths.containsKey(iconId.toLowerCase())) {
      return SvgPicture.asset(
        turnSymbolAssetPaths[iconId.toLowerCase()],
        color: color ?? Colors.white,
        width: 48,
      );
    } else {
      return const Icon(Icons.info);
    }
  }
}
