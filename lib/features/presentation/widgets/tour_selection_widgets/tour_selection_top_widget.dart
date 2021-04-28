import 'package:bike_gps/core/controllers/controllers.dart';
import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tour_selection_top_widgets/search_bar_widget.dart';

/// Shows the search bar and a map style selection button.
class TourSelectionTopWidget extends StatelessWidget {
  /// Displays the style selection dialog when the according button is pressed.
  ///
  /// This allows changing the map source.
  void showStyleSelectionDialog(BuildContext context) {
    final MapboxBloc mapboxBloc = BlocProvider.of<MapboxBloc>(context);
    final MapboxState mapboxState = mapboxBloc.state;

    if (mapboxState is MapboxLoadSuccess) {
      final MapboxController mapboxController = mapboxState.controller;
      final List<BikeGpsDialogOption> dialogOptions = [];
      int initialActiveDialogOptionIndex = 0;

      /// Builds the dialog options.
      for (final String styleName in mapboxController.styleStrings.keys) {
        final String styleString = mapboxController.styleStrings[styleName];
        final bool isActive = styleString == mapboxController.activeStyleString;

        /// Finds the currently active style.
        if (isActive) {
          initialActiveDialogOptionIndex =
              mapboxController.styleStrings.keys.toList().indexOf(styleName);
        }

        /// Makes a dialog option.
        dialogOptions.add(BikeGpsDialogOption(
          optionIcon: Icons.map,
          optionText: '$styleName map',
          isActive: isActive,
          onPressedCallback: () => mapboxBloc.add(
            MapboxLoaded(
                mapboxController: mapboxController,
                activeStyleString: styleString),
          ),
        ));
      }

      /// Shows the dialog.
      showBikeGpsDialog(
          context: context,
          dialogOptions: dialogOptions,
          initialActiveDialogOptionIndex: initialActiveDialogOptionIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 64, right: 8),

            /// A button showing the map style selection dialog when pressed.
            child: FloatingActionButton(
              mini: true,
              onPressed: () => showStyleSelectionDialog(context),
              child: const Icon(Icons.layers),
            ),
          ),
        ),

        /// The search bar at the top of the screen.
        const SearchBarWidget(),
      ],
    );
  }
}
