import 'dart:developer';

import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/domain/entities/search/entities.dart';
import 'package:bike_gps/features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/search/search_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:material_floating_search_bar/material_floating_search_bar.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return SafeArea(
      child: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          final SearchBloc searchBloc = BlocProvider.of<SearchBloc>(context);
          final FloatingSearchBarController searchBarController =
              searchBloc.searchBarController;
          return FloatingSearchBar(
            automaticallyImplyBackButton: false,
            controller: searchBarController,
            clearQueryOnClose: false,
            iconColor: Colors.grey,
            transitionDuration: const Duration(milliseconds: 800),
            transitionCurve: Curves.easeInOutCubic,
            physics: const BouncingScrollPhysics(),
            axisAlignment: isPortrait ? 0.0 : -1.0,
            openAxisAlignment: 0.0,
            maxWidth: isPortrait ? 600 : 500,
            onSubmitted: (_) => _getSearchResultAndSubmit(
                searchBloc: searchBloc, context: context),
            actions: [
              FloatingSearchBarAction(
                builder: (context, _) {
                  if (searchBarController.query.isEmpty) {
                    return CircularButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () =>
                          print('options menu not implemented yet'),
                    );
                  } else {
                    return CircularButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _onQueryCleared(searchBloc, context),
                    );
                  }
                },
              ),
              FloatingSearchBarAction.searchToClear(
                showIfClosed: false,
              ),
            ],
            progress: state is QueryLoading,
            debounceDelay: const Duration(milliseconds: 500),
            onQueryChanged: (query) => _onQueryChanged(query, searchBloc),
            scrollPadding: EdgeInsets.zero,
            transition: CircularFloatingSearchBarTransition(),
            builder: (context, _) => ExpandableBody(),
          );
        },
      ),
    );
  }

  void _onQueryChanged(String query, SearchBloc searchBloc) {
    final SearchState searchState = searchBloc.state;
    if (searchState is QueryLoadSuccess) {
      if (searchState.query != query) {
        searchBloc.add(QueryChanged(query: query));
      }
    } else if (searchState is QueryEmpty) {
      if (query != '') {
        searchBloc.add(QueryChanged(query: query));
      }
    }
  }

  void _onQueryCleared(SearchBloc searchBloc, BuildContext context) {
    searchBloc.add(const QueryChanged(query: ''));
    searchBloc.searchBarController.close();
    final MapboxState mapboxState = BlocProvider.of<MapboxBloc>(context).state;
    if (mapboxState is MapboxLoadSuccess) {
      mapboxState.controller.onTourDismissed();
    }
    final TourBloc tourBloc = BlocProvider.of<TourBloc>(context);
    final TourState tourState = tourBloc.state;
    if (tourState is TourLoadSuccess) {
      tourBloc.add(TourRemoved());
    }
  }

  void _getSearchResultAndSubmit(
      {@required SearchBloc searchBloc, @required BuildContext context}) {
    final SearchState searchState = searchBloc.state;
    SearchResult searchResult;
    if (searchState is QueryLoadSuccess) {
      searchResult = searchState.searchResults.first;
    } else if (searchState is QueryEmpty) {
      searchResult = searchState.searchHistory.first;
    }
    _onSubmitted(
        searchBloc: searchBloc, context: context, searchResult: searchResult);
  }
}

class ExpandableBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is QueryLoading) {
          return const LoadingIndicator();
        } else if (state is QueryLoadSuccess) {
          return SearchBarBody(
            searchResults: state.searchResults,
          );
        } else if (state is QueryEmpty) {
          return SearchBarBody(
            searchResults: state.searchHistory,
          );
        } else {
          return Container();
        }
      },
    );
  }
}

class SearchBarBody extends StatelessWidget {
  final List<SearchResult> searchResults;

  const SearchBarBody({Key key, this.searchResults}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8),
      child: ImplicitlyAnimatedList<SearchResult>(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        items: searchResults,
        areItemsTheSame: (a, b) => a == b,
        itemBuilder: (context, animation, searchResult, i) {
          return SizeFadeTransition(
            animation: animation,
            child: SearchBarListItem(searchResult: searchResult),
          );
        },
        updateItemBuilder: (context, animation, searchResult) {
          return FadeTransition(
            opacity: animation,
            child: SearchBarListItem(searchResult: searchResult),
          );
        },
      ),
    );
  }
}

class SearchBarListItem extends StatelessWidget {
  final SearchResult searchResult;

  const SearchBarListItem({Key key, @required this.searchResult})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final SearchBloc searchBloc = BlocProvider.of<SearchBloc>(context);
    final SearchState searchState = searchBloc.state;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () {
            _onSubmitted(
                searchBloc: searchBloc,
                context: context,
                searchResult: searchResult);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: _getItemIcon(searchBloc.state, searchResult)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        searchResult.isTour
                            ? "Tour: ${searchResult.name}"
                            : searchResult.name,
                        style: textTheme.subtitle1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        searchResult.secondaryAddress,
                        style: textTheme.bodyText2
                            .copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (searchState is QueryLoadSuccess &&
            searchResult != searchState.searchResults.last)
          const Divider(
            height: 0,
          ),
        if (searchState is QueryEmpty &&
            searchResult != searchState.searchHistory.last)
          const Divider(height: 0),
      ],
    );
  }

  Icon _getItemIcon(SearchState state, SearchResult searchResult) {
    if (state is QueryLoadSuccess) {
      if (searchResult.isTour) {
        return const Icon(Icons.directions_bike);
      } else {
        return const Icon(Icons.place);
      }
    } else if (state is QueryEmpty) {
      return const Icon(Icons.history);
    } else {
      return const Icon(Icons.error);
    }
  }
}

void _onSubmitted(
    {@required SearchBloc searchBloc,
    @required BuildContext context,
    @required SearchResult searchResult}) {
  final SearchState state = searchBloc.state;
  if (state is QueryLoadSuccess) {
    searchBloc.add(QuerySubmitted(
        searchResult: searchResult,
        query: state.query,
        searchResults: state.searchResults));
  } else if (state is QueryEmpty) {
    searchBloc.add(QuerySubmitted(
        searchResult: searchResult,
        query: searchResult.name,
        searchResults: state.searchHistory));
  } else {
    log('Tried submitting query before loading finished',
        name: 'SearchBar', time: DateTime.now());
  }
  searchBloc.searchBarController.close();
  final MapboxBloc mapboxBloc = BlocProvider.of<MapboxBloc>(context);
  final MapboxState mapboxState = mapboxBloc.state;
  if (mapboxState is MapboxLoadSuccess) {
    mapboxState.controller.mapboxMapController
        .updateMyLocationTrackingMode(MyLocationTrackingMode.None);
    mapboxBloc.add(MapboxLoaded(
        mapboxController: mapboxState.controller
            .copyWith(myLocationTrackingMode: MyLocationTrackingMode.None)));
    if (searchResult.isTour) {
      if (mapboxState is MapboxLoadSuccess) {
        // TODO include alternative tours
        BlocProvider.of<TourBloc>(context).add(TourLoaded(
            tourName: searchResult.name,
            mapboxController: mapboxState.controller));
      }
    } else {
      mapboxState.controller.onSelectPlace(searchResult);
    }
  }
}
