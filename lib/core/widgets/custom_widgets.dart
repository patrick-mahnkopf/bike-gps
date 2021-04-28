import 'dart:math' show pi;

import 'package:bike_gps/core/helpers/constants_helper.dart';
import 'package:bike_gps/features/presentation/blocs/map/map_bloc.dart';
import 'package:bike_gps/features/presentation/blocs/mapbox/mapbox_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';

/// A collection of custom widgets used throughout the app.

/// A custom loading indicator.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// A custom container widget with text inside.
///
/// Used for list items that only contain text.
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

/// A custom button that recenters the Mapbox map on the user location.
///
/// Hides automatically when the user location is tracked. Changes the map's
/// location tracking mode to tracking compass when pressed.
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
        /// Only show when the map is ready and the user location is not
        /// already tracked.
        if (state is MapboxLoadSuccess &&
            state.controller.mapboxMapController != null &&
            state.controller.myLocationTrackingMode !=
                MyLocationTrackingMode.TrackingCompass) {
          return Padding(
            padding: const EdgeInsets.all(8),

            /// Button to recenter the map.
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

  /// Recenters the Mapbox map on the user location.
  ///
  /// Changes the map's location tracking mode to tracking compass.
  void _recenterMap(
      MapboxBloc mapboxBloc, MapState mapState, MapboxLoadSuccess state) {
    CameraUpdate cameraUpdate;

    /// Get the zoom used during navigation.
    if (mapState is NavigationViewActive) {
      cameraUpdate = CameraUpdate.zoomTo(constantsHelper.navigationViewZoom);

      /// Get the zoom used during tour selection.
    } else if (mapState is TourSelectionViewActive) {
      cameraUpdate = CameraUpdate.zoomTo(constantsHelper.tourViewZoom);
    }

    /// Apply the zoom and activate the tracking compass location tracking mode.
    mapboxBloc.add(MapboxLoaded(
      mapboxController: state.controller,
      myLocationTrackingMode: MyLocationTrackingMode.TrackingCompass,
      cameraUpdate: cameraUpdate,
    ));
  }
}

/// A controller handling the bottom sheet snapping behaviour.
class BottomSheetSnapController extends ChangeNotifier {
  final SnappingSheetController snappingSheetController;
  bool snappingTop = false;

  BottomSheetSnapController({@required this.snappingSheetController});

  /// Handles snapping position changes
  void onSnapEnd() {
    bool _snappingTop;

    /// The bottom sheet is in the highest position.
    if (snappingSheetController.currentSnapPosition ==
        snappingSheetController.snapPositions.last) {
      _snappingTop = true;

      /// The bottom sheet is not in the highest position.
    } else {
      _snappingTop = false;
    }

    /// Notifies listeners when snapping at the top changes.
    if (snappingTop != _snappingTop) {
      snappingTop = _snappingTop;
      notifyListeners();
    }
  }

  /// Toggles between the maximum and minimum snap positions.
  void toggleBetweenSnapPositions() {
    /// Snaps to the maximum if in the minimum position.
    if (snappingSheetController.currentSnapPosition ==
        snappingSheetController.snapPositions.first) {
      snappingSheetController
          .snapToPosition(snappingSheetController.snapPositions.last);

      /// Snaps to the minimum position if anywhere else.
    } else {
      snappingSheetController
          .snapToPosition(snappingSheetController.snapPositions.first);
    }

    /// Notifies listeners.
    onSnapEnd();
  }
}

/// A custom bottom sheet defining default snapping positions.
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

/// A custom bottom sheet grab section including an arrow icon that changes
/// depending on the snapping position.
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

/// A custom divider line for lists.
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

/// A horizontal bar used as a bottom sheet grab icon when not in the top
/// snapping position.
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

/// A downward arrow used as a bottom sheet grab icon when in the top snapping
/// position.
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

/// A custom rounded container.
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

/// Displays a [BikeGpsDialogWidget].
void showBikeGpsDialog(
    {@required BuildContext context,
    @required List<BikeGpsDialogOption> dialogOptions,
    @required int initialActiveDialogOptionIndex}) {
  showGeneralDialog(
    barrierLabel: "Barrier",
    barrierDismissible: true,
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 100),
    context: context,
    pageBuilder: (_, __, ___) {
      return BikeGpsDialogWidget(
        dialogOptions: dialogOptions,
        initialActiveDialogOptionIndex: initialActiveDialogOptionIndex,
      );
    },
    transitionBuilder: (_, anim, __, child) {
      return FadeTransition(
        opacity: anim,
        child: child,
      );
    },
  );
}

/// A custom dialog including the Bike GPS logo at the top.
class BikeGpsDialogWidget extends StatefulWidget {
  final List<BikeGpsDialogOption> dialogOptions;
  final int initialActiveDialogOptionIndex;

  const BikeGpsDialogWidget(
      {Key key,
      @required this.dialogOptions,
      @required this.initialActiveDialogOptionIndex})
      : super(key: key);

  @override
  _BikeGpsDialogWidgetState createState() => _BikeGpsDialogWidgetState();
}

class _BikeGpsDialogWidgetState extends State<BikeGpsDialogWidget> {
  int activeDialogOptionIndex;

  @override
  void initState() {
    activeDialogOptionIndex = widget.initialActiveDialogOptionIndex;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: const EdgeInsets.all(0),
      children: [
        Row(
          children: [
            /// A button to close the dialog.
            const Align(
              alignment: Alignment.topLeft,
              child: CloseButton(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 24, 16, 8),

              /// The Bike GPS logo.
              child: Image.asset(
                "assets/images/branding/bike_gps_logo.png",
                color: Colors.blue,
                scale: 2,
              ),
            )
          ],
        ),

        /// Displays the dialog options.
        ..._getDialogOptions(),
      ],
    );
  }

  /// Applies the correct [_onTapped] callback to the dialog options and
  /// activates the currently active one.
  List<BikeGpsDialogOption> _getDialogOptions() {
    final List<BikeGpsDialogOption> dialogOptions = [];
    for (var i = 0; i < widget.dialogOptions.length; i++) {
      final BikeGpsDialogOption dialogOption = widget.dialogOptions[i];
      if (i == activeDialogOptionIndex) {
        dialogOptions.add(dialogOption.copyWith(
            isActive: true, onTapped: _onTapped, optionIndex: i));
      } else {
        dialogOptions.add(dialogOption.copyWith(
            isActive: false, onTapped: _onTapped, optionIndex: i));
      }
    }
    return dialogOptions;
  }

  /// Calls the registered callback for the dialog option at [optionIndex].
  void _onTapped(int optionIndex) {
    widget.dialogOptions[optionIndex].onPressedCallback();
    setState(() {
      activeDialogOptionIndex = optionIndex;
    });
  }
}

/// Custom dialog options for the [BikeGpsDialogWidget].
class BikeGpsDialogOption extends StatelessWidget {
  final bool isActive;
  final Function onPressedCallback;
  final Function onTapped;
  final IconData optionIcon;
  final String optionText;
  final int optionIndex;

  const BikeGpsDialogOption({
    @required this.optionIcon,
    @required this.optionText,
    @required this.onPressedCallback,
    this.isActive = false,
    this.onTapped,
    this.optionIndex,
  });

  BikeGpsDialogOption copyWith({
    IconData optionIcon,
    String optionText,
    bool isActive,
    Function onTapped,
    Function onPressedCallback,
    int optionIndex,
  }) {
    return BikeGpsDialogOption(
      optionIcon: optionIcon ?? this.optionIcon,
      optionText: optionText ?? this.optionText,
      isActive: isActive ?? this.isActive,
      onTapped: onTapped ?? this.onTapped,
      onPressedCallback: onPressedCallback ?? this.onPressedCallback,
      optionIndex: optionIndex ?? this.optionIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color activeOptionColor = Colors.blue;
    const Color inactiveOptionColor = Colors.black;
    return SimpleDialogOption(
      /// Calls the registered callback.
      onPressed: () => isActive ? null : onTapped(optionIndex),
      child: Row(
        children: [
          /// The icon of this dialog entry.
          Icon(
            optionIcon,
            color: isActive ? activeOptionColor : inactiveOptionColor,
          ),

          /// The text of this dialog entry.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              optionText,
              style: TextStyle(
                color: isActive ? activeOptionColor : inactiveOptionColor,
              ),
            ),
          ),

          /// Displays a check mark if this dialog entry is currently active.
          if (isActive)
            const Icon(
              Icons.check,
              color: activeOptionColor,
            )
          else
            Container(),
        ],
      ),
    );
  }
}
