import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/core/helpers/tour_conversion_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../injection_container.dart';
import '../../../domain/entities/tour/entities.dart';
import 'navigation_top_widgets/lower_navigation_widget.dart';
import 'navigation_top_widgets/upper_navigation_widget.dart';

class NavigationTopWidget extends StatelessWidget {
  final WayPoint currentWayPoint;
  final double currentWayPointDistance;
  final WayPoint nextWayPoint;

  const NavigationTopWidget(
      {Key key,
      @required this.currentWayPoint,
      @required this.nextWayPoint,
      @required this.currentWayPointDistance})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: UpperNavigationWidget(
                currentWayPoint: currentWayPoint,
                nextWayPoint: nextWayPoint,
                currentWayPointDistance: currentWayPointDistance,
                locationHelper: getIt<DistanceHelper>(),
                turnSymbolHelper: getIt<TourConversionHelper>(),
              ),
            ),
            Flexible(
              child: LowerNavigationWidget(
                nextWayPoint: nextWayPoint,
                turnSymbolHelper: getIt<TourConversionHelper>(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
