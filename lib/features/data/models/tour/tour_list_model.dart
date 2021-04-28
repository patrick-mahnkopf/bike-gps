import 'dart:convert';
import 'dart:io';

import 'package:bike_gps/features/data/models/tour/tour_info_model.dart';
import 'package:bike_gps/features/domain/entities/tour/entities.dart';
import 'package:bike_gps/features/domain/entities/tour/tour_list.dart';
import 'package:flutter/foundation.dart';

/// A list of a [TourListModel] item for each tour available in the tour folder.
class TourListModel extends TourList {
  TourListModel(
      {@required Map<String, TourInfoModel> tourMap,
      @required Map<String, TourBounds> tourBounds})
      : super(tourMap: tourMap, tourBounds: tourBounds);

  /// Converts the Json at [tourListPath] to a [TourListModel].
  factory TourListModel.fromJson(String tourListPath) {
    final Map<String, TourInfoModel> tourMap = {};
    final Map<String, TourBounds> tourBounds = {};
    final String tourListContent = File(tourListPath).readAsStringSync();
    if (tourListContent != '') {
      final List tourInfos = jsonDecode(tourListContent) as List;
      for (final dynamic tourInfo in tourInfos) {
        final TourInfoModel tourInfoModel =
            TourInfoModel.fromJson(tourInfo as Map<String, dynamic>);
        tourMap[tourInfoModel.name] = tourInfoModel;
        tourBounds[tourInfoModel.name] =
            TourBounds(bounds: tourInfoModel.bounds, name: tourInfoModel.name);
      }
    }
    return TourListModel(tourMap: tourMap, tourBounds: tourBounds);
  }

  /// Writes this [TourListModel] object to the Json at [tourListPath].
  void changeTourListCacheFile(String tourListPath) {
    File(tourListPath).writeAsStringSync(jsonEncode(asList), flush: true);
  }
}
