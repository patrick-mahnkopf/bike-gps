import 'package:flutter/material.dart';

class MapStyleListWidget extends StatefulWidget {
  final Function changeStyleCallback;
  final List<String> styleStringNames;

  MapStyleListWidget({Key key, this.changeStyleCallback, this.styleStringNames})
      : super(key: key);

  @override
  State createState() =>
      MapStyleListState(changeStyleCallback, styleStringNames);
}

class MapStyleListState extends State<MapStyleListWidget> {
  final Function changeStyleCallback;
  final List<String> styleStringNames;
  bool _visible = false;

  MapStyleListState(this.changeStyleCallback, this.styleStringNames);

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _visible,
      child: Padding(
        padding: EdgeInsets.only(left: 24.0, right: 24.0),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: styleStringNames.length,
          itemBuilder: (context, index) {
            return ListTile(
              tileColor: Colors.white,
              leading: Icon(Icons.map),
              title: Text('${styleStringNames[index]} map'),
              onTap: () => onTileTap(styleStringNames[index]),
            );
          },
        ),
      ),
    );
  }

  onTileTap(String mapStyleName) {
    changeStyleCallback(mapStyleName);
    toggleVisibility();
  }

  toggleVisibility() {
    setState(() {
      _visible = !_visible;
    });
  }
}
