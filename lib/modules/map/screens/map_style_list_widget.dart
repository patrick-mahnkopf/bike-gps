import 'package:flutter/material.dart';

class MapStyleListWidget extends StatefulWidget {
  final Function changeStyleCallback;
  final List<String> styleStringNames;
  final String currentStyleName;

  MapStyleListWidget(
      {Key key,
      this.changeStyleCallback,
      this.styleStringNames,
      this.currentStyleName})
      : super(key: key);

  @override
  State createState() => MapStyleListState(
      changeStyleCallback, styleStringNames, currentStyleName);
}

class MapStyleListState extends State<MapStyleListWidget> {
  final Function changeStyleCallback;
  final List<String> styleStringNames;
  final String currentStyleName;

  MapStyleListState(
      this.changeStyleCallback, this.styleStringNames, this.currentStyleName);

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
        getSimpleDialogOption(Icons.map, styleStringNames[0]),
        getSimpleDialogOption(Icons.map, styleStringNames[1]),
      ],
    );
  }

  getSimpleDialogOption(IconData iconData, String name) {
    bool currentStyle = currentStyleName == name;
    return SimpleDialogOption(
      onPressed: () => currentStyle ? null : onDialogOptionPressed(name),
      child: Opacity(
        opacity: currentStyle ? 0.3 : 1,
        child: Row(
          children: [
            Icon(iconData),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              child:
                  currentStyle ? Text("$name map (active)") : Text("$name map"),
            )
          ],
        ),
      ),
    );
  }

  onDialogOptionPressed(String styleName) {
    changeStyleCallback(styleName);
    Navigator.pop(context, true);
  }
}
