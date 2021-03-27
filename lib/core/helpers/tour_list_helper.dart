import 'dart:developer';
import 'dart:io';

import 'package:bike_gps/core/function_results/function_result.dart';
import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/tour_parser.dart';
import 'package:bike_gps/features/data/models/tour/tour_list_model.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:f_logs/f_logs.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

@lazySingleton
class TourListHelper {
  TourListModel _tourList;
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
        if (!event.path.contains('/.')) {
          if (event.type == ChangeType.REMOVE) {
            FLog.info(text: 'File at ${event.path} got removed');
            final String baseNameWithoutExtension =
                p.basenameWithoutExtension(event.path);
            _tourList.remove(baseNameWithoutExtension);
          } else {
            log('File change event type: ${event.type}, path: ${event.path}');
            if (tourParser.fileExtensionPriority
                .contains(p.extension(event.path))) {
              if (await shouldAddTourToList(filePath: event.path)) {
                await Future.delayed(const Duration(milliseconds: 100));
                log('Found potential tour file for tour list at ${event.path}',
                    name: 'TourListHelper debug');
                FLog.info(
                    text:
                        'Found potential tour file for tour list at ${event.path}');
                final File file = File(event.path);
                _tourList.add(await tourParser.getTourInfo(file: file));
              }
            }
          }
          _tourList.changeTourListCacheFile(constantsHelper.tourListPath);
        }
      },
    );
  }

  Future<FunctionResult> initializeTourList() async {
    _tourList = TourListModel.fromJson(constantsHelper.tourListPath);
    for (final TourInfo tourInfo in _tourList.asList) {
      if (!File(tourInfo.filePath).existsSync()) {
        _tourList.remove(tourInfo.name);
      }
    }
    _tourList.changeTourListCacheFile(constantsHelper.tourListPath);
    final List<FileSystemEntity> tourFiles =
        Directory(constantsHelper.tourDirectoryPath).listSync();
    for (final FileSystemEntity entity in tourFiles) {
      if (!entity.path.contains('/.')) {
        FLog.info(
            text: 'Found potential tour file for tour list at ${entity.path}');
        if (tourParser.fileExtensionPriority
            .contains(p.extension(entity.path))) {
          if (await shouldAddTourToList(filePath: entity.path)) {
            FLog.info(text: 'Adding tour file to tour list');
            final TourInfo tourInfo =
                await tourParser.getTourInfo(file: entity as File);
            _tourList.add(tourInfo);
          }
        }
      }
    }
    _tourList.changeTourListCacheFile(constantsHelper.tourListPath);
    return FunctionResultSuccess();
  }

  Future<bool> shouldAddTourToList({@required String filePath}) async {
    try {
      if (!tourParser.fileExtensionPriority.contains(p.extension(filePath))) {
        return false;
      }
      FLog.info(text: 'Got file path: $filePath');
      final String fileBasename = p.basenameWithoutExtension(filePath);
      final File file = await _getFileWithBestExtension(fileBasename);
      FLog.info(text: 'Using file: ${file.path}');
      if (file != null) {
        if (_tourList.contains(fileBasename)) {
          final bool differentHash = _tourList.getFileHash(fileBasename) !=
              await constantsHelper.getFileHash(file.path);
          final bool differentExtension =
              _tourList.getExtension(fileBasename) != p.extension(file.path);
          FLog.info(
              text:
                  'File already in tour list: differentHash? $differentHash, differentExtension? $differentExtension');
          if (differentHash || differentExtension) {
            return true;
          }
        } else {
          FLog.info(text: 'File not yet in tour list');
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
