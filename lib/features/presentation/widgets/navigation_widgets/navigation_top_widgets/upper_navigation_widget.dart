import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../domain/entities/tour/entities.dart';

class UpperNavigationWidget extends StatelessWidget {
  final WayPoint currentWayPoint;
  final double currentWayPointDistance;
  final DistanceHelper locationHelper;
  final WayPoint nextWayPoint;
  final TurnSymbolHelper turnSymbolHelper;

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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                turnSymbolHelper.getTurnSymbolFromId(
                    iconId: currentWayPoint.turnSymboldId, color: Colors.white),
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      currentWayPoint.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24),
                    ),
                    Text(
                      currentWayPoint.location,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      currentWayPoint.direction,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
