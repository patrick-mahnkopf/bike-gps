import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../../core/helpers/helpers.dart';
import '../../../../domain/entities/tour/entities.dart';

class LowerNavigationWidget extends StatelessWidget {
  final WayPoint nextWayPoint;
  final TurnSymbolHelper turnSymbolHelper;

  const LowerNavigationWidget(
      {Key key, @required this.nextWayPoint, @required this.turnSymbolHelper})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            turnSymbolHelper.getTurnSymbolFromId(
                iconId: nextWayPoint.turnSymboldId),
            Text(
              nextWayPoint.name,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
