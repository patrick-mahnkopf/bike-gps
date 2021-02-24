import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/presentation/blocs/height_map/height_map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:bike_gps/features/presentation/widgets/tour_selection_widgets/tour_selection_bottom_widgets/tour_selection_bottom_sheet_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TourSelectionBottomWidget extends StatelessWidget {
  double get bottomSheetGrabSectionHeight => 101;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TourBloc, TourState>(
      builder: (context, state) {
        if (state is TourLoadSuccess) {
          BlocProvider.of<HeightMapBloc>(context)
              .add(HeightMapLoaded(tour: state.tour));
          return Stack(
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding:
                      EdgeInsets.only(bottom: bottomSheetGrabSectionHeight),
                  child: RecenterMapWidget(),
                ),
              ),
              TourSelectionBottomSheetWidget(
                tour: state.tour,
                grabSectionHeight: bottomSheetGrabSectionHeight,
              ),
            ],
          );
        } else if (state is TourLoading) {
          return const LoadingIndicator();
        } else {
          return Container();
        }
      },
    );
  }
}
