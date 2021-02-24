import 'package:bike_gps/features/presentation/blocs/height_map/height_map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/search/search_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => getIt<MapboxBloc>()
              ..add(MapboxInitialized(mapboxController: getIt())),
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
                    mapboxController: getIt<MapboxController>(),
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
                  if (searchState is QueryLoadSuccess) {
                    searchBloc.add(SearchBarDismissed(
                        query: searchState.query,
                        searchResults: searchState.searchResults));
                  }
                  final MapboxBloc mapboxBloc =
                      BlocProvider.of<MapboxBloc>(context);
                  final MapboxState mapboxState = mapboxBloc.state;
                  if (mapboxState is MapboxLoadSuccess &&
                      mapboxState.controller != null) {
                    mapboxState.controller.mapboxMapController
                        .updateMyLocationTrackingMode(
                            MyLocationTrackingMode.TrackingCompass);
                    mapboxBloc.add(MapboxLoaded(
                        mapboxController: mapboxState.controller.copyWith(
                            myLocationTrackingMode:
                                MyLocationTrackingMode.TrackingCompass)));
                  }
                  final TourState tourState =
                      BlocProvider.of<TourBloc>(context).state;
                  if (tourState is TourLoadSuccess) {
                    BlocProvider.of<NavigationBloc>(context)
                        .add(NavigationLoaded(
                      tour: tourState.tour,
                    ));
                    final MapboxBloc mapboxBloc =
                        BlocProvider.of<MapboxBloc>(context);
                    final MapboxState mapboxState = mapboxBloc.state;
                    if (mapboxState is MapboxLoadSuccess) {
                      mapboxBloc.add(MapboxLoaded(
                          mapboxController: mapboxState.controller,
                          cameraUpdate: CameraUpdate.zoomTo(14)));
                    }
                  }
                  return const NavigationView();
                } else {
                  final SearchBloc searchBloc =
                      BlocProvider.of<SearchBloc>(context);
                  final SearchState searchState = searchBloc.state;
                  if (searchState is SearchBarInactive) {
                    searchBloc.add(SearchBarRecovered(
                        previousQuery: searchState.previousQuery,
                        previousSearchResults:
                            searchState.previousSearchResults));
                  }
                  final NavigationBloc navigationBloc =
                      BlocProvider.of<NavigationBloc>(context);
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
