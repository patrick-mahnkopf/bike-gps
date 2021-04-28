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

/// Helper class that handles the app's tour list.
///
/// Contains a list of all tours and frequently accessed information for each.
/// Updates itself when files in the observed directories change.
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

  /// Listens to file changes in the tour directory and updates the tour list.
  void _startTourListChangeListener() {
    DirectoryWatcher(constantsHelper.tourDirectoryPath).events.listen(
      (WatchEvent event) async {
        /// Ignores hidden directories.
        if (!_isHiddenFolder(event.path)) {
          /// Removes the tour info when the tour file is removed.
          if (event.type == ChangeType.REMOVE) {
            FLog.info(text: 'File at ${event.path} got removed');
            final String baseNameWithoutExtension =
                p.basenameWithoutExtension(event.path);
            _tourList.remove(baseNameWithoutExtension);

            /// Handles tour file changes and new files.
          } else {
            log('File change event type: ${event.type}, path: ${event.path}');

            /// Checks if the file has a supported file type.
            if (tourParser.fileExtensionPriority
                .contains(p.extension(event.path))) {
              /// Adds the tour to the list if appropriate.
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

          /// Updates the local tour list file.
          _tourList.changeTourListCacheFile(constantsHelper.tourListPath);
        }
      },
    );
  }

  /// Convenience method to check if the folder at [path] is hidden.
  bool _isHiddenFolder(String path) {
    return path.contains('/.');
  }

  Future<FunctionResult> initializeTourList() async {
    /// Reads the previous tour list from the local file.
    _tourList = TourListModel.fromJson(constantsHelper.tourListPath);

    /// Removes all list entries where the respective tour file no longer
    /// exists.
    for (final TourInfo tourInfo in _tourList.asList) {
      if (!File(tourInfo.filePath).existsSync()) {
        _tourList.remove(tourInfo.name);
      }
    }

    /// Updates the local tour list file.
    _tourList.changeTourListCacheFile(constantsHelper.tourListPath);

    /// Gets all files in the tour directory and all sub directories.
    final List<FileSystemEntity> tourFiles =
        Directory(constantsHelper.tourDirectoryPath).listSync(recursive: true);

    /// Adds all available tour files to the list that should be added.
    for (final FileSystemEntity entity in tourFiles) {
      /// Ignores hidden directories.
      if (!_isHiddenFolder(entity.path)) {
        FLog.info(
            text: 'Found potential tour file for tour list at ${entity.path}');

        /// Checks if the file has a supported file type.
        if (tourParser.fileExtensionPriority
            .contains(p.extension(entity.path))) {
          /// Adds the tour to the list if appropriate.
          if (await shouldAddTourToList(filePath: entity.path)) {
            FLog.info(text: 'Adding tour file to tour list');
            final TourInfo tourInfo =
                await tourParser.getTourInfo(file: entity as File);
            _tourList.add(tourInfo);
          }
        }
      }
    }

    /// Updates the local tour list file.
    _tourList.changeTourListCacheFile(constantsHelper.tourListPath);
    return FunctionResultSuccess();
  }

  /// Determines if the file at [filePath] is a tour that should be added to
  /// the tour list.
  ///
  /// Returns false on error.
  Future<bool> shouldAddTourToList({@required String filePath}) async {
    try {
      /// Checks if the file has a supported file type.
      if (!tourParser.fileExtensionPriority.contains(p.extension(filePath))) {
        return false;
      }
      FLog.info(text: 'Got file path: $filePath');
      final String fileBasename = p.basenameWithoutExtension(filePath);

      /// Gets the file with the highest priority extension if alternatives
      /// exist.
      final File file = await _getFileWithBestExtension(fileBasename);
      FLog.info(text: 'Using file: ${file.path}');
      if (file != null) {
        /// Checks if the file already exists in the tour list.
        if (_tourList.contains(fileBasename)) {
          final bool differentHash = _tourList.getFileHash(fileBasename) !=
              await constantsHelper.getFileHash(file.path);
          final bool differentExtension =
              _tourList.getExtension(fileBasename) != p.extension(file.path);
          FLog.info(
              text:
                  'File already in tour list: differentHash? $differentHash, differentExtension? $differentExtension');

          /// Returns true if the hash or the extension of the file differs
          /// from the respective entry that already was in the list.
          if (differentHash || differentExtension) {
            return true;
          }

          /// Returns true for files not yet in the tour list.
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

  /// Gets the file called [name] with the highest priority extension if
  /// multiple file share the same [name].
  ///
  /// Returns null if no file called [name] with a supported extension can be
  /// found.
  Future<File> _getFileWithBestExtension(String name) async {
    final String filePath = p.join(constantsHelper.tourDirectoryPath, name);

    /// Checks all files that only differ in their file type returning the
    /// first match, therefore the one with the preferred file type.
    for (final String fileExtension in tourParser.fileExtensionPriority) {
      if (await File(filePath + fileExtension).exists()) {
        return File(filePath + fileExtension);
      }
    }
    return null;
  }
}
