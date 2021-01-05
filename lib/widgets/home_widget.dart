import 'package:bike_gps/widgets/loading_widget.dart';
import 'package:bike_gps/widgets/map_view/map_widget.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:route_parser/route_parser.dart';
import 'package:tuple/tuple.dart';

class Home extends StatefulWidget {
  final RouteParser routeParser;
  final List<Tuple3<int, Widget, BottomNavigationBarItem>> additionalWidgetList;

  Home(
      {this.routeParser,
      List<Tuple3<int, Widget, BottomNavigationBarItem>> additionalWidgetList})
      : this.additionalWidgetList = additionalWidgetList ?? [];

  @override
  State<StatefulWidget> createState() =>
      _HomeState(routeParser, additionalWidgetList: additionalWidgetList);
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;
  RouteParser routeParser;
  List<Tuple3<int, Widget, BottomNavigationBarItem>> additionalWidgetList;
  List<Widget> _children;

  _HomeState(this.routeParser, {this.additionalWidgetList}) {
    _children = [
      FullMapWidget(routeParser),
      LoadingWidget(),
    ];
    additionalWidgetList.forEach((tuple) {
      _children.insert(tuple.item1, tuple.item2);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: getBottomNavigationBarItems(),
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  getBottomNavigationBarItems() {
    List<BottomNavigationBarItem> items = [
      BottomNavigationBarItem(icon: new Icon(Icons.map), label: 'Map'),
      BottomNavigationBarItem(icon: new Icon(Icons.more_horiz), label: 'More'),
    ];
    for (Tuple3 tuple in additionalWidgetList) {
      items.insert(tuple.item1, tuple.item3);
    }
    return items;
  }

  @override
  void initState() {
    super.initState();
    _getPermissions();
  }

  void _getPermissions() async {
    final location = Location();
    final hasPermissions = await location.hasPermission();
    if (hasPermissions != PermissionStatus.granted) {
      await location.requestPermission();
    }
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
