import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/helpers/helpers.dart';
import '../../../../injection_container.dart';
import '../../../blocs/map/map_bloc.dart';
import '../../../blocs/mapbox/mapbox_bloc.dart';

class NavigationBottomSheetWidget extends StatelessWidget {
  final double distanceToTourEnd;
  final DistanceHelper locationHelper;

  const NavigationBottomSheetWidget(
      {Key key,
      @required this.distanceToTourEnd,
      @required this.locationHelper})
      : super(key: key);

  void stopNavigation() {
    getIt<MapBloc>().add(TourSelectionViewActivated());
  }

  void recenterMap() {
    final MapboxState mapboxState = getIt<MapboxBloc>().state;
    if (mapboxState is MapboxLoadSuccess) {
      mapboxState.controller.recenterMap();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, right: 8),
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                child: FloatingActionButton.extended(
                  onPressed: () => recenterMap(),
                  backgroundColor: Colors.white,
                  label: const Text(
                    "Re-center",
                    style: TextStyle(color: Colors.blue),
                  ),
                  icon: const Icon(
                    Icons.navigation,
                    color: Colors.blue,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.zero,
                margin: EdgeInsets.zero,
                alignment: Alignment.topCenter,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 20.0,
                      color: Colors.black.withOpacity(0.2),
                    )
                  ],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8.0),
                    topRight: Radius.circular(8.0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Stack(
                      children: [
                        Transform.rotate(
                          angle: pi / 8,
                          child: Container(
                            padding: EdgeInsets.zero,
                            width: 16,
                            height: 4,
                            margin: const EdgeInsets.only(top: 8, right: 8),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0))),
                          ),
                        ),
                        Transform.rotate(
                          angle: -pi / 8,
                          child: Container(
                            padding: EdgeInsets.zero,
                            width: 16,
                            height: 4,
                            margin: const EdgeInsets.only(top: 8, left: 8),
                            decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0))),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              locationHelper
                                  .distanceToString(distanceToTourEnd),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => stopNavigation(),
                                style: ElevatedButton.styleFrom(
                                  primary: Colors.red,
                                  onPrimary: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(64),
                                  ),
                                ),
                                child: const Text("Exit"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 2.0,
                      margin: const EdgeInsets.only(left: 20, right: 20),
                      color: Colors.grey[300],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
