import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:injectable/injectable.dart';
import 'package:md5_plugin/md5_plugin.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Helper class that handles the app's constants.
@preResolve
@injectable
class ConstantsHelper {
  final String applicationDocumentsDirectoryPath;
  final String applicationSupportDirectoryPath;
  String tourDirectoryPath;
  String searchHistoryPath;
  String tourListPath;
  final Uri serverStatusUri;
  final Uri serverRouteServiceUri;
  static const String mapSymbolPath = 'assets/images/map_symbols';
  static const String turnArrowsPath = 'assets/images/turn_arrows';
  final Map<String, String> turnSymbolAssetPaths;
  final double navigationViewZoom = 16;
  final double tourViewZoom = 14;
  static const double maxAllowedDistanceToTour = 20;

  ConstantsHelper(
      {@required this.applicationDocumentsDirectoryPath,
      @required this.applicationSupportDirectoryPath,
      @required this.turnSymbolAssetPaths,
      @required this.serverStatusUri,
      @required this.serverRouteServiceUri}) {
    /// Uses appropriate directories depending on the OS.
    if (Platform.isAndroid) {
      tourDirectoryPath = p.join(
        applicationSupportDirectoryPath,
        'tours',
      );
    } else {
      tourDirectoryPath = applicationDocumentsDirectoryPath;
    }

    /// The search history file path.
    searchHistoryPath = p.join(
      applicationSupportDirectoryPath,
      'searchHistory.json',
    );

    /// The tour list file path.
    tourListPath = p.join(
      applicationSupportDirectoryPath,
      'tourList.json',
    );

    /// Creates the tour directory if it doesn't exist.
    if (!Directory(tourDirectoryPath).existsSync()) {
      Directory(tourDirectoryPath).create(recursive: true);
    }

    /// Creates the search history file if it doesn't exist.
    if (!File(searchHistoryPath).existsSync()) {
      File(searchHistoryPath).create();
    }

    /// Creates the tour list file if it doesn't exist.
    if (!File(tourListPath).existsSync()) {
      File(tourListPath).create();
    }
  }

  /// Gets the MD5 hash of the file at [filePath].
  ///
  /// Returns null on error of if the file doesn't exist.
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

  /// Initializes the [ConstantsHelper].
  @factoryMethod
  static Future<ConstantsHelper> create() async {
    final Map<String, String> turnArrowPaths = await _getTurnArrowPaths();
    final String serverRouteServiceUrl =
        await rootBundle.loadString('assets/tokens/route_service_url.txt');
    final String serverStatusUrl = await rootBundle
        .loadString('assets/tokens/route_service_status_url.txt');
    return ConstantsHelper(
        applicationDocumentsDirectoryPath:
            (await getApplicationDocumentsDirectory()).path,
        applicationSupportDirectoryPath:
            (await getApplicationSupportDirectory()).path,
        turnSymbolAssetPaths: turnArrowPaths,
        serverStatusUri: Uri.parse(serverStatusUrl),
        serverRouteServiceUri: Uri.parse(serverRouteServiceUrl));
  }

  /// Gets a [Map] of the paths of all turn arrows defined in the app's pubspec.
  static Future<Map<String, String>> _getTurnArrowPaths() async {
    /// Gets all paths registered in the app's pubspec.
    final Map<String, dynamic> manifestMap =
        jsonDecode(await rootBundle.loadString('AssetManifest.json'))
            as Map<String, dynamic>;

    /// Gets all turn arrow paths.
    final Iterable<String> iconPaths =
        manifestMap.keys.where((String key) => key.contains(turnArrowsPath));

    final Map<String, String> turnArrowPaths = {};

    /// Cleans the turn arrow paths and adds them to the map.
    for (final String iconPath in iconPaths) {
      final String fileName = p.basename(iconPath).replaceAll('%20', ' ');
      final String baseName = p.basenameWithoutExtension(fileName);
      turnArrowPaths[baseName.toLowerCase()] = p.join(turnArrowsPath, fileName);
    }
    return turnArrowPaths;
  }
}
