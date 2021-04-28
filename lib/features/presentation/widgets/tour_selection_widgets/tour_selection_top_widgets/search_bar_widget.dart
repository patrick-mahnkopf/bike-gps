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

/// The search bar.
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
                      onPressed: () => _displayOptionsMenu(),
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

  /// Notifies the [SearchBloc] when the [query] changes.
  ///
  /// Adds a [QueryChanged] event containing the new [query] to the
  /// [SearchBloc].
  void _onQueryChanged(String query, SearchBloc searchBloc) {
    final SearchState searchState = searchBloc.state;

    /// Handles query changes if a previous query existed.
    if (searchState is QueryLoadSuccess) {
      if (searchState.query != query) {
        searchBloc.add(QueryChanged(query: query));
      }

      /// Handles query changes for a previously empty query.
    } else if (searchState is QueryEmpty) {
      if (query != '') {
        searchBloc.add(QueryChanged(query: query));
      }
    }
  }

  /// Notifies the [SearchBloc] when the [query] is cleared.
  ///
  /// Dismisses active tours if they exist and resets the map.
  void _onQueryCleared(SearchBloc searchBloc, BuildContext context) {
    searchBloc.add(const QueryChanged(query: ''));
    searchBloc.searchBarController.close();
    final MapboxState mapboxState = BlocProvider.of<MapboxBloc>(context).state;

    /// Clears map drawings and reset the camera location.
    if (mapboxState is MapboxLoadSuccess) {
      mapboxState.controller.onTourDismissed();
    }
    final TourBloc tourBloc = BlocProvider.of<TourBloc>(context);
    final TourState tourState = tourBloc.state;

    /// Removes active tours if they exist.
    if (tourState is TourLoadSuccess) {
      tourBloc.add(TourRemoved());
    }
  }

  /// Gets the first search result in the list and submits it.
  ///
  /// This gets called if the user didn't select a specific search result, for
  /// example by pressing the search or enter button. In these cases the first
  /// result is selected.
  void _getSearchResultAndSubmit(
      {@required SearchBloc searchBloc, @required BuildContext context}) {
    final SearchState searchState = searchBloc.state;
    SearchResult searchResult;

    /// Selects the first search result.
    if (searchState is QueryLoadSuccess) {
      searchResult = searchState.searchResults.first;

      /// Selects the first search history item.
    } else if (searchState is QueryEmpty) {
      searchResult = searchState.searchHistory.first;
    }

    /// Submits the search item.
    _onSubmitted(
        searchBloc: searchBloc, context: context, searchResult: searchResult);
  }

  /// Displays an options menu for the app.
  ///
  /// Gets called when tapping the search bar's hamburger menu.
  void _displayOptionsMenu() {
    // TODO implement search bar options menu
  }
}

/// Displays the body of the list of search results or search history items.
class ExpandableBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is QueryLoading) {
          return const LoadingIndicator();
        } else if (state is QueryLoadSuccess) {
          if (state.searchResults.isEmpty) {
            return Container();

            /// Displays the search results.
          } else {
            return SearchBarBody(
              searchResults: state.searchResults,
            );
          }
        } else if (state is QueryEmpty) {
          if (state.searchHistory.isEmpty) {
            return Container();
          } else {
            /// Displays the search history items.
            return SearchBarBody(
              searchResults: state.searchHistory,
            );
          }
        } else {
          return Container();
        }
      },
    );
  }
}

/// Displays the list of search results or search history items.
class SearchBarBody extends StatelessWidget {
  final List<SearchResult> searchResults;

  const SearchBarBody({Key key, this.searchResults}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8),

      /// The list containing the search items.
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

/// A single search result of search history item to be displayed in the search
/// result list.
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
          /// Submit this item when tapped.
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

                      /// Gets an icon depending on the result type.
                      child: _getItemIcon(searchBloc.state, searchResult)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// The search results name. Prepends "Tour: " if it is a
                      /// tour.
                      Text(
                        searchResult.isTour
                            ? "Tour: ${searchResult.name}"
                            : searchResult.name,
                        style: textTheme.subtitle1,
                      ),
                      const SizedBox(height: 2),

                      /// Location information of the search result.
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

        /// Places a divider between search results except for the last one.
        if (searchState is QueryLoadSuccess &&
            searchResult != searchState.searchResults.last)
          const Divider(
            height: 0,
          ),

        /// Places a divider between search history items except for the last
        /// one.
        if (searchState is QueryEmpty &&
            searchResult != searchState.searchHistory.last)
          const Divider(height: 0),
      ],
    );
  }

  /// Gets an icon depending on the result type of [searchResult].
  Icon _getItemIcon(SearchState state, SearchResult searchResult) {
    if (state is QueryLoadSuccess) {
      /// Returns the tour icon for tour results.
      if (searchResult.isTour) {
        return const Icon(Icons.directions_bike);

        /// Returns the place icon for location results.
      } else {
        return const Icon(Icons.place);
      }

      /// Returns the history icon for search history items.
    } else if (state is QueryEmpty) {
      return const Icon(Icons.history);

      /// Returns an error icon if there is no appropriate icon for this result.
    } else {
      return const Icon(Icons.error);
    }
  }
}

/// Submits the selected [searchResult] to the [searchBloc].
void _onSubmitted(
    {@required SearchBloc searchBloc,
    @required BuildContext context,
    @required SearchResult searchResult}) {
  final SearchState state = searchBloc.state;

  /// Submits the selected search result.
  if (state is QueryLoadSuccess) {
    searchBloc.add(QuerySubmitted(
        searchResult: searchResult,
        query: state.query,
        searchResults: state.searchResults));

    /// Submits the selected search history item.
  } else if (state is QueryEmpty) {
    searchBloc.add(QuerySubmitted(
        searchResult: searchResult,
        query: searchResult.name,
        searchResults: state.searchHistory));

    /// The search bar is currently loading.
  } else {
    log('Tried submitting query before loading finished',
        name: 'SearchBar', time: DateTime.now());
  }
  searchBloc.searchBarController.close();
  final MapboxBloc mapboxBloc = BlocProvider.of<MapboxBloc>(context);
  final MapboxState mapboxState = mapboxBloc.state;
  if (mapboxState is MapboxLoadSuccess) {
    /// Disables map camera tracking.
    mapboxBloc.add(MapboxLoaded(
        mapboxController: mapboxState.controller,
        myLocationTrackingMode: MyLocationTrackingMode.None));

    /// Moves the map camera to the tour bounds and draws the tours.
    if (searchResult.isTour) {
      if (mapboxState is MapboxLoadSuccess) {
        BlocProvider.of<TourBloc>(context).add(TourLoaded(
            tourName: searchResult.name,
            mapboxController: mapboxState.controller));
      }

      /// Moves the map camera to the selected location.
    } else {
      mapboxState.controller.onSelectPlace(searchResult);
    }
  }
}
