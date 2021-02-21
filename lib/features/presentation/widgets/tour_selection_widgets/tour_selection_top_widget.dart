import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../injection_container.dart';
import 'tour_selection_top_widgets/search_bar_widget.dart';

class TourSelectionTopWidget extends StatelessWidget {
  void showStyleSelectionDialog() {
    // TODO Add styleSelectionDialog

    getIt<TourBloc>().add(const TourLoaded(tourName: 'Eilenriede'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SearchBarWidget(),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 64, right: 8),
            child: FloatingActionButton(
              mini: true,
              onPressed: () => showStyleSelectionDialog(),
              child: const Icon(Icons.layers),
            ),
          ),
        ),
      ],
    );
  }
}
