import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart';

import '../../../core/controllers/controllers.dart';
import '../../../core/widgets/custom_widgets.dart';
import '../../../injection_container.dart';
import '../blocs/map/map_bloc.dart';
import '../blocs/mapbox/mapbox_bloc.dart';
import '../blocs/navigation/navigation_bloc.dart';
import '../blocs/tour/tour_bloc.dart';
import '../widgets/mapbox_widget.dart';
import 'screens.dart';

class MapScreen extends StatelessWidget {
  MapScreen({Key key}) : super(key: key) {
    getIt<Location>().onLocationChanged.listen((LocationData currentLocation) {
      final TourState tourState = getIt<TourBloc>().state;
      final MapBloc mapBloc = getIt<MapBloc>();
      if (tourState is TourLoadSuccess &&
          mapBloc.state is NavigationViewActive) {
        getIt<NavigationBloc>().add(NavigationLoaded(
            userLocation: currentLocation, tour: tourState.tour));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => getIt<MapboxBloc>()
              ..add(MapboxLoaded(mapboxController: getIt())),
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
                  final MapboxState mapboxState = getIt<MapboxBloc>().state;
                  if (mapboxState is MapboxLoadSuccess &&
                      mapboxState.controller != null) {
                    mapboxState.controller.recenterMap();
                  }
                  final TourState tourState = getIt<TourBloc>().state;
                  if (tourState is TourLoadSuccess) {
                    getIt<NavigationBloc>()
                        .add(NavigationLoaded(tour: tourState.tour));
                  }
                  return const NavigationView();
                } else {
                  final NavigationBloc navigationBloc = getIt<NavigationBloc>();
                  if (navigationBloc.state is NavigationLoadSuccess) {
                    navigationBloc.add(NavigationStopped());
                  }
                  return const TourSelectionView();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
