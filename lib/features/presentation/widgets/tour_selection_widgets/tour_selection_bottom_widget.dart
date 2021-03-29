import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:bike_gps/features/presentation/widgets/tour_selection_widgets/tour_selection_bottom_widgets/tour_selection_bottom_sheet_widget.dart';
import 'package:bike_gps/injection_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TourSelectionBottomWidget extends StatelessWidget {
  double get bottomSheetGrabSectionHeight => 101;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TourBloc, TourState>(
      builder: (context, state) {
        if (state is TourLoadSuccess) {
          return Stack(
            children: [
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding:
                      EdgeInsets.only(bottom: bottomSheetGrabSectionHeight),
                  child: RecenterMapWidget(
                    constantsHelper: getIt(),
                  ),
                ),
              ),
              TourSelectionBottomSheetWidget(
                grabSectionHeight: bottomSheetGrabSectionHeight,
              ),
            ],
          );
        } else if (state is TourLoading) {
          return const LoadingIndicator();
        } else {
          return Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: RecenterMapWidget(
                constantsHelper: getIt(),
              ),
            ),
          );
        }
      },
    );
  }
}
