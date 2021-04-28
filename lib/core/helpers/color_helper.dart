import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../error/failure.dart';

/// Helper class that handles color conversions.
@injectable
class ColorHelper {
  /// Converts the [materialColor] or [color] to it's hex code representation.
  Either<Failure, String> colorToHex(
      {MaterialColor materialColor, Color color}) {
    int value;

    ///Returns an ArgumentFailure if no color was provided.
    if (materialColor == null && color == null) {
      return left(ArgumentFailure());

      ///Returns an ArgumentFailure if both types of color were provided.
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
