import 'dart:io';

import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/entities/tour/tour_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as p;

/// A list of all avaiable tours.
///
/// Contains the file path, extension, file hash, and bounds for each tour.
class TourList {
  Map<String, TourInfo> _tourMap = {};
  Map<String, TourBounds> _tourBounds = {};

  TourList(
      {@required Map<String, TourInfo> tourMap,
      @required Map<String, TourBounds> tourBounds}) {
    _tourMap = tourMap;
    _tourBounds = tourBounds;
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
}
