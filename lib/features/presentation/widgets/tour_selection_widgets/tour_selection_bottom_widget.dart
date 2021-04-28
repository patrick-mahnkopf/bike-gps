import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/presentation/blocs/tour/tour_bloc.dart';
import 'package:bike_gps/features/presentation/widgets/tour_selection_widgets/tour_selection_bottom_widgets/tour_selection_bottom_sheet_widget.dart';
import 'package:bike_gps/injection_container.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows a recenter map button and the bottom sheet if there is an active tour.
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

                  /// A button to recenter the map to the user location.
                  child: RecenterMapWidget(
                    constantsHelper: getIt(),
                  ),
                ),
              ),

              /// The tour selection bottom sheet.
              TourSelectionBottomSheetWidget(
                grabSectionHeight: bottomSheetGrabSectionHeight,
              ),
            ],
          );
        } else if (state is TourLoading) {
          return const LoadingIndicator();

          /// Displays only the recenter button when there is no active tour.
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
