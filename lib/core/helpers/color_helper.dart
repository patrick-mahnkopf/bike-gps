import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../error/failure.dart';

@injectable
class ColorHelper {
  Either<Failure, String> colorToHex(
      {MaterialColor materialColor, Color color}) {
    int value;
    if (materialColor == null && color == null) {
      return left(ArgumentFailure());
    } else if (materialColor != null && color != null) {
      return left(ArgumentFailure());
    } else if (materialColor != null) {
      value = materialColor.value;
    } else {
      value = color.value;
    }
    return right(
        '#${value.toRadixString(16).substring(2, value.toRadixString(16).length).padLeft(6, '0')}');
  }
}
