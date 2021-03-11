import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../domain/entities/tour/entities.dart';

class TourLineModel extends TourLine {
  const TourLineModel(
      {@required Line background,
      @required Line tour,
      @required Line touchArea,
      @required String tourName,
      @required bool isActive,
      @required bool isPathToTour})
      : super(
            background: background,
            tour: tour,
            touchArea: touchArea,
            tourName: tourName,
            isActive: isActive,
            isPathToTour: isPathToTour);
}
