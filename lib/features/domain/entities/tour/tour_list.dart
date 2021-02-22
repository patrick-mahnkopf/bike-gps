import 'dart:io';

import 'package:bike_gps/features/domain/entities/tour/tour_info.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class TourList {
  final Map<String, TourInfo> _tourMap = {};

  List<TourInfo> get asList => _tourMap.values.toList();

  TourInfo get(String name) => _tourMap[name];

  String getPath(String name) => get(name).filePath;

  File getFile(String name) => File(getPath(name));

  LatLngBounds getBounds(String name) => get(name).bounds;

  bool contains(String name) => get(name) != null;

  void add(TourInfo tourInfo) => _tourMap[tourInfo.name] = tourInfo;
}
