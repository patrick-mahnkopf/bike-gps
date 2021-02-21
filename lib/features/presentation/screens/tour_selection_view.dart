import 'package:bike_gps/features/presentation/widgets/tour_selection_widgets/tour_selection_bottom_widget.dart';
import 'package:bike_gps/features/presentation/widgets/tour_selection_widgets/tour_selection_top_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injection_container.dart';
import '../blocs/tour/tour_bloc.dart';

class TourSelectionView extends StatelessWidget {
  const TourSelectionView({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TourBloc>(),
      child: SafeArea(
        child: Stack(
          children: [
            TourSelectionTopWidget(),
            TourSelectionBottomWidget(),
          ],
        ),
      ),
    );
  }
}
