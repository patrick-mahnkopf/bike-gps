import 'dart:developer';

import 'package:bike_gps/features/presentation/blocs/map/map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/navigation/navigation_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/controllers/controllers.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../injection_container.dart';
import '../widgets/mapbox_widget.dart';
import 'screens.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              getIt<MapboxBloc>()..add(MapboxLoaded(mapboxController: getIt())),
        ),
        BlocProvider(
          create: (_) => getIt<TourBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<NavigationBloc>(),
        ),
      ],
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: false,
            body: BlocBuilder<MapboxBloc, MapboxState>(
              builder: (context, state) {
                if (state is MapboxLoadSuccess) {
                  return MapboxWidget(
                    mapboxController: getIt<MapboxController>(),
                  );
                } else {
                  return const LoadingIndicator();
                }
              },
            ),
          ),
          BlocBuilder<MapBloc, MapState>(
            builder: (context, state) {
              if (state is NavigationViewActive) {
                log('State is NavigationView', name: 'MapScreen');
                return const NavigationView();
              } else {
                log('State is TourSelectionView', name: 'MapScreen');
                return const TourSelectionView();
              }
            },
          ),
        ],
      ),
    );
  }
}
