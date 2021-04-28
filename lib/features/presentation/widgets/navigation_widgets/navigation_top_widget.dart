import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/core/helpers/tour_conversion_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../injection_container.dart';
import '../../../domain/entities/tour/entities.dart';
import 'navigation_top_widgets/lower_navigation_widget.dart';
import 'navigation_top_widgets/upper_navigation_widget.dart';

/// Shows navigation information for the current turn and next turn.
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
    /// Only builds if navigation data is available.
    if (_navigationDataAvailable()) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                /// Shows navigation information for the current turn.
                child: UpperNavigationWidget(
                  currentWayPoint: currentWayPoint,
                  nextWayPoint: nextWayPoint,
                  currentWayPointDistance: currentWayPointDistance,
                  locationHelper: getIt<DistanceHelper>(),
                  turnSymbolHelper: getIt<TourConversionHelper>(),
                ),
              ),
              Flexible(
                /// Shows navigation information for the next turn.
                child: LowerNavigationWidget(
                  nextWayPoint: nextWayPoint,
                  turnSymbolHelper: getIt<TourConversionHelper>(),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  /// Checks if navigation data is available.
  ///
  /// The current waypoint has to exist and needs at least one of the following:
  /// direction information or a turn arrow.
  bool _navigationDataAvailable() {
    if (currentWayPoint != null) {
      final bool hasDirection =
          currentWayPoint.direction != null && currentWayPoint.direction != '';
      final bool hasTurnSymbolId = currentWayPoint.turnSymboldId != null &&
          currentWayPoint.turnSymboldId != '';

      if (hasDirection || hasTurnSymbolId) {
        return true;
      }
    }
    return false;
  }
}
