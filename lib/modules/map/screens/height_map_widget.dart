import 'package:flutter/widgets.dart';

class HeightMapWidget extends StatefulWidget {
  @override
  _HeightMapWidgetState createState() => _HeightMapWidgetState();
}

class _HeightMapWidgetState extends State<HeightMapWidget> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: _visible,
      child: Container(
          // TODO build height map
          ),
    );
  }
}
