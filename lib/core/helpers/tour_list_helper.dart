import 'dart:developer';
import 'dart:io';

import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/tour_parser.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

@lazySingleton
class TourListHelper {
  final TourList _tourList = TourList();
  final ConstantsHelper constantsHelper;
  final TourParser tourParser;

  List<TourInfo> get asList => _tourList.asList;

  TourInfo get(String name) => _tourList.get(name);

  String getPath(String name) => _tourList.getPath(name);

  String getExtension(String name) => _tourList.getExtension(name);

  File getFile(String name) => _tourList.getFile(name);

  String getFileHash(String name) => _tourList.getFileHash(name);

  TourBounds getBounds(String name) => _tourList.getBounds(name);

  List<TourBounds> getBoundsList() => _tourList.getBoundsList();

  bool contains(String name) => _tourList.contains(name);

  TourListHelper({@required this.constantsHelper, @required this.tourParser}) {
    _startTourListChangeListener();
  }

  void _startTourListChangeListener() {
    DirectoryWatcher(constantsHelper.tourDirectoryPath).events.listen(
      (WatchEvent event) async {
        if (event.type == ChangeType.REMOVE) {
          final String baseNameWithoutExtension =
              p.basenameWithoutExtension(event.path);
          _tourList.remove(baseNameWithoutExtension);
        } else {
          if (await shouldAddTourToList(filePath: event.path)) {
            final File file = File(event.path);
            _tourList.add(await tourParser.getTourInfo(file: file));
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
        _tourList.add(tourInfo);
      }
    }
    return initialTourList;
  }

  Future<bool> shouldAddTourToList({@required String filePath}) async {
    try {
      final String fileBasename = p.basenameWithoutExtension(filePath);
      final File file = await _getFileWithBestExtension(fileBasename);
      if (file != null) {
        if (_tourList.contains(fileBasename)) {
          final bool differentHash = _tourList.getFileHash(fileBasename) !=
              await constantsHelper.getFileHash(file.path);
          final bool differentExtension =
              _tourList.getExtension(fileBasename) != p.extension(file.path);
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
