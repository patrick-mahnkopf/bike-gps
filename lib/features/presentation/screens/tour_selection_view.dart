import 'package:bike_gps/features/presentation/blocs/map/map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injection_container.dart';
import '../widgets/tour_selection_widgets/tour_info_bottom_sheet_widgets/widgets.dart';

class TourSelectionView extends StatelessWidget {
  const TourSelectionView({Key key}) : super(key: key);

  void showStyleSelectionDialog() {
    // TODO Add styleSelectionDialog

    getIt<TourBloc>().add(const TourLoaded(tourName: 'Eilenriede'));
  }

  void temp(BuildContext context) {
    getIt<MapBloc>().add(NavigationViewActivated());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TourBloc>(),
      child: SafeArea(
        child: Column(
          children: [
            const SearchBarWidget(),
            Padding(
              padding: const EdgeInsets.only(top: 64, right: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: showStyleSelectionDialog,
                  child: const Icon(Icons.layers),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 64, right: 8),
              child: Align(
                alignment: Alignment.topRight,
                child: FloatingActionButton(
                  mini: true,
                  onPressed: () => temp(context),
                  child: const Icon(Icons.layers),
                ),
              ),
            ),
            BlocBuilder<TourBloc, TourState>(
              builder: (context, state) {
                if (state is TourLoadSuccess) {
                  return TourInfoBottomSheetWidget(
                    tour: state.tour,
                  );
                } else {
                  return Container();
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
