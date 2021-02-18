import 'package:bike_gps/features/presentation/blocs/navigation/navigation_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart';

import '../../../core/helpers/helpers.dart';
import '../../../injection_container.dart';
import '../widgets/navigation_widgets/navigation_bottom_sheet_widget.dart';
import '../widgets/navigation_widgets/navigation_top_widget.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    getIt<Location>().onLocationChanged.listen((LocationData currentLocation) {
      final TourState tourState = getIt<TourBloc>().state;
      if (tourState is TourLoadSuccess) {
        getIt<NavigationBloc>().add(NavigationLoaded(
            userLocation: currentLocation, tour: tourState.tour));
      }
    });

    return SafeArea(
      child: Column(
        children: [
          BlocBuilder<NavigationBloc, NavigationState>(
            builder: (context, state) {
              if (state is NavigationLoadSuccess) {
                return NavigationTopWidget(
                  currentWayPoint: state.currentWayPoint,
                  nextWayPoint: state.nextWayPoint,
                  currentWayPointDistance: state.currentWayPointDistance,
                );
              } else {
                return Container();
              }
            },
          ),
          BlocBuilder<NavigationBloc, NavigationState>(
            builder: (context, state) {
              if (state is NavigationLoadSuccess) {
                return NavigationBottomSheetWidget(
                  distanceToTourEnd: state.distanceToTourEnd,
                  locationHelper: getIt<DistanceHelper>(),
                );
              } else {
                return Container();
              }
            },
          ),
        ],
      ),
    );
  }
}
