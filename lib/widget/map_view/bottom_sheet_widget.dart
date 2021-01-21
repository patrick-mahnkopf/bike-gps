import 'dart:math';

import 'package:flutter/material.dart' hide Route;
import 'package:flutter/widgets.dart' hide Route;
import 'package:route_parser/models/route.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

class BottomSheetWidget extends StatefulWidget {
  final Route activeRoute;
  final List<Route> similarRoutes;

  BottomSheetWidget({Key key, this.activeRoute, this.similarRoutes})
      : super(key: key);

  @override
  BottomSheetState createState() =>
      BottomSheetState(activeRoute, similarRoutes);
}

class BottomSheetState extends State<BottomSheetWidget>
    with SingleTickerProviderStateMixin {
  SnappingSheetController _controller = SnappingSheetController();
  Route _activeRoute;
  List<Route> _similarRoutes;
  final GlobalKey<GrabSectionState> _grabSectionStateKey = GlobalKey();

  BottomSheetState(this._activeRoute, this._similarRoutes);

  @override
  Widget build(BuildContext context) {
    return SnappingSheet(
      onSnapEnd: onSnapEnd,
      snappingSheetController: _controller,
      snapPositions: const [
        SnapPosition(
          positionFactor: 0,
          snappingCurve: Curves.elasticOut,
          snappingDuration: Duration(milliseconds: 750),
        ),
        SnapPosition(positionFactor: 0.6),
        SnapPosition(positionFactor: 1),
      ],
      grabbingHeight: MediaQuery.of(context).padding.bottom + 50,
      grabbing: GrabSectionWidget(
          _grabSectionStateKey, _activeRoute, _similarRoutes, _controller),
      sheetBelow: SnappingSheetContent(child: SheetContent()),
    );
  }

  onSnapEnd() {
    bool snapTop;
    GrabSectionState grabSectionState = _grabSectionStateKey.currentState;

    if (_controller.currentSnapPosition == _controller.snapPositions.last) {
      snapTop = true;
    } else {
      snapTop = false;
    }
    grabSectionState.setState(() {
      grabSectionState._snappingTop = snapTop;
    });
  }

  updateRoutes(Route activeRoute, List<Route> similarRoutes) {
    GrabSectionState grabSectionState = _grabSectionStateKey.currentState;

    grabSectionState.setState(() {
      grabSectionState._activeRoute = activeRoute;
      grabSectionState._similarRoutes = similarRoutes;
    });
  }
}

class GrabSectionWidget extends StatefulWidget {
  final Route activeRoute;
  final List<Route> similarRoutes;
  final SnappingSheetController controller;

  GrabSectionWidget(
    Key key,
    this.activeRoute,
    this.similarRoutes,
    this.controller,
  ) : super(key: key);

  @override
  GrabSectionState createState() =>
      GrabSectionState(activeRoute, similarRoutes, controller);
}

class GrabSectionState extends State<GrabSectionWidget> {
  final SnappingSheetController _controller;
  Route _activeRoute;
  List<Route> _similarRoutes;
  bool _snappingTop = false;

  GrabSectionState(this._activeRoute, this._similarRoutes, this._controller);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleBetweenSnapPoints,
      child: Container(
        padding: EdgeInsets.zero,
        margin: EdgeInsets.zero,
        alignment: Alignment.topCenter,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 20.0,
              color: Colors.black.withOpacity(0.2),
            )
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _snappingTop
                ? Stack(
                    children: [
                      Transform.rotate(
                        angle: pi / 8,
                        child: Container(
                          padding: EdgeInsets.zero,
                          width: 16,
                          height: 4,
                          margin: EdgeInsets.only(top: 8, left: 0, right: 8),
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0))),
                        ),
                      ),
                      Transform.rotate(
                        angle: -pi / 8,
                        child: Container(
                          padding: EdgeInsets.zero,
                          width: 16,
                          height: 4,
                          margin: EdgeInsets.only(top: 8, left: 8, right: 0),
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius:
                                  BorderRadius.all(Radius.circular(5.0))),
                        ),
                      ),
                    ],
                  )
                : Container(
                    width: 28,
                    height: 4,
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.all(Radius.circular(5.0))),
                  ),
            Container(
              margin: EdgeInsets.only(left: 20),
              alignment: Alignment.centerLeft,
              child: Text(_activeRoute.routeName),
            ),
            Container(
              height: 2.0,
              margin: EdgeInsets.only(left: 20, right: 20),
              color: Colors.grey[300],
            ),
          ],
        ),
      ),
    );
  }

  _toggleBetweenSnapPoints() {
    if (_controller.currentSnapPosition == _controller.snapPositions.first) {
      _controller.snapToPosition(_controller.snapPositions.last);
    } else {
      _controller.snapToPosition(_controller.snapPositions.first);
    }
    setState(() {});
  }
}

class SheetContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.all(20.0),
        itemCount: 50,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.grey[300], width: 1.0))),
            child: ListTile(
              leading: Icon(Icons.info),
              title: Text('List item $index'),
            ),
          );
        },
      ),
    );
  }
}
