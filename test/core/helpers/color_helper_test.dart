import 'package:bike_gps/core/error/failure.dart';
import 'package:bike_gps/core/helpers/color_helper.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MaterialColor materialColor = Colors.blue;
  const Color color = Colors.black;
  ColorHelper colorHelper;

  setUp(() {
    colorHelper = ColorHelper();
  });

  test('should convert Color to corresponding hex code', () {
    // arrange
    // act
    final result = colorHelper.colorToHex(color: color);
    // assert
    expect(result, right('#000000'));
  });

  test('should convert MaterialColor to corresponding hex code', () {
    // arrange
    // act
    final result = colorHelper.colorToHex(materialColor: materialColor);
    // assert
    expect(result, right('#2196f3'));
  });

  test('should throw an ArgumentFailure if more than one color is provided',
      () {
    // arrange
    // act
    final call = colorHelper.colorToHex;
    // assert
    expect(call(color: color, materialColor: materialColor),
        left(ArgumentFailure()));
  });

  test('should throw an ArgumentFailure if no color is provided', () {
    // arrange
    // act
    final call = colorHelper.colorToHex;
    // assert
    expect(call(), left(ArgumentFailure()));
  });
}
