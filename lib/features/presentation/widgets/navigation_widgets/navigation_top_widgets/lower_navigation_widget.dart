import 'package:bike_gps/core/helpers/tour_conversion_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../domain/entities/tour/entities.dart';

/// Shows the turn arrow for the next waypoint.
class LowerNavigationWidget extends StatelessWidget {
  final WayPoint nextWayPoint;
  final TourConversionHelper turnSymbolHelper;

  const LowerNavigationWidget(
      {Key key, @required this.nextWayPoint, @required this.turnSymbolHelper})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (nextWayPoint != null) {
      /// The Container housing the widgets.
      return Container(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        decoration: BoxDecoration(
          color: Colors.green.shade800,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
            )
          ],
          borderRadius: const BorderRadius.only(
            bottomRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Then",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),

              /// The turn arrow.
              turnSymbolHelper.getTurnSymbolFromId(
                  iconId: nextWayPoint.turnSymboldId),
            ],
          ),
        ),
      );
    } else {
      return Container();
    }
  }
}
