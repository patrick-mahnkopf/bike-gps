import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'tour_selection_top_widgets/search_bar_widget.dart';

class TourSelectionTopWidget extends StatelessWidget {
  void showStyleSelectionDialog(BuildContext context) {
    // TODO Add styleSelectionDialog
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        const SearchBarWidget(),
      ],
    );
  }
}
