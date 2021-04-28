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

/// The app's main screen containing the map and the currently active view.
///
/// Initially in the tour selection view. Can change between it and the
/// navigation view.
class MapScreen extends StatelessWidget {
  const MapScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: MultiBlocProvider(
        /// Provides the BLoCs to all children in the widget tree.
        providers: [
          /// Provides and initializes the MapboxBLoC.
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
            /// Handles the Mapbox map.
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
                /// Rebuilds when the navigation view was activated.
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

                  /// Dismisses the search bar and saves the current contents.
                  if (searchState is QueryLoadSuccess) {
                    searchBloc.add(SearchBarDismissed(
                        query: searchState.query,
                        searchResults: searchState.searchResults));
                  }

                  /// Moves the map to the user location and starts the
                  /// navigation.
                  if (tourState is TourLoadSuccess) {
                    if (mapboxState is MapboxLoadSuccess &&
                        mapboxState.controller != null) {
                      mapboxState.controller.clearAlternativeTours();

                      /// Sets the tracking mode to tracking compass for the
                      /// navigation.
                      mapboxBloc.add(
                        MapboxLoaded(
                          mapboxController: mapboxState.controller,
                          myLocationTrackingMode:
                              MyLocationTrackingMode.TrackingCompass,
                          cameraUpdate: CameraUpdate.zoomTo(16),
                        ),
                      );

                      /// Starts the navigation.
                      navigationBloc.add(NavigationLoaded(
                        tour: tourState.tour,
                        mapboxController: mapboxState.controller,
                      ));
                    }
                  }

                  /// Updates the navigation on user location changes.
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

                      /// Recalculates current navigation data on the tour
                      /// using the new user location.
                      if (navigationState is NavigationLoadSuccess) {
                        /// Checks if the location actually changed.
                        if (currentLatLng != navigationState.userLocation) {
                          navigationBloc.add(NavigationLoaded(
                              userLocation: currentLatLng,
                              tour: tourState.tour,
                              mapboxController: mapboxState.controller));
                        }

                        /// Recalculates current navigation data to the tour
                        /// using the new user location.
                      } else if (navigationState
                          is NavigationToTourLoadSuccess) {
                        /// Checks if the location actually changed.
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

                  /// Rebuilds when the tour selection view was activated.
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

                  /// Recovers the search bar with its previous contents.
                  if (searchState is SearchBarInactive) {
                    searchBloc.add(SearchBarRecovered(
                        previousQuery: searchState.previousQuery,
                        previousSearchResults:
                            searchState.previousSearchResults));
                  }

                  /// Stops the navigation.
                  if (navigationBloc.state is NavigationLoadSuccess ||
                      navigationBloc.state is NavigationToTourLoadSuccess) {
                    navigationBloc.add(NavigationStopped());
                  }

                  /// Redraws alternative tours if they exist.
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
