import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

@preResolve
@singleton
class ConstantsHelper {
  final String applicationDocumentsDirectoryPath;
  String tourDirectoryPath;
  final Map<String, String> turnSymbolAssetPaths;

  ConstantsHelper(
      {@required this.applicationDocumentsDirectoryPath,
      @required this.turnSymbolAssetPaths}) {
    tourDirectoryPath = p.join(
      applicationDocumentsDirectoryPath,
      'tours',
    );
  }

  @factoryMethod
  static Future<ConstantsHelper> create() async {
    final Map<String, String> turnArrowPaths = await _getTurnArrowPaths();
    return ConstantsHelper(
        applicationDocumentsDirectoryPath:
            (await getApplicationDocumentsDirectory()).path,
        turnSymbolAssetPaths: turnArrowPaths);
  }

  static Future<Map<String, String>> _getTurnArrowPaths() async {
    final Map<String, dynamic> manifestMap =
        jsonDecode(await rootBundle.loadString('AssetManifest.json'))
            as Map<String, dynamic>;
    final Iterable<String> iconPaths =
        manifestMap.keys.where((String key) => key.contains('turnArrows/'));

    final Map<String, String> turnArrowPaths = {};
    for (final String iconPath in iconPaths) {
      final String fileName = p.basename(iconPath).replaceAll('%20', ' ');
      final String baseName = p.basenameWithoutExtension(fileName);
      turnArrowPaths[baseName.toLowerCase()] = 'assets/turnArrows/$fileName';
    }
    return turnArrowPaths;
  }
}
