import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/core/helpers/tour_conversion_helper.dart';
import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/presentation/blocs/height_map/height_map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/map/map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:bike_gps/injection_container.dart';
import 'package:charts_flutter_cf/charts_flutter_cf.dart' hide TextStyle;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/tour/entities.dart';

/// The bottom sheet shown during tour selection if there is an active tour.
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
        distanceHelper: getIt(),
      ),
      sheetContent: const SheetContent(),
    );
  }
}

/// Displays information about the currently active tour and holds the road
/// book and navigation start buttons.
///
/// Shows the tour length and total ascent and descent. The road book button
/// expands the bottom sheet to reveal further content. The start button starts
/// the navigation using the currently active tour.
class GrabSectionContent extends StatelessWidget {
  final DistanceHelper distanceHelper;

  const GrabSectionContent({
    Key key,
    @required this.distanceHelper,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TourBloc, TourState>(builder: (context, state) {
      if (state is TourLoadSuccess) {
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

                    /// The total tour length.
                    child: Text(
                      distanceHelper.distanceToString(state.tour.tourLength),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),

                  /// The ascent icon.
                  const Icon(
                    Icons.arrow_upward,
                    color: Colors.green,
                    size: 16,
                  ),

                  /// The tour's total ascent.
                  Text(
                    distanceHelper.distanceToString(state.tour.ascent),
                  ),

                  /// The descent icon.
                  const Icon(
                    Icons.arrow_downward,
                    color: Colors.red,
                    size: 16,
                  ),

                  /// The tour's total descent.
                  Text(
                    distanceHelper.distanceToString(state.tour.descent),
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
                    /// The road book button.
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.list),
                      label: const Text("Road book"),

                      /// Fully expands the bottom sheet when pressed.
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

                      /// The button to start the navigation.
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.navigation),
                        label: const Text("Start"),

                        /// Starts the navigation when pressed.
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
      } else if (state is TourLoading) {
        return const LoadingIndicator();
      } else {
        return Container();
      }
    });
  }
}

/// The content of the bottom sheet when expanded.
///
/// Includes the height map that always stays on top and the road book which is
/// a scrollable list of the tour's waypoints.
class SheetContent extends StatelessWidget {
  const SheetContent({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TourBloc, TourState>(
      builder: (context, tourBlocState) {
        if (tourBlocState is TourLoadSuccess) {
          /// Loads the height map for the currently active tour.
          BlocProvider.of<HeightMapBloc>(context)
              .add(HeightMapLoaded(tour: tourBlocState.tour));

          /// Due to the height map, there is always at least one item to show
          /// in this list.
          final int _itemCount = tourBlocState.tour.wayPoints.isEmpty
              ? 1
              : tourBlocState.tour.wayPoints.length;
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BlocBuilder<HeightMapBloc, HeightMapState>(
                  builder: (context, heightMapState) {
                    /// Shows the height map for the currently active tour.
                    if (heightMapState is HeightMapLoadSuccess &&
                        heightMapState.tour == tourBlocState.tour) {
                      return HeightMap(state: heightMapState);
                    } else if (heightMapState is HeightMapLoading) {
                      return const LoadingIndicator();
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

                        /// Shows the road book for the currently active tour.
                        child: RoadBook(
                          tour: tourBlocState.tour,
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
        } else if (tourBlocState is TourLoading) {
          return const LoadingIndicator();
        } else {
          return Container();
        }
      },
    );
  }
}

/// The height map showing the height profile of the currently active tour.
class HeightMap extends StatelessWidget {
  final HeightMapLoadSuccess state;

  const HeightMap({Key key, @required this.state}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      width: MediaQuery.of(context).size.width,
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

/// The road book displaying a scrollable list of the [tour]'s waypoints.
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
    /// Displays an error message if there are no waypoitns in the active tour.
    if (tour.wayPoints.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.error),
        title: Text('This tour file does not include road book information'),
      );
    } else {
      final WayPoint currentWayPoint = tour.wayPoints[index];

      /// Displays an entry for the current waypoint.
      return ListTile(
        leading: tourConversionHelper.getTurnSymbolFromId(
          iconId: currentWayPoint.turnSymboldId,
          color: Colors.black,
        ),
        title: _getTileTitle(currentWayPoint),
        subtitle: _getTileSubtitle(currentWayPoint),
      );
    }
  }

  /// Gets a title for the [currentWayPoint].
  ///
  /// Returns either the waypoint's name or the location depending on which of
  /// those exists. Prefers the name over the location.
  Widget _getTileTitle(WayPoint currentWayPoint) {
    /// Returns the waypoint's name if it exists and isn't empty.
    if (currentWayPoint.name != null && currentWayPoint.name != '') {
      return Text(currentWayPoint.name);

      /// Returns the waypoint's location if it exists and isn't empty.
    } else if (currentWayPoint.location != null &&
        currentWayPoint.location != '') {
      return Text(currentWayPoint.location);
    }

    /// Returns an empty Container if no other information exists.
    return Container();
  }

  /// Gets a subtitle for the [currentWayPoint].
  ///
  /// Returns either the waypoint's name or the location depending on which of
  /// those exists. Prefers the name over the location.
  Widget _getTileSubtitle(WayPoint currentWayPoint) {
    String subtitleContent = '';
    final Widget tileTitle = _getTileTitle(currentWayPoint);
    String tileTitleText = '';

    /// Checks if the main title includes text information.
    if (tileTitle is Text) {
      tileTitleText = tileTitle.data;
    }

    /// Displays the currentWayPoint's location if it exists and wasn't
    /// already used for the main title.
    if (currentWayPoint.location != null &&
        currentWayPoint.location != '' &&
        tileTitleText != currentWayPoint.location) {
      subtitleContent += "${currentWayPoint.location}\n\n";
    }

    /// Adds the currentWayPoint's direction if it exists.
    if (currentWayPoint.direction != null && currentWayPoint.direction != '') {
      subtitleContent += currentWayPoint.direction;
    }

    /// Returns the subtitle if it isn't empty.
    if (subtitleContent != '') {
      return Text(subtitleContent);

      /// Returns an empty Container if no other information exists.
    } else {
      return Container();
    }
  }
}
