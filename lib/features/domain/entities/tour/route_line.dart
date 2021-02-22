import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

class TourLine extends Equatable {
  final Line background;
  final Line route;
  final Line touchArea;

  const TourLine(
      {@required this.background,
      @required this.route,
      @required this.touchArea});

  @override
  List<Object> get props => [background, route, touchArea];
}
