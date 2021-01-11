import 'package:flutter/widgets.dart';

class AdditionalWidget {
  int insertionIndex;
  Widget widget;
  String bottomNavigationBarItemLabel;
  Icon bottomNavigationBarItemIcon;
  BottomNavigationBarItem bottomNavigationBarItem;

  AdditionalWidget(
      {this.insertionIndex,
      this.widget,
      this.bottomNavigationBarItemLabel,
      this.bottomNavigationBarItemIcon}) {
    this.bottomNavigationBarItem = BottomNavigationBarItem(
      label: bottomNavigationBarItemLabel,
      icon: bottomNavigationBarItemIcon,
    );
  }
}
