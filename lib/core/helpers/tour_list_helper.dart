import 'dart:developer';
import 'dart:io';
import 'dart:math' hide log;

import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/tour_parser.dart';
import 'package:bike_gps/features/domain/entities/tour/tour_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

@lazySingleton
class TourListHelper {
  final Map<String, TourInfo> _tourMap = {};
  final Map<String, TourBounds> _tourBounds = {};
  final ConstantsHelper constantsHelper;
  final TourParser tourParser;

  TourListHelper({@required this.constantsHelper, @required this.tourParser}) {
    _startTourListChangeListener();
  }

  List<TourInfo> get asList => _tourMap.values.toList();

  TourInfo get(String name) => _tourMap[name];

  String getPath(String name) => get(name).filePath;

  String getExtension(String name) => p.extension(getPath(name));

  File getFile(String name) => File(getPath(name));

  String getFileHash(String name) => get(name).fileHash;

  TourBounds getBounds(String name) => _tourBounds[name];

  List<TourBounds> getBoundsList() => _tourBounds.values.toList();

  bool contains(String name) => _tourMap.containsKey(name);

  void add(TourInfo tourInfo) {
    _tourMap[tourInfo.name] = tourInfo;
    _tourBounds[tourInfo.name] =
        TourBounds(bounds: tourInfo.bounds, name: tourInfo.name);
  }

  void remove(String name) {
    _tourMap.remove(name);
    _tourBounds.remove(name);
  }

  void _startTourListChangeListener() {
    DirectoryWatcher(constantsHelper.tourDirectoryPath).events.listen(
      (WatchEvent event) async {
        if (event.type == ChangeType.REMOVE) {
          final String baseNameWithoutExtension =
              p.basenameWithoutExtension(event.path);
          remove(baseNameWithoutExtension);
        } else {
          if (await shouldAddTourToList(filePath: event.path)) {
            final File file = File(event.path);
            add(await tourParser.getTourInfo(file: file));
          }
        }
      },
    );
  }

  Future<List<TourInfo>> initializeTourList() async {
    final List<FileSystemEntity> tourFiles =
        Directory(constantsHelper.tourDirectoryPath).listSync();
    final List<TourInfo> initialTourList = [];
    for (final FileSystemEntity entity in tourFiles) {
      if (await shouldAddTourToList(filePath: entity.path)) {
        final TourInfo tourInfo =
            await tourParser.getTourInfo(file: entity as File);
        initialTourList.add(tourInfo);
        add(tourInfo);
      }
    }
    return initialTourList;
  }

  Future<bool> shouldAddTourToList({@required String filePath}) async {
    try {
      final String fileBasename = p.basenameWithoutExtension(filePath);
      final File file = await _getFileWithBestExtension(fileBasename);
      if (file != null) {
        if (contains(fileBasename)) {
          final bool differentHash = getFileHash(fileBasename) !=
              await constantsHelper.getFileHash(file.path);
          final bool differentExtension =
              getExtension(fileBasename) != p.extension(file.path);
          if (differentHash || differentExtension) {
            return true;
          }
        } else {
          return true;
        }
      }
      return false;
    } on Exception catch (error, stacktrace) {
      log(error.toString(),
          error: error,
          stackTrace: stacktrace,
          time: DateTime.now(),
          name: 'TourListHelper');
      return false;
    }
  }

  Future<File> _getFileWithBestExtension(String name) async {
    final String filePath = p.join(constantsHelper.tourDirectoryPath, name);
    for (final String fileExtension in tourParser.fileExtensionPriority) {
      if (await File(filePath + fileExtension).exists()) {
        return File(filePath + fileExtension);
      }
    }
    return null;
  }
}

class TourBounds {
  final String name;
  LatLngBounds bounds;

  TourBounds({@required this.bounds, @required this.name});

  double get west => bounds.southwest.longitude;

  set west(double newValue) => bounds = LatLngBounds(
      southwest: LatLng(bounds.southwest.latitude, newValue),
      northeast: bounds.northeast);

  double get east => bounds.northeast.longitude;

  set east(double newValue) => bounds = LatLngBounds(
      southwest: bounds.southwest,
      northeast: LatLng(bounds.northeast.latitude, newValue));

  double get north => bounds.northeast.latitude;

  set north(double newValue) => bounds = LatLngBounds(
      southwest: bounds.southwest,
      northeast: LatLng(newValue, bounds.northeast.longitude));

  double get south => bounds.southwest.latitude;

  set south(double newValue) => bounds = LatLngBounds(
      southwest: LatLng(newValue, bounds.southwest.longitude),
      northeast: bounds.northeast);

  double get area => (east - west) * (north - south);

  double getOverlap(TourBounds other) {
    if (east <= other.west ||
        other.east <= west ||
        north <= other.south ||
        other.north <= south) return 0;
    final double overlapArea = (max(west, other.west) - min(east, other.east)) *
        (max(south, other.south) - min(north, other.north));
    return max(0, overlapArea / (area + other.area - overlapArea));
  }

  LatLngBounds get toLatLngBounds => bounds;
}
