import 'package:bike_gps/features/presentation/widgets/navigation_widgets/navigation_bottom_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/navigation/navigation_bloc.dart';
import '../widgets/navigation_widgets/navigation_top_widget.dart';

class NavigationView extends StatelessWidget {
  const NavigationView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
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
                return NavigationBottomWidget(
                  distanceToTourEnd: state.distanceToTourEnd,
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
