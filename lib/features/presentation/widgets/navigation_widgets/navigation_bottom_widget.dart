import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

import '../../../../injection_container.dart';
import '../../blocs/map/map_bloc.dart';

/// Shows a bottom sheet used during navigation.
class NavigationBottomWidget extends StatelessWidget {
  final double distanceToTourStart;
  final double distanceToTourEnd;
  double get bottomSheetGrabSectionHeight => 78;

  const NavigationBottomWidget(
      {Key key, @required this.distanceToTourEnd, this.distanceToTourStart})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        /// Position the bottom sheet in the bottom.
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomSheetGrabSectionHeight),
            child: RecenterMapWidget(
              constantsHelper: getIt(),
            ),
          ),
        ),

        /// The actuall bottom sheet.
        BottomSheetWidget(
          grabSectionHeight: bottomSheetGrabSectionHeight,
          topSnapPosition: 0.85,
          grabSectionContent: GrabSectionContent(
            distanceHelper: getIt(),
            distanceToTourEnd: distanceToTourEnd,
          ),
        )
      ],
    );
  }
}

/// The bottom sheet's content.
class GrabSectionContent extends StatelessWidget {
  final DistanceHelper distanceHelper;
  final double distanceToTourEnd;
  final double distanceToTourStart;

  const GrabSectionContent(
      {Key key,
      this.distanceHelper,
      this.distanceToTourEnd,
      this.distanceToTourStart = 0})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),

            /// The distance left until the end of the tour.
            child: Text(
              _getTourDistanceText(),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Align(
              alignment: Alignment.centerRight,

              /// A button to stop the navigation.
              child: ElevatedButton(
                onPressed: () => stopNavigation(context),
                style: ElevatedButton.styleFrom(
                  primary: Colors.red,
                  onPrimary: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(64),
                  ),
                ),
                child: const Text("Exit"),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Gets the remaining distance of the tour in a string representation.
  ///
  /// Returns the distance to the tour followed by the total remaining distance
  /// to the tour end, if the user is not on the tour. Otherwise returns only
  /// the remaining distance to the tour end.
  String _getTourDistanceText() {
    final String distanceToTour =
        distanceHelper.distanceToString(distanceToTourStart);
    final String totalDistance = distanceHelper
        .distanceToString(distanceToTourStart + distanceToTourEnd);
    if (distanceToTourStart != 0) {
      return "$distanceToTour (total: $totalDistance)";
    } else {
      return totalDistance;
    }
  }

  /// Stops the navigation.
  ///
  /// Switches the map to the tour selection view. Moves the map camera to the
  /// currently active tour bounds. Clears the path to the tour if it exists.
  /// Disables the map's camera tracking.
  void stopNavigation(BuildContext context) {
    final TourState tourState = BlocProvider.of<TourBloc>(context).state;
    final MapboxBloc mapboxBloc = BlocProvider.of<MapboxBloc>(context);
    final MapboxState mapboxState = mapboxBloc.state;

    BlocProvider.of<MapBloc>(context).add(TourSelectionViewActivated());
    if (mapboxState is MapboxLoadSuccess && tourState is TourLoadSuccess) {
      mapboxState.controller.animateCameraToTourBounds(
          tour: tourState.tour, alternativeTours: tourState.alternativeTours);
      mapboxState.controller.clearPathToTour();
      mapboxBloc.add(MapboxLoaded(
          mapboxController: mapboxState.controller,
          myLocationTrackingMode: MyLocationTrackingMode.None));
    }
  }
}
