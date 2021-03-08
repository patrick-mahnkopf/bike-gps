import 'dart:math';

import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/features/presentation/blocs/map/map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class CustomContainerTextWidget extends StatelessWidget {
  final String text;
  final Color color;

  const CustomContainerTextWidget({Key key, @required this.text, this.color})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}

class RecenterMapWidget extends StatelessWidget {
  final ConstantsHelper constantsHelper;

  const RecenterMapWidget({Key key, @required this.constantsHelper})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MapboxBloc mapboxBloc = BlocProvider.of<MapboxBloc>(context);
    final MapState mapState = BlocProvider.of<MapBloc>(context).state;
    return BlocBuilder<MapboxBloc, MapboxState>(
      builder: (context, state) {
        if (state is MapboxLoadSuccess &&
            state.controller.mapboxMapController != null &&
            state.controller.myLocationTrackingMode !=
                MyLocationTrackingMode.TrackingCompass) {
          return Padding(
            padding: const EdgeInsets.all(8),
            child: FloatingActionButton.extended(
              onPressed: () => _recenterMap(mapboxBloc, mapState, state),
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
          );
        } else {
          return Container();
        }
      },
    );
  }

  void _recenterMap(
      MapboxBloc mapboxBloc, MapState mapState, MapboxLoadSuccess state) {
    CameraUpdate cameraUpdate;
    if (mapState is NavigationViewActive) {
      cameraUpdate = CameraUpdate.zoomTo(constantsHelper.navigationViewZoom);
    } else if (mapState is TourSelectionViewActive) {
      cameraUpdate = CameraUpdate.zoomTo(constantsHelper.tourViewZoom);
    }
    mapboxBloc.add(MapboxLoaded(
      mapboxController: state.controller.copyWith(
          myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass),
      cameraUpdate: cameraUpdate,
    ));
  }
}

class BottomSheetSnapController extends ChangeNotifier {
  final SnappingSheetController snappingSheetController;
  bool snappingTop = false;

  BottomSheetSnapController({@required this.snappingSheetController});

  void onSnapEnd() {
    bool _snappingTop;
    if (snappingSheetController.currentSnapPosition ==
        snappingSheetController.snapPositions.last) {
      _snappingTop = true;
    } else {
      _snappingTop = false;
    }
    if (snappingTop != _snappingTop) {
      snappingTop = _snappingTop;
      notifyListeners();
    }
  }

  void toggleBetweenSnapPositions() {
    if (snappingSheetController.currentSnapPosition ==
        snappingSheetController.snapPositions.first) {
      snappingSheetController
          .snapToPosition(snappingSheetController.snapPositions.last);
    } else {
      snappingSheetController
          .snapToPosition(snappingSheetController.snapPositions.first);
    }
    onSnapEnd();
  }
}

class BottomSheetWidget extends StatelessWidget {
  static final SnappingSheetController _snappingSheetController =
      SnappingSheetController();
  final BottomSheetSnapController snapController = BottomSheetSnapController(
      snappingSheetController: _snappingSheetController);
  final double centerSnapPosition;
  final double topSnapPosition;
  final double grabSectionHeight;
  final Widget grabSectionContent;
  final Widget sheetContent;

  BottomSheetWidget(
      {Key key,
      this.centerSnapPosition = 0.6,
      this.topSnapPosition = 1,
      this.grabSectionHeight = 150,
      this.grabSectionContent,
      this.sheetContent})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => snapController,
      child: SnappingSheet(
        onSnapEnd: snapController.onSnapEnd,
        snappingSheetController: _snappingSheetController,
        grabbingHeight: grabSectionHeight,
        lockOverflowDrag: true,
        snapPositions: [
          const SnapPosition(
              positionFactor: 0,
              snappingCurve: Curves.elasticOut,
              snappingDuration: Duration(milliseconds: 750)),
          SnapPosition(positionFactor: centerSnapPosition),
          SnapPosition(positionFactor: topSnapPosition),
        ],
        grabbing: BottomSheetGrabSection(
          content: grabSectionContent,
        ),
        sheetBelow: SnappingSheetContent(
          heightBehavior: const SnappingSheetHeight.fixed(),
          child: sheetContent,
        ),
      ),
    );
  }
}

class BottomSheetGrabSection extends StatelessWidget {
  final Widget content;

  const BottomSheetGrabSection({this.content});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: RoundedContainer(
        content: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Consumer<BottomSheetSnapController>(
              builder: (context, snapController, child) {
                if (snapController.snappingTop) {
                  return GrabIconArrow();
                } else {
                  return GrabIconStraight();
                }
              },
            ),
            content,
            DividerLine(),
          ],
        ),
      ),
    );
  }
}

class DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2.0,
      margin: const EdgeInsets.only(left: 20, right: 20),
      color: Colors.grey[300],
    );
  }
}

class GrabIconStraight extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 4,
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: const BorderRadius.all(Radius.circular(5.0))),
    );
  }
}

class GrabIconArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
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
                borderRadius: const BorderRadius.all(Radius.circular(5.0))),
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
                borderRadius: const BorderRadius.all(Radius.circular(5.0))),
          ),
        ),
      ],
    );
  }
}

class RoundedContainer extends StatelessWidget {
  final Widget content;

  const RoundedContainer({Key key, this.content}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: content,
    );
  }
}
