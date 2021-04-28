import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/core/helpers/tour_conversion_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../../core/widgets/custom_widgets.dart';
import '../../../../domain/entities/tour/entities.dart';

/// Shows navigation information for the current turn.
class UpperNavigationWidget extends StatelessWidget {
  final WayPoint currentWayPoint;
  final double currentWayPointDistance;
  final DistanceHelper locationHelper;
  final WayPoint nextWayPoint;
  final TourConversionHelper turnSymbolHelper;

  const UpperNavigationWidget(
      {Key key,
      @required this.currentWayPoint,
      @required this.nextWayPoint,
      @required this.currentWayPointDistance,
      @required this.turnSymbolHelper,
      @required this.locationHelper})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    /// The Container housing the widgets.
    return Container(
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.green,
        boxShadow: [
          BoxShadow(
            blurRadius: 20.0,
            color: Colors.black.withOpacity(0.2),
          )
        ],
        borderRadius: const BorderRadius.only(
          bottomRight: Radius.circular(8),
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// The turn arrow.
                turnSymbolHelper.getTurnSymbolFromId(
                    iconId: currentWayPoint.turnSymboldId, color: Colors.white),

                /// The remaining distance to the current waypoint.
                Text(
                  locationHelper.distanceToString(currentWayPointDistance),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// A list of items describing the current waypoint.
                    ..._getCurrentWayPointWidgets(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gets a list of [CustomContainerTextWidget]s that describe the current
  /// waypoint.
  ///
  /// Includes the location and direction, only the location or only the
  /// direction if only one of them is available, or the waypoint's name if no
  /// other information exists.
  List<Widget> _getCurrentWayPointWidgets() {
    final List<Widget> widgets = [];

    /// Adds the location if it exists.
    if (currentWayPoint.location != null && currentWayPoint.location != '') {
      widgets.add(CustomContainerTextWidget(
        text: currentWayPoint.location,
      ));
    }

    /// Adds the direction if it exists.
    if (currentWayPoint.direction != null && currentWayPoint.direction != '') {
      widgets.add(CustomContainerTextWidget(
        text: currentWayPoint.direction,
      ));
    }

    /// Returns only the name if no other information exists.
    if (widgets.isEmpty &&
        currentWayPoint.name != null &&
        currentWayPoint.name != '') {
      widgets.add(CustomContainerTextWidget(
        text: currentWayPoint.name,
      ));
    }
    return widgets;
  }
}
