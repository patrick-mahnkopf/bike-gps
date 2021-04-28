import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/presentation/widgets/navigation_widgets/navigation_bottom_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/navigation/navigation_bloc.dart';
import '../widgets/navigation_widgets/navigation_top_widget.dart';

/// The active view during navigation.
class NavigationView extends StatelessWidget {
  const NavigationView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          BlocBuilder<NavigationBloc, NavigationState>(
            builder: (context, state) {
              /// Rebuilds the navigation widgets at the top when the
              /// navigation data for the tour changed.
              if (state is NavigationLoadSuccess) {
                return NavigationTopWidget(
                  currentWayPoint: state.currentWayPoint,
                  nextWayPoint: state.nextWayPoint,
                  currentWayPointDistance: state.currentWayPointDistance,
                );

                /// Rebuilds the navigation widgets at the top when the
                /// navigation data to the tour changed.
              } else if (state is NavigationToTourLoadSuccess) {
                return NavigationTopWidget(
                  currentWayPoint: state.currentWayPoint,
                  nextWayPoint: state.nextWayPoint,
                  currentWayPointDistance: state.currentWayPointDistance,
                );
              } else if (state is NavigationLoading) {
                return const LoadingIndicator();
              } else {
                return Container();
              }
            },
          ),
          BlocBuilder<NavigationBloc, NavigationState>(
            builder: (context, state) {
              /// Rebuilds the navigation widgets at the bottom when the
              /// navigation data for the tour changed.
              if (state is NavigationLoadSuccess) {
                return NavigationBottomWidget(
                  distanceToTourEnd: state.distanceToTourEnd,
                );

                /// Rebuilds the navigation widgets at the bottom when the
                /// navigation data to the tour changed.
              } else if (state is NavigationToTourLoadSuccess) {
                return NavigationBottomWidget(
                  distanceToTourEnd: state.distanceToTourEnd,
                );
              } else if (state is NavigationLoading) {
                return const LoadingIndicator();
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
