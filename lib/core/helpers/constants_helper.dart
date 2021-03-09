import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:md5_plugin/md5_plugin.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

@preResolve
@injectable
class ConstantsHelper {
  final String applicationDocumentsDirectoryPath;
  final String applicationSupportDirectoryPath;
  String tourDirectoryPath;
  String searchHistoryPath;
  final Map<String, String> turnSymbolAssetPaths;
  final double navigationViewZoom = 16;
  final double tourViewZoom = 14;

  ConstantsHelper(
      {@required this.applicationDocumentsDirectoryPath,
      @required this.applicationSupportDirectoryPath,
      @required this.turnSymbolAssetPaths}) {
    tourDirectoryPath = applicationDocumentsDirectoryPath;
    searchHistoryPath = p.join(
      applicationSupportDirectoryPath,
      'searchHistory.json',
    );
    if (!Directory(tourDirectoryPath).existsSync()) {
      Directory(tourDirectoryPath).create(recursive: true);
    }
    if (!File(searchHistoryPath).existsSync()) {
      File(searchHistoryPath).create();
    }
  }

  Future<String> getFileHash(String filePath) async {
    final File file = File(filePath);
    String hash = '';
    if (await file.exists()) {
      try {
        hash = await Md5Plugin.getMD5WithPath(filePath);
      } on Exception catch (exception, stacktrace) {
        log(exception.toString(),
            error: exception,
            stackTrace: stacktrace,
            time: DateTime.now(),
            name: 'MD5 error');
        return null;
      }
    } else {
      log('Tried getting MD5 of not existing file',
          time: DateTime.now(), name: 'MD5 error');
      return null;
    }
    return hash;
  }

  @factoryMethod
  static Future<ConstantsHelper> create() async {
    final Map<String, String> turnArrowPaths = await _getTurnArrowPaths();
    return ConstantsHelper(
        applicationDocumentsDirectoryPath:
            (await getApplicationDocumentsDirectory()).path,
        applicationSupportDirectoryPath:
            (await getApplicationSupportDirectory()).path,
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
      turnArrowPaths[baseName.toLowerCase()] =
          'assets/images/turnArrows/$fileName';
    }
    return turnArrowPaths;
  }
}
