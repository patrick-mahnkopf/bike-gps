import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'tour_selection_top_widgets/search_bar_widget.dart';

class TourSelectionTopWidget extends StatelessWidget {
  void showStyleSelectionDialog(BuildContext context) {
    // TODO Add styleSelectionDialog

    BlocProvider.of<TourBloc>(context)
        .add(TourLoaded(tourName: 'Eilenriede', context: context));
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
              onPressed: () => showStyleSelectionDialog(context),
              child: const Icon(Icons.layers),
            ),
          ),
        ),
      ],
    );
  }
}
