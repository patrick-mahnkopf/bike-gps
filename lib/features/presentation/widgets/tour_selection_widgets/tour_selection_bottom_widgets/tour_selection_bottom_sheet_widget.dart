import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/core/helpers/tour_conversion_helper.dart';
import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/presentation/blocs/height_map/height_map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/map/map_bloc.dart';
import 'package:bike_gps/injection_container.dart';
import 'package:charts_flutter_cf/charts_flutter_cf.dart' hide TextStyle;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/tour/entities.dart';

class TourSelectionBottomSheetWidget extends StatelessWidget {
  final Tour tour;
  final double grabSectionHeight;

  const TourSelectionBottomSheetWidget(
      {Key key, this.tour, this.grabSectionHeight})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      grabSectionHeight: grabSectionHeight,
      grabSectionContent: GrabSectionContent(
        tour: tour,
        distanceHelper: getIt(),
      ),
      sheetContent: SheetContent(
        tour: tour,
      ),
    );
  }
}

class GrabSectionContent extends StatelessWidget {
  final Tour tour;
  final DistanceHelper distanceHelper;

  const GrabSectionContent({
    Key key,
    @required this.tour,
    @required this.distanceHelper,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  distanceHelper.distanceToString(tour.tourLength),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const Icon(
                Icons.arrow_upward,
                color: Colors.green,
                size: 16,
              ),
              Text(
                distanceHelper.distanceToString(tour.ascent),
              ),
              const Icon(
                Icons.arrow_downward,
                color: Colors.red,
                size: 16,
              ),
              Text(
                distanceHelper.distanceToString(tour.descent),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.list),
                  label: const Text("Road book"),
                  onPressed: () => Provider.of<BottomSheetSnapController>(
                          context,
                          listen: false)
                      .toggleBetweenSnapPositions(),
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
                    icon: const Icon(Icons.navigation),
                    label: const Text("Start"),
                    onPressed: () => BlocProvider.of<MapBloc>(context)
                        .add(NavigationViewActivated()),
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
        )
      ],
    );
  }
}

class SheetContent extends StatelessWidget {
  final Tour tour;

  const SheetContent({Key key, @required this.tour}) : super(key: key);

  int get _itemCount => tour.wayPoints.isEmpty ? 1 : tour.wayPoints.length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<HeightMapBloc, HeightMapState>(
            builder: (context, state) {
              if (state is HeightMapLoading) {
                return const LoadingIndicator();
              } else if (state is HeightMapLoadSuccess) {
                return HeightMap(state: state);
              } else {
                // TODO replace with error widget
                return const Text('Could not load height map');
              }
            },
          ),
          DividerLine(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: _itemCount,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey[300],
                      ),
                    ),
                  ),
                  child: RoadBook(
                    tour: tour,
                    index: index,
                    tourConversionHelper: getIt(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HeightMap extends StatelessWidget {
  final HeightMapLoadSuccess state;

  const HeightMap({Key key, @required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LineChart(
        state.chartData,
        defaultRenderer: LineRendererConfig(
          includeArea: true,
          stacked: true,
        ),
        defaultInteractions: false,
        primaryMeasureAxis: NumericAxisSpec(
          tickProviderSpec:
              StaticNumericTickProviderSpec(state.primaryMeasureAxisTickSpecs),
        ),
        domainAxis: NumericAxisSpec(
          tickProviderSpec:
              StaticNumericTickProviderSpec(state.domainAxisTickSpecs),
        ),
      ),
    );
  }
}

class RoadBook extends StatelessWidget {
  final Tour tour;
  final int index;
  final TourConversionHelper tourConversionHelper;

  const RoadBook(
      {Key key,
      @required this.tour,
      @required this.index,
      @required this.tourConversionHelper})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tour.wayPoints.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.error),
        title: Text('This route file does not include road book information'),
      );
    } else {
      final WayPoint currentWayPoint = tour.wayPoints[index];
      return ListTile(
        leading: tourConversionHelper.getTurnSymbolFromId(
          iconId: currentWayPoint.turnSymboldId,
          color: Colors.black,
        ),
        title: Text(currentWayPoint.name ?? ''),
        subtitle: _getTileSubtitle(currentWayPoint),
      );
    }
  }

  Widget _getTileSubtitle(WayPoint currentWayPoint) {
    String subtitleContent = '';
    if (currentWayPoint.location != null && currentWayPoint.location != '') {
      subtitleContent += "${currentWayPoint.location}\n\n";
    }
    if (currentWayPoint.direction != null && currentWayPoint.direction != '') {
      subtitleContent += currentWayPoint.direction;
    }
    if (subtitleContent != '') {
      return Text(subtitleContent);
    } else {
      return Container();
    }
  }
}
