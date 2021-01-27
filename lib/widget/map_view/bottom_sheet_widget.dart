import 'dart:math';

import 'package:bike_gps/route_parser/models/route.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/widgets.dart' hide Route;
import 'package:latlong/latlong.dart';
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
  final GlobalKey<SheetContentState> _sheetContentStateKey = GlobalKey();

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
      grabbingHeight: MediaQuery.of(context).padding.bottom + 117,
      grabbing: GrabSectionWidget(
          key: _grabSectionStateKey,
          activeRoute: _activeRoute,
          similarRoutes: _similarRoutes,
          controller: _controller),
      sheetBelow: SnappingSheetContent(
          child: SheetContentWidget(
        key: _sheetContentStateKey,
        activeRoute: _activeRoute,
        similarRoutes: _similarRoutes,
      )),
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
    SheetContentState sheetContentState = _sheetContentStateKey.currentState;

    grabSectionState.setState(() {
      grabSectionState._activeRoute = activeRoute;
      grabSectionState._similarRoutes = similarRoutes;
    });
    sheetContentState.setState(() {
      sheetContentState._activeRoute = activeRoute;
      sheetContentState._similarRoutes = similarRoutes;
    });
  }
}

class GrabSectionWidget extends StatefulWidget {
  final Route activeRoute;
  final List<Route> similarRoutes;
  final SnappingSheetController controller;

  GrabSectionWidget({
    Key key,
    this.activeRoute,
    this.similarRoutes,
    this.controller,
  }) : super(key: key);

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
            topLeft: Radius.circular(8.0),
            topRight: Radius.circular(8.0),
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
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      "${(_activeRoute.length.toDouble() / 1000).toStringAsFixed(1)} km",
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.green,
                    size: 16,
                  ),
                  Text("${_activeRoute.ascent} m"),
                  Icon(
                    Icons.arrow_downward,
                    color: Colors.red,
                    size: 16,
                  ),
                  Text("${_activeRoute.descent} m"),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.list),
                      label: Text("Road book"),
                      onPressed: _toggleBetweenSnapPoints,
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        onPrimary: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.navigation),
                        label: Text("Start"),
                        onPressed: _startNavigation,
                        style: ElevatedButton.styleFrom(
                          primary: Colors.blue,
                          onPrimary: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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

  _startNavigation() {}
}

class SheetContentWidget extends StatefulWidget {
  final Route activeRoute;
  final List<Route> similarRoutes;

  SheetContentWidget({
    Key key,
    this.activeRoute,
    this.similarRoutes,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() =>
      SheetContentState(activeRoute, similarRoutes);
}

class SheetContentState extends State<SheetContentWidget> {
  Route _activeRoute;
  List<Route> _similarRoutes;
  static const MIN_ITEM_COUNT = 2;

  int get _itemCount => _activeRoute.roadBook.wayPoints.length == 0
      ? MIN_ITEM_COUNT
      : _activeRoute.roadBook.wayPoints.length - 1 + MIN_ITEM_COUNT;

  bool get _roadBookEmpty => _itemCount == MIN_ITEM_COUNT;

  SheetContentState(this._activeRoute, this._similarRoutes);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: EdgeInsets.all(20.0),
        itemCount: _itemCount,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.grey[300], width: 1.0))),
            child: index == 0 ? _getHeightMap() : _getRoadBook(index - 1),
          );
        },
      ),
    );
  }

  _getHeightMap() {
    // TODO draw similar routes as well
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        width: double.infinity,
        height: 200,
        child: charts.LineChart(
          _createChartData(),
          defaultRenderer: charts.LineRendererConfig(
            includeArea: true,
            stacked: true,
          ),
          defaultInteractions: false,
          primaryMeasureAxis: charts.NumericAxisSpec(
            tickProviderSpec: charts.StaticNumericTickProviderSpec(
              _getPrimaryMeasureAxisTicks(_activeRoute),
            ),
          ),
          domainAxis: charts.NumericAxisSpec(
              tickProviderSpec: charts.StaticNumericTickProviderSpec(
            _getDomainAxisTicks(_activeRoute),
          )),
        ),
      ),
    );
  }

  List<charts.TickSpec<num>> _getPrimaryMeasureAxisTicks(Route route) {
    List<charts.TickSpec<num>> tickSpecs = [];
    double tickStep = route.highestPoint / 5;
    for (double tickValue = 0;
        tickValue < route.highestPoint + tickStep;
        tickValue += tickStep) {
      double roundValue = round(tickStep / 10, decimals: 0) * 10;
      double labelValue =
          round(tickValue / roundValue, decimals: 0) * roundValue;
      tickSpecs.add(charts.TickSpec(labelValue, label: '$labelValue m'));
    }
    return tickSpecs;
  }

  List<charts.TickSpec<num>> _getDomainAxisTicks(Route route) {
    List<charts.TickSpec<num>> tickSpecs = [];
    double tickStep = route.length / 5;
    for (double tickValue = 0;
        tickValue < route.length + tickStep;
        tickValue += tickStep) {
      tickSpecs
          .add(charts.TickSpec(tickValue, label: '${tickValue ~/ 1000} km'));
    }
    return tickSpecs;
  }

  List<charts.Series<RoutePoint, int>> _createChartData() {
    return [
      new charts.Series<RoutePoint, int>(
        id: 'Active Route',
        colorFn: (RoutePoint routePoint, _) =>
            _getSurfaceColor(routePoint.surface),
        domainFn: (RoutePoint routePoint, _) =>
            routePoint.distanceFromStart.toInt(),
        measureFn: (RoutePoint routePoint, _) => routePoint.ele.toInt(),
        data: _activeRoute.roadBook.routePoints,
      )
    ];
  }

  charts.Color _getSurfaceColor(String surface) {
    switch (surface) {
      case 'A':
        return charts.MaterialPalette.blue.shadeDefault;
        break;
      case 'R':
        return charts.MaterialPalette.purple.shadeDefault;
        break;
      case 'S':
        return charts.MaterialPalette.green.shadeDefault;
        break;
      case 'W':
        return charts.MaterialPalette.deepOrange.shadeDefault;
        break;
      case 'P':
        return charts.MaterialPalette.red.shadeDefault;
        break;
      case 'T':
        return charts.MaterialPalette.black;
        break;
      case 'X':
        return charts.MaterialPalette.purple.makeShades(2).last;
        break;
      default:
        return charts.MaterialPalette.blue.shadeDefault;
        break;
    }
  }

  _getRoadBook(int index) {
    if (_roadBookEmpty) {
      return ListTile(
        leading: Icon(Icons.error),
        title: Text("This route file does not include road book information."),
      );
    } else {
      RoutePoint _routePoint = _activeRoute.roadBook.wayPoints[index];
      return ListTile(
        leading: Icon(Icons.info),
        title: Text(_routePoint.name ?? ''),
        subtitle: Text(
          "${_routePoint.location ?? ''}\n\n"
          "${_routePoint.direction ?? ''}\n",
        ),
      );
    }
  }
}
