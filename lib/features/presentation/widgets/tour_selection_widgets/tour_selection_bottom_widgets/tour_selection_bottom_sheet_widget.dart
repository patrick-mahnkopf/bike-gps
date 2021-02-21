import 'package:bike_gps/core/helpers/distance_helper.dart';
import 'package:bike_gps/core/widgets/custom_widgets.dart';
import 'package:bike_gps/features/presentation/blocs/map/map_bloc.dart';
import 'package:bike_gps/injection_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../../../domain/entities/tour/entities.dart';

class TourSelectionBottomSheetWidget extends StatelessWidget {
  final Tour tour;
  final double grabSectionHeight;

  const TourSelectionBottomSheetWidget(
      {Key key, this.tour, this.grabSectionHeight})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomSheetWidget(
      grabSectionHeight: grabSectionHeight,
      grabSectionContent: GrabSectionContent(
        tour: tour,
        distanceHelper: getIt(),
      ),
      sheetContent: SheetContent(
        tour: tour,
      ),
    );
  }
}

class GrabSectionContent extends StatelessWidget {
  final Tour tour;
  final DistanceHelper distanceHelper;

  const GrabSectionContent({
    Key key,
    @required this.tour,
    @required this.distanceHelper,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  distanceHelper.distanceToString(tour.tourLength),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const Icon(
                Icons.arrow_upward,
                color: Colors.green,
                size: 16,
              ),
              Text(
                distanceHelper.distanceToString(tour.ascent),
              ),
              const Icon(
                Icons.arrow_downward,
                color: Colors.red,
                size: 16,
              ),
              Text(
                distanceHelper.distanceToString(tour.descent),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.list),
                  label: const Text("Road book"),
                  onPressed: () => Provider.of<BottomSheetSnapController>(
                          context,
                          listen: false)
                      .toggleBetweenSnapPositions(),
                  style: ElevatedButton.styleFrom(
                    primary: Colors.white,
                    onPrimary: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.navigation),
                    label: const Text("Start"),
                    onPressed: () =>
                        getIt<MapBloc>().add(NavigationViewActivated()),
                    style: ElevatedButton.styleFrom(
                      primary: Colors.blue,
                      onPrimary: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}

class SheetContent extends StatelessWidget {
  final Tour tour;

  const SheetContent({Key key, @required this.tour}) : super(key: key);

  int get _itemCount => tour.wayPoints.isEmpty ? 1 : tour.wayPoints.length;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HeightMap(),
            Flexible(
              child: ListView.builder(
                padding: const EdgeInsets.all(20.0),
                itemCount: _itemCount,
                itemBuilder: (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey[300],
                        ),
                      ),
                    ),
                    child: RoadBook(tour: tour, index: index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HeightMap extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container();
  }
}

class RoadBook extends StatelessWidget {
  final Tour tour;
  final int index;

  const RoadBook({Key key, @required this.tour, @required this.index})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tour.wayPoints.isEmpty) {
      return const ListTile(
        leading: Icon(Icons.error),
        title: Text('This route file does not include road book information'),
      );
    } else {
      // TODO: implement build
      return Container();
    }
  }
}
