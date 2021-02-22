import 'dart:io';

import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/features/data/data_sources/tour_parser/data_sources.dart';
import 'package:bike_gps/features/domain/entities/tour/tour_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:injectable/injectable.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:path/path.dart' as p;

@injectable
class TourListHelper {
  final Map<String, TourInfo> _tourMap = {};
  final ConstantsHelper constantsHelper;
  final TourParser tourParser;

  TourListHelper({@required this.constantsHelper, @required this.tourParser});

  List<TourInfo> get asList => _tourMap.values.toList();

  TourInfo get(String name) => _tourMap[name];

  String getPath(String name) => get(name).filePath;

  File getFile(String name) => File(getPath(name));

  LatLngBounds getBounds(String name) => get(name).bounds;

  bool contains(String name) => get(name) != null;

  void add(TourInfo tourInfo) => _tourMap[tourInfo.name] = tourInfo;

  void updateTourList() {
    Directory(constantsHelper.tourDirectoryPath)
        .list()
        .listen((FileSystemEntity entity) async {
      if (entity is File) {
        final String fileBasename = p.basenameWithoutExtension(entity.path);
        final File file = await _getTourFile(fileBasename);
        final bool notInTourList = !contains(fileBasename);
        final bool differentHash = get(fileBasename).fileHash !=
            await constantsHelper.getFileHash(file.path);
        final bool differentExtension =
            p.extension(get(fileBasename).filePath) != p.extension(file.path);
        if (notInTourList || differentHash || differentExtension) {
          add(await tourParser.getTourInfo(file: file));
        }
      }
    });
  }

  Future<File> _getTourFile(String name) async {
    final String filePath = p.join(constantsHelper.tourDirectoryPath, name);
    for (final String fileExtension in tourParser.fileExtensionPriority) {
      if (await File(filePath + fileExtension).exists()) {
        return File(filePath + fileExtension);
      }
    }
    return null;
  }
}
