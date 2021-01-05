import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class OptionsDialogWidget extends StatefulWidget {
  @override
  _OptionsDialogState createState() => _OptionsDialogState();
}

class _OptionsDialogState extends State<OptionsDialogWidget> {
  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.all(0),
      children: [
        Row(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: CloseButton(),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(48, 24, 16, 8),
              child: Image.asset(
                "assets/bike_gps_logo.png",
                color: Colors.blue,
                scale: 2,
              ),
            )
          ],
        ),
        getSimpleDialogOption(Icons.cloud_off, 'Offline maps'),
        getSimpleDialogOption(Icons.battery_unknown, 'E-Bike battery'),
        getSimpleDialogOption(Icons.warning, 'Emergency Information'),
        getSimpleDialogOption(Icons.settings, 'Settings'),
      ],
    );
  }

  getSimpleDialogOption(IconData iconData, String name) {
    return SimpleDialogOption(
      child: Row(
        children: [
          Icon(iconData),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(name),
          )
        ],
      ),
    );
  }
}
