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
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomSheetGrabSectionHeight),
            child: RecenterMapWidget(
              constantsHelper: getIt(),
            ),
          ),
        ),
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
            child: Text(
              _getTourDistanceText(),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Align(
              alignment: Alignment.centerRight,
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

  void stopNavigation(BuildContext context) {
    BlocProvider.of<MapBloc>(context).add(TourSelectionViewActivated());
    final TourState tourState = BlocProvider.of<TourBloc>(context).state;
    final MapboxBloc mapboxBloc = BlocProvider.of<MapboxBloc>(context);
    final MapboxState mapboxState = mapboxBloc.state;
    if (mapboxState is MapboxLoadSuccess && tourState is TourLoadSuccess) {
      mapboxState.controller.animateCameraToTourBounds(
          tour: tourState.tour, alternativeTours: tourState.alternativeTours);
      mapboxBloc.add(MapboxLoaded(
          mapboxController: mapboxState.controller
              .copyWith(myLocationTrackingMode: MyLocationTrackingMode.None)));
    }
  }
}
