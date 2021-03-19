import 'package:bike_gps/features/presentation/blocs/height_map/height_map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/search/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:location/location.dart';
import 'package:mapbox_gl/mapbox_gl.dart';

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
  const MapScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => getIt<MapboxBloc>()
              ..add(MapboxInitialized(
                  mapboxController: getIt(),
                  devicePixelRatio: devicePixelRatio)),
          ),
          BlocProvider(
            create: (_) => getIt<TourBloc>(),
          ),
          BlocProvider(
            create: (_) => getIt<NavigationBloc>(),
          ),
          BlocProvider(
            create: (_) => getIt<HeightMapBloc>(),
          ),
          BlocProvider(
            create: (_) => getIt<SearchBloc>(),
          ),
        ],
        child: Stack(
          children: [
            BlocBuilder<MapboxBloc, MapboxState>(
              builder: (context, state) {
                if (state is MapboxInitial || state is MapboxLoadSuccess) {
                  return MapboxWidget(
                    uninitializedMapboxController: getIt<MapboxController>(),
                  );
                } else {
                  return const LoadingIndicator();
                }
              },
            ),
            BlocBuilder<MapBloc, MapState>(
              builder: (context, state) {
                if (state is NavigationViewActive) {
                  final SearchBloc searchBloc =
                      BlocProvider.of<SearchBloc>(context);
                  final SearchState searchState = searchBloc.state;

                  final MapboxBloc mapboxBloc =
                      BlocProvider.of<MapboxBloc>(context);
                  final MapboxState mapboxState = mapboxBloc.state;

                  final TourState tourState =
                      BlocProvider.of<TourBloc>(context).state;

                  final MapState mapState =
                      BlocProvider.of<MapBloc>(context).state;

                  final NavigationBloc navigationBloc =
                      BlocProvider.of<NavigationBloc>(context);

                  if (searchState is QueryLoadSuccess) {
                    searchBloc.add(SearchBarDismissed(
                        query: searchState.query,
                        searchResults: searchState.searchResults));
                  }

                  if (tourState is TourLoadSuccess) {
                    if (mapboxState is MapboxLoadSuccess &&
                        mapboxState.controller != null) {
                      mapboxState.controller.clearAlternativeTours();
                      mapboxBloc.add(
                        MapboxLoaded(
                          mapboxController: mapboxState.controller,
                          myLocationTrackingMode:
                              MyLocationTrackingMode.TrackingCompass,
                          cameraUpdate: CameraUpdate.zoomTo(16),
                        ),
                      );
                      navigationBloc.add(NavigationLoaded(
                        tour: tourState.tour,
                        mapboxController: mapboxState.controller,
                      ));
                    }
                  }

                  getIt<Location>()
                      .onLocationChanged
                      .listen((LocationData currentLocation) {
                    if (tourState is TourLoadSuccess &&
                        mapState is NavigationViewActive &&
                        mapboxState is MapboxLoadSuccess) {
                      final NavigationState navigationState =
                          navigationBloc.state;
                      final LatLng currentLatLng = LatLng(
                          currentLocation.latitude, currentLocation.longitude);
                      if (navigationState is NavigationLoadSuccess) {
                        if (currentLatLng != navigationState.userLocation) {
                          navigationBloc.add(NavigationLoaded(
                              userLocation: currentLatLng,
                              tour: tourState.tour,
                              mapboxController: mapboxState.controller));
                        }
                      } else if (navigationState
                          is NavigationToTourLoadSuccess) {
                        if (currentLatLng != navigationState.userLocation) {
                          navigationBloc.add(NavigationLoaded(
                              userLocation: currentLatLng,
                              tour: tourState.tour,
                              mapboxController: mapboxState.controller));
                        }
                      }
                    }
                  });
                  return const NavigationView();
                } else {
                  final SearchBloc searchBloc =
                      BlocProvider.of<SearchBloc>(context);
                  final SearchState searchState = searchBloc.state;
                  final NavigationBloc navigationBloc =
                      BlocProvider.of<NavigationBloc>(context);
                  final TourState tourState =
                      BlocProvider.of<TourBloc>(context).state;
                  final MapboxState mapboxState =
                      BlocProvider.of<MapboxBloc>(context).state;

                  if (searchState is SearchBarInactive) {
                    searchBloc.add(SearchBarRecovered(
                        previousQuery: searchState.previousQuery,
                        previousSearchResults:
                            searchState.previousSearchResults));
                  }

                  if (navigationBloc.state is NavigationLoadSuccess ||
                      navigationBloc.state is NavigationToTourLoadSuccess) {
                    navigationBloc.add(NavigationStopped());
                  }

                  if (tourState is TourLoadSuccess &&
                      mapboxState is MapboxLoadSuccess) {
                    if (tourState.alternativeTours.isNotEmpty) {
                      mapboxState.controller
                          .drawAlternativeTours(tourState.alternativeTours);
                    }
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
